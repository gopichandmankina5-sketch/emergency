import unittest
import json
from app.main import app
from app.database.connection import db
from app.notifications.fcm_handler import fcm_handler

class TestInfrastructureSimulation(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()
        db.clear_all()

    def test_1_create_unknown_road_user(self):
        """1. Create unknown road user."""
        res = self.client.post("/api/road-users/observe", json={
            "vehicleId": "UNKNOWN-001",
            "latitude": 13.08001,
            "longitude": 80.26960,
            "speed": 35.0,
            "heading": 90.0,
            "vehicleType": "CAR"
        })
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["vehicleId"], "UNKNOWN-001")
        self.assertEqual(data["registrationStatus"], "UNKNOWN")

    def test_2_update_unknown_road_user(self):
        """2. Update unknown road user."""
        self.client.post("/api/road-users/observe", json={
            "vehicleId": "UNKNOWN-001",
            "latitude": 13.08001,
            "longitude": 80.26960,
            "speed": 35.0,
            "heading": 90.0,
            "vehicleType": "CAR"
        })

        res = self.client.post("/api/road-users/simulate", json={
            "vehicleId": "UNKNOWN-001",
            "latitude": 13.08005,
            "longitude": 80.27000,
            "speed": 40.0,
            "heading": 90.0
        })
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["vehicleId"], "UNKNOWN-001")
        self.assertEqual(data["latitude"], 13.08005)
        self.assertEqual(data["speed"], 40.0)

    def test_3_list_unknown_road_users(self):
        """3. List unknown road users."""
        self.client.post("/api/road-users/observe", json={"vehicleId": "UNKNOWN-001", "latitude": 13.08001, "longitude": 80.26960})
        self.client.post("/api/road-users/observe", json={"vehicleId": "UNKNOWN-002", "latitude": 13.08002, "longitude": 80.26970})

        res = self.client.get("/api/road-users")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(len(data), 2)
        v_ids = [u["vehicleId"] for u in data]
        self.assertIn("UNKNOWN-001", v_ids)
        self.assertIn("UNKNOWN-002", v_ids)

    def test_4_delete_unknown_road_user(self):
        """4. Delete unknown road user."""
        self.client.post("/api/road-users/observe", json={"vehicleId": "UNKNOWN-001", "latitude": 13.08001, "longitude": 80.26960})
        del_res = self.client.delete("/api/road-users/UNKNOWN-001")
        self.assertEqual(del_res.status_code, 200)
        data = json.loads(del_res.data)
        self.assertEqual(data["status"], "DELETED")

        list_res = self.client.get("/api/road-users")
        self.assertEqual(len(json.loads(list_res.data)), 0)

    def test_5_unknown_vehicle_inside_corridor_creates_infrastructure_alert(self):
        """5. Unknown vehicle inside corridor creates infrastructure alert."""
        # Add unknown vehicle inside path
        self.client.post("/api/road-users/observe", json={
            "vehicleId": "UNKNOWN-001",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0
        })

        # Start emergency
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })

        res = self.client.get("/api/infrastructure/alerts?emergencyVehicleId=AMB001")
        self.assertEqual(res.status_code, 200)
        alerts = json.loads(res.data)
        self.assertGreaterEqual(len(alerts), 1)
        alert = alerts[0]
        self.assertEqual(alert["vehicleId"], "UNKNOWN-001")
        self.assertEqual(alert["emergencyVehicleId"], "AMB001")
        self.assertEqual(alert["deliveryChannel"], "SOFTWARE_INFRASTRUCTURE_SIMULATION")
        self.assertEqual(alert["deliveryStatus"], "SIMULATED")
        self.assertEqual(alert["registrationStatus"], "UNKNOWN")
        self.assertEqual(alert["active"], True)

    def test_6_unknown_vehicle_outside_corridor_does_not_create_active_alert(self):
        """6. Unknown vehicle outside corridor does not create active alert."""
        # Add unknown vehicle far north outside corridor path
        self.client.post("/api/road-users/observe", json={
            "vehicleId": "UNKNOWN-OUTSIDE",
            "latitude": 13.09500,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0
        })

        # Start emergency
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })

        res = self.client.get("/api/infrastructure/alerts?emergencyVehicleId=AMB001")
        alerts = json.loads(res.data)
        active_ids = [a["vehicleId"] for a in alerts if a.get("active")]
        self.assertNotIn("UNKNOWN-OUTSIDE", active_ids)

    def test_7_unknown_vehicle_never_receives_fcm(self):
        """7. Unknown vehicle never receives FCM."""
        # Observe unknown vehicle inside path
        self.client.post("/api/road-users/observe", json={
            "vehicleId": "UNKNOWN-001",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0
        })

        # Start emergency
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })

        # Verify no FCM token or vehicle entry created in normal vehicles DB
        v_info = db.get_vehicle("UNKNOWN-001")
        self.assertIsNone(v_info)

    def test_8_emergency_stop_deactivates_infrastructure_alerts(self):
        """8. Emergency stop deactivates infrastructure alerts."""
        self.client.post("/api/road-users/observe", json={
            "vehicleId": "UNKNOWN-001",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0
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

        # Pre-stop check
        pre_res = self.client.get("/api/infrastructure/alerts?emergencyVehicleId=AMB001")
        self.assertEqual(len(json.loads(pre_res.data)), 1)

        # Stop emergency
        self.client.post("/api/emergency/stop?vehicleId=AMB001")

        # Post-stop check
        post_res = self.client.get("/api/infrastructure/alerts?emergencyVehicleId=AMB001")
        self.assertEqual(len(json.loads(post_res.data)), 0)

    def test_9_new_emergency_creates_fresh_infrastructure_alerts(self):
        """9. New emergency creates fresh infrastructure alerts."""
        self.client.post("/api/road-users/observe", json={
            "vehicleId": "UNKNOWN-001",
            "latitude": 13.08001,
            "longitude": 80.26950,
            "speed": 30.0,
            "heading": 90.0
        })

        # Emergency 1 start & stop
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

        # Emergency 2 start
        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB002",
            "type": "FIRE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })

        res = self.client.get("/api/infrastructure/alerts?emergencyVehicleId=AMB002")
        alerts = json.loads(res.data)
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0]["emergencyVehicleId"], "AMB002")

    def test_10_no_alert_creates_no_infrastructure_alert(self):
        """10. NO_ALERT creates no infrastructure alert."""
        # Vehicle heading opposite direction (heading 270 vs ev heading 90) -> NO_ALERT
        self.client.post("/api/road-users/observe", json={
            "vehicleId": "UNKNOWN-OPPOSITE",
            "latitude": 13.08000,
            "longitude": 80.27100,
            "speed": 45.0,
            "heading": 270.0
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

        res = self.client.get("/api/infrastructure/alerts?emergencyVehicleId=AMB001")
        alerts = json.loads(res.data)
        v_ids = [a["vehicleId"] for a in alerts]
        self.assertNotIn("UNKNOWN-OPPOSITE", v_ids)

    def test_11_multiple_unknown_vehicles_work(self):
        """11. Multiple unknown vehicles work."""
        self.client.post("/api/road-users/observe", json={"vehicleId": "UNKNOWN-001", "latitude": 13.08001, "longitude": 80.26950, "speed": 30.0, "heading": 90.0})
        self.client.post("/api/road-users/observe", json={"vehicleId": "UNKNOWN-002", "latitude": 13.08002, "longitude": 80.27020, "speed": 25.0, "heading": 90.0})

        self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 50.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })

        res = self.client.get("/api/infrastructure/alerts?emergencyVehicleId=AMB001")
        alerts = json.loads(res.data)
        v_ids = [a["vehicleId"] for a in alerts if a.get("active")]
        self.assertIn("UNKNOWN-001", v_ids)
        self.assertIn("UNKNOWN-002", v_ids)

    def test_12_existing_v102_behavior_remains_unchanged(self):
        """12. Existing V102 behavior remains unchanged."""
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

        res = self.client.get("/api/alerts/V102")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["hasAlert"], True)
        self.assertEqual(data["latestAlert"]["vehicleId"], "V102")

if __name__ == "__main__":
    unittest.main()
