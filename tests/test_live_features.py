import unittest
import json
import time
from datetime import datetime, timezone, timedelta
from app.main import app
from app.services.corridor_service import corridor_service
from app.database.connection import db, db_store
from app.notifications.fcm_handler import fcm_handler

class TestLiveFeatures(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()

    def test_fcm_token_registration(self):
        """Verify POST /api/vehicles/fcm-token registers FCM device token."""
        res = self.client.post("/api/vehicles/fcm-token", json={
            "vehicleId": "V102",
            "fcmToken": "DEVICE_TOKEN_TEST_V102"
        })
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["status"], "REGISTERED")
        
        v = db.get_vehicle("V102")
        self.assertEqual(v.get("fcmToken"), "DEVICE_TOKEN_TEST_V102")

    def test_alert_deduplication(self):
        """Verify duplicate notifications are suppressed if action remains unchanged."""
        corridor_service.last_dispatched_actions.clear()
        
        # Action 1: First dispatch for V102 (MOVE_RIGHT)
        v102_data = {"vehicleId": "V102", "latitude": 13.08001, "longitude": 80.26950, "speed": 30.0, "heading": 90.0, "locationEnabled": True}
        corridor_service.update_vehicle_location(v102_data)
        
        # Start emergency
        corridor_service.start_emergency({
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 45.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })
        
        initial_action = corridor_service.last_dispatched_actions.get("V102")
        self.assertIsNotNone(initial_action)
        
        # Repeat calculation with identical position
        corridor_service.recalculate_and_dispatch("AMB001")
        same_action = corridor_service.last_dispatched_actions.get("V102")
        self.assertEqual(initial_action, same_action)

    def test_stale_location_filtering(self):
        """Verify vehicle positions older than 15 seconds are filtered out as stale."""
        now = datetime.now(timezone.utc)
        fresh_time = now.isoformat()
        stale_time = (now - timedelta(seconds=30)).isoformat()
        
        db.upsert_vehicle({"vehicleId": "FRESH_V1", "latitude": 13.08001, "longitude": 80.26950, "lastUpdated": fresh_time})
        db.upsert_vehicle({"vehicleId": "STALE_V2", "latitude": 13.08001, "longitude": 80.26950, "lastUpdated": stale_time})
        
        fresh_list = db_store.get_fresh_vehicles(max_stale_seconds=15.0)
        fresh_ids = [v["vehicleId"] for v in fresh_list]
        
        self.assertIn("FRESH_V1", fresh_ids)
        self.assertNotIn("STALE_V2", fresh_ids)

    def test_db_fallback_and_fcm_status_endpoints(self):
        """Verify status endpoints properly indicate dev fallback & simulation mode labels."""
        db_status = db.get_db_status()
        self.assertIn("mode", db_status)
        
        fcm_status = fcm_handler.get_status()
        self.assertIn("mode", fcm_status)

    def test_driver_test_001_nearby_registration(self):
        """Verify registering DRIVER_TEST_001 allows it to be retrieved via GET /api/vehicles/nearby with spatial query."""
        reg_res = self.client.post("/api/vehicles/register", json={
            "vehicleId": "DRIVER_TEST_001",
            "vehicleType": "car",
            "latitude": 10.3800,
            "longitude": 78.8200,
            "speed": 30,
            "heading": 90
        })
        self.assertEqual(reg_res.status_code, 200)

        nearby_res = self.client.get("/api/vehicles/nearby?latitude=10.3800&longitude=78.8200&radius=5000")
        self.assertEqual(nearby_res.status_code, 200)
        data = json.loads(nearby_res.data)
        
        self.assertGreater(data["count"], 0)
        v_ids = [v["vehicleId"] for v in data["vehicles"]]
        self.assertIn("DRIVER_TEST_001", v_ids)

if __name__ == "__main__":
    unittest.main()
