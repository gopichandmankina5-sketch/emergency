import unittest
import json
from app.main import app
from app.database.connection import db

class TestAPIEndpoints(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()

    def test_01_register_vehicle(self):
        res = self.client.post("/api/vehicles/register", json={"vehicleId": "TEST_V101", "isEmergency": False})
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["status"], "SUCCESS")

    def test_02_update_location(self):
        res = self.client.post("/api/vehicles/location", json={"vehicleId": "TEST_V101", "latitude": 13.0827, "longitude": 80.2707, "speed": 35.0, "heading": 90.0, "locationEnabled": True})
        self.assertEqual(res.status_code, 200)

    def test_03_get_nearby_vehicles(self):
        res = self.client.get("/api/vehicles/nearby?radius=800")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertIn("vehicles", data)

    def test_04_start_emergency_invalid_input(self):
        # Missing destination should return 400 Bad Request
        res = self.client.post("/api/emergency/start", json={"vehicleId": "AMB999"})
        self.assertEqual(res.status_code, 400)

    def test_05_start_emergency_success(self):
        res = self.client.post("/api/emergency/start", json={
            "vehicleId": "AMB001",
            "type": "AMBULANCE",
            "latitude": 13.08000,
            "longitude": 80.26800,
            "speed": 45.0,
            "heading": 90.0,
            "destination": {"latitude": 13.08000, "longitude": 80.30000}
        })
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["status"], "ACTIVE")

    def test_06_get_corridor(self):
        res = self.client.get("/api/emergency/AMB001/corridor")
        self.assertEqual(res.status_code, 200)

    def test_07_get_alerts(self):
        res = self.client.get("/api/alerts/TEST_V101")
        self.assertEqual(res.status_code, 200)

    def test_08_send_alert_manual(self):
        res = self.client.post("/api/alerts/send", json={"vehicleId": "TEST_V101", "action": "MOVE_LEFT", "title": "ALERT", "body": "MOVE"})
        self.assertEqual(res.status_code, 200)

    def test_09_stop_emergency(self):
        res = self.client.post("/api/emergency/stop?vehicleId=AMB001")
        self.assertEqual(res.status_code, 200)

    def test_10_analytics_and_csv_export(self):
        res1 = self.client.get("/api/analytics")
        self.assertEqual(res1.status_code, 200)
        
        res2 = self.client.get("/api/analytics/export-csv")
        self.assertEqual(res2.status_code, 200)
        self.assertEqual(res2.mimetype, "text/csv")
        self.assertIn("Vehicle ID", res2.data.decode())

    def test_11_success_criteria(self):
        res = self.client.get("/api/success-criteria")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["totalCriteria"], 12)

if __name__ == "__main__":
    unittest.main()
