import unittest
import json
from app.main import app
from app.database.connection import db

class TestAlertLifecycle(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()
        db.clear_all()

    def test_A_no_active_emergency_returns_no_active_alert(self):
        """A. No active emergency -> GET /api/alerts/V102 returns no active alert."""
        res = self.client.get("/api/alerts/V102")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["hasAlert"], False)
        self.assertEqual(data["vehicleId"], "V102")
        self.assertEqual(data["alerts"], [])
        self.assertNotIn("latestAlert", data)

    def test_B_start_emergency_makes_targeted_alert_active(self):
        """B. Start emergency -> targeted alert becomes active."""
        # 1. Register driver vehicle V102 directly on corridor path ahead of AMB001
        self.client.post("/api/vehicles/register", json={"vehicleId": "V102", "isEmergency": False})
        self.client.post("/api/vehicles/location", json={
            "vehicleId": "V102",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0,
            "locationEnabled": True
        })

        # 2. Start emergency mission for AMB001
        start_res = self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })
        self.assertEqual(start_res.status_code, 200)

        # 3. Check alerts for V102
        res = self.client.get("/api/alerts/V102")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["hasAlert"], True)
        self.assertIn("latestAlert", data)
        self.assertEqual(data["latestAlert"]["vehicleId"], "V102")
        self.assertEqual(data["latestAlert"]["active"], True)
        self.assertEqual(data["latestAlert"]["emergencyVehicleId"], "AMB001")

    def test_C_and_D_stop_emergency_deactivates_alerts_and_returns_no_active_alert(self):
        """C & D. Stop emergency -> targeted alert becomes inactive, GET /api/alerts/V102 returns no active alert."""
        # 1. Register driver vehicle V102
        self.client.post("/api/vehicles/register", json={"vehicleId": "V102", "isEmergency": False})
        self.client.post("/api/vehicles/location", json={
            "vehicleId": "V102",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0,
            "locationEnabled": True
        })

        # 2. Start emergency mission
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })

        # Verify active alert exists before stopping
        pre_res = self.client.get("/api/alerts/V102")
        self.assertTrue(json.loads(pre_res.data)["hasAlert"])

        # 3. Stop emergency mission
        stop_res = self.client.post("/api/emergency/stop?vehicleId=AMB001")
        self.assertEqual(stop_res.status_code, 200)

        # 4. Check GET /api/alerts/V102 after stop
        post_res = self.client.get("/api/alerts/V102")
        self.assertEqual(post_res.status_code, 200)
        data = json.loads(post_res.data)
        self.assertEqual(data["hasAlert"], False)
        self.assertEqual(data["alerts"], [])

    def test_E_start_second_emergency_generates_new_fresh_alert(self):
        """E. Start a second emergency -> a new alert can be generated."""
        # Setup vehicle
        self.client.post("/api/vehicles/register", json={"vehicleId": "V102", "isEmergency": False})
        self.client.post("/api/vehicles/location", json={
            "vehicleId": "V102",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0,
            "locationEnabled": True
        })

        # First emergency start & stop
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })
        self.client.post("/api/emergency/stop?vehicleId=AMB001")

        # Second emergency start with different emergency vehicle AMB002
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB002",
            "type": "FIRE_TRUCK",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })

        # Check alerts for V102 during second emergency
        res = self.client.get("/api/alerts/V102")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["hasAlert"], True)
        self.assertEqual(data["latestAlert"]["emergencyVehicleId"], "AMB002")
        self.assertEqual(data["latestAlert"]["active"], True)

    def test_F_acknowledgement_still_works(self):
        """F. Acknowledgement still works."""
        self.client.post("/api/vehicles/register", json={"vehicleId": "V102", "isEmergency": False})
        self.client.post("/api/vehicles/location", json={
            "vehicleId": "V102",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0,
            "locationEnabled": True
        })
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })

        # Acknowledge alert
        ack_res = self.client.post("/api/alerts/V102/acknowledge")
        self.assertEqual(ack_res.status_code, 200)
        ack_data = json.loads(ack_res.data)
        self.assertEqual(ack_data["acknowledged"], True)

        # GET /api/alerts/V102 should no longer report active alert
        res = self.client.get("/api/alerts/V102")
        data = json.loads(res.data)
        self.assertEqual(data["hasAlert"], False)

    def test_G_existing_analytics_and_history_preserved(self):
        """G. Existing analytics/history are preserved."""
        self.client.post("/api/vehicles/register", json={"vehicleId": "V102", "isEmergency": False})
        self.client.post("/api/vehicles/location", json={
            "vehicleId": "V102",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0,
            "locationEnabled": True
        })
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })
        self.client.post("/api/emergency/stop?vehicleId=AMB001")

        # Historical alert record still exists in database and analytics
        all_historical = db.get_alerts_by_vehicle("V102")
        self.assertGreaterEqual(len(all_historical), 1)

        # Verify analytics endpoint
        analytics_res = self.client.get("/api/analytics")
        self.assertEqual(analytics_res.status_code, 200)
        analytics_data = json.loads(analytics_res.data)
        self.assertIn("totalVehiclesRegistered", analytics_data)

if __name__ == "__main__":
    unittest.main()
