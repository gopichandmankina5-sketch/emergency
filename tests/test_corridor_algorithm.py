import unittest
import time
from app.algorithms.corridor_algorithm import corridor_engine
from app.models.schemas import ActionType, AlertType

class TestCorridorAlgorithm(unittest.TestCase):

    def setUp(self):
        self.ev_id = "AMB001"
        self.ev_lat = 13.08000
        self.ev_lon = 80.26800
        self.ev_speed = 45.0  # km/h (~12.5 m/s)
        self.ev_heading = 90.0  # East
        self.dest_lat = 13.08000
        self.dest_lon = 80.30000

    def test_scenario_a_few_blockers(self):
        """Scenario A: 10 nearby vehicles, only 2 obstruct predicted path."""
        vehicles = []
        # 2 Blocking vehicles on center lane (150m & 300m ahead)
        vehicles.append({"vehicleId": "V1", "latitude": 13.08001, "longitude": 80.26950, "speed": 30.0, "heading": 90.0, "locationEnabled": True})
        vehicles.append({"vehicleId": "V2", "latitude": 13.08001, "longitude": 80.27100, "speed": 25.0, "heading": 90.0, "locationEnabled": True})
        
        # 8 Non-blocking vehicles (far north, far south, opposite direction)
        for i in range(3, 11):
            offset_lat = 13.0850 + (i * 0.001)
            vehicles.append({"vehicleId": f"V{i}", "latitude": offset_lat, "longitude": 80.2700, "speed": 35.0, "heading": 90.0, "locationEnabled": True})

        res = corridor_engine.evaluate_minimum_intervention_corridor(
            self.ev_id, self.ev_lat, self.ev_lon, self.ev_speed, self.ev_heading,
            self.dest_lat, self.dest_lon, vehicles
        )

        self.assertEqual(res["totalNearbyVehicles"], 10)
        self.assertEqual(res["obstructingVehiclesCount"], 2)
        self.assertEqual(res["instructedToMoveCount"], 2)

    def test_scenario_b_no_obstructions(self):
        """Scenario B: 10 nearby vehicles, 0 on emergency path."""
        vehicles = []
        for i in range(1, 11):
            vehicles.append({"vehicleId": f"V{i}", "latitude": 13.08500 + (i * 0.0005), "longitude": 80.27000, "speed": 40.0, "heading": 90.0, "locationEnabled": True})

        res = corridor_engine.evaluate_minimum_intervention_corridor(
            self.ev_id, self.ev_lat, self.ev_lon, self.ev_speed, self.ev_heading,
            self.dest_lat, self.dest_lon, vehicles
        )

        self.assertEqual(res["totalNearbyVehicles"], 10)
        self.assertEqual(res["obstructingVehiclesCount"], 0)
        self.assertEqual(res["instructedToMoveCount"], 0)

    def test_scenario_c_dynamic_recalculation(self):
        """Scenario C: Change vehicle positions and verify recalculation updates actions."""
        # Step 1: Vehicle V102 is far away (NO ALERT)
        v_initial = [{"vehicleId": "V102", "latitude": 13.08500, "longitude": 80.26800, "speed": 30.0, "heading": 90.0, "locationEnabled": True}]
        res1 = corridor_engine.evaluate_minimum_intervention_corridor(
            self.ev_id, self.ev_lat, self.ev_lon, self.ev_speed, self.ev_heading,
            self.dest_lat, self.dest_lon, v_initial
        )
        self.assertEqual(res1["instructedToMoveCount"], 0)

        # Step 2: Vehicle V102 moves into centerline ahead (MOVE RIGHT / MOVE LEFT)
        v_moved = [{"vehicleId": "V102", "latitude": 13.08001, "longitude": 80.26950, "speed": 30.0, "heading": 90.0, "locationEnabled": True}]
        res2 = corridor_engine.evaluate_minimum_intervention_corridor(
            self.ev_id, self.ev_lat, self.ev_lon, self.ev_speed, self.ev_heading,
            self.dest_lat, self.dest_lon, v_moved
        )
        self.assertEqual(res2["instructedToMoveCount"], 1)

    def test_safety_rule_opposite_direction(self):
        """Safety Test: Opposite direction vehicle receives NO ALERT."""
        v_opposite = [{"vehicleId": "V_OPP", "latitude": 13.08000, "longitude": 80.27000, "speed": 45.0, "heading": 270.0, "locationEnabled": True}]
        res = corridor_engine.evaluate_minimum_intervention_corridor(
            self.ev_id, self.ev_lat, self.ev_lon, self.ev_speed, self.ev_heading,
            self.dest_lat, self.dest_lon, v_opposite
        )
        self.assertEqual(res["obstructingVehiclesCount"], 0)

    def test_safety_rule_location_off(self):
        """Safety Test: Location OFF generates notice, no unsafe lane instruction."""
        v_off = [{"vehicleId": "V_OFF", "latitude": 13.08000, "longitude": 80.26900, "speed": 30.0, "heading": 90.0, "locationEnabled": False}]
        res = corridor_engine.evaluate_minimum_intervention_corridor(
            self.ev_id, self.ev_lat, self.ev_lon, self.ev_speed, self.ev_heading,
            self.dest_lat, self.dest_lon, v_off
        )
        self.assertTrue(len(res["alerts"]) > 0)
        self.assertIn("Location OFF", res["alerts"][0].actionText)

    def test_stale_faraway_vehicles_excluded_from_total_nearby_count(self):
        """
        Verification Test:
        Vehicles hundreds of kilometers away (e.g., UNKNOWN-001 at ~481.5 km and UNKNOWN-002 at ~482 km)
        must NOT increase totalNearbyVehicles, while actual nearby vehicles (e.g. V102 at 7.8 m) ARE counted.
        """
        vehicles = [
            # V102: 7.8 m away
            {"vehicleId": "V102", "latitude": 13.08007, "longitude": 80.26800, "speed": 30.0, "heading": 90.0, "locationEnabled": True},
            # UNKNOWN-001: ~481.5 km away (lat 17.41234, lon 78.47567)
            {"vehicleId": "UNKNOWN-001", "latitude": 17.41234, "longitude": 78.47567, "speed": 0.0, "heading": 0.0, "locationEnabled": True},
            # UNKNOWN-002: ~482.0 km away (lat 17.42345, lon 78.48678)
            {"vehicleId": "UNKNOWN-002", "latitude": 17.42345, "longitude": 78.48678, "speed": 0.0, "heading": 0.0, "locationEnabled": True},
        ]

        res = corridor_engine.evaluate_minimum_intervention_corridor(
            self.ev_id, self.ev_lat, self.ev_lon, self.ev_speed, self.ev_heading,
            self.dest_lat, self.dest_lon, vehicles
        )

        # totalNearbyVehicles must be exactly 1 (V102 only)
        self.assertEqual(res["totalNearbyVehicles"], 1)

        # Analytics rows must still evaluate all 3 candidates for infrastructure/analytics tracking
        self.assertEqual(len(res["analyticsRows"]), 3)

if __name__ == "__main__":
    unittest.main()
