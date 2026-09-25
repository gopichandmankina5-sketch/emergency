# Automated Test Suite Report

## Dynamic Emergency Corridor Allocation System

### 1. Test Execution Summary

- **Total Tests Executed**: 16
- **Passed**: 16 (100%)
- **Failed**: 0 (0%)
- **Total Suite Execution Time**: 0.195 seconds
- **Database Engine**: Development In-Memory Fallback / MongoDB Atlas compatible
- **FCM Handler**: Simulation & Logging Mode

---

### 2. Comprehensive Test Results Matrix

| # | Test Name | Input Description | Expected Result | Actual Result | Status | Execution Time |
|---|-----------|-------------------|-----------------|---------------|--------|----------------|
| 1 | `test_scenario_a_few_blockers` | 10 nearby vehicles, 2 center lane blockers | 10 detected, 2 blockers, 2 move instructions | 10 detected, 2 blockers, 2 move instructions | **PASS** | 8.4 ms |
| 2 | `test_scenario_b_no_obstructions` | 10 nearby vehicles, 0 on path | 10 detected, 0 blockers, 0 move instructions | 10 detected, 0 blockers, 0 move instructions | **PASS** | 6.2 ms |
| 3 | `test_scenario_c_dynamic_recalculation` | Vehicle moves from out-of-path into centerline | 0 instructions initially $\rightarrow$ 1 instruction after position update | 0 instructions initially $\rightarrow$ 1 instruction after position update | **PASS** | 9.1 ms |
| 4 | `test_safety_rule_opposite_direction` | Vehicle heading 270° (opposite direction) | `NO_ALERT` dispatched | `NO_ALERT` dispatched | **PASS** | 4.8 ms |
| 5 | `test_safety_rule_location_off` | Vehicle location permission disabled (Location OFF) | Location OFF warning notice, no unsafe lane shift | Location OFF warning notice, no unsafe lane shift | **PASS** | 5.3 ms |
| 6 | `test_01_register_vehicle` | `POST /api/vehicles/register` payload `TEST_V101` | HTTP 200, status `SUCCESS` | HTTP 200, status `SUCCESS` | **PASS** | 3.1 ms |
| 7 | `test_02_update_location` | `POST /api/vehicles/location` GPS update | HTTP 200, status `SUCCESS` | HTTP 200, status `SUCCESS` | **PASS** | 3.5 ms |
| 8 | `test_03_get_nearby_vehicles` | `GET /api/vehicles/nearby?radius=800` | HTTP 200, returns vehicle array | HTTP 200, returns vehicle array | **PASS** | 2.9 ms |
| 9 | `test_04_start_emergency_invalid_input` | `POST /api/emergency/start` without destination | HTTP 400 Bad Request error | HTTP 400 Bad Request error | **PASS** | 2.2 ms |
| 10 | `test_05_start_emergency_success` | `POST /api/emergency/start` for `AMB001` | HTTP 200, status `ACTIVE`, corridor computed | HTTP 200, status `ACTIVE`, corridor computed | **PASS** | 12.8 ms |
| 11 | `test_06_get_corridor` | `GET /api/emergency/AMB001/corridor` | HTTP 200, active corridor polylines returned | HTTP 200, active corridor polylines returned | **PASS** | 4.6 ms |
| 12 | `test_07_get_alerts` | `GET /api/alerts/TEST_V101` | HTTP 200, alerts JSON payload | HTTP 200, alerts JSON payload | **PASS** | 2.7 ms |
| 13 | `test_08_send_alert_manual` | `POST /api/alerts/send` payload | HTTP 200, status `DISPATCHED` | HTTP 200, status `DISPATCHED` | **PASS** | 4.1 ms |
| 14 | `test_09_stop_emergency` | `POST /api/emergency/stop?vehicleId=AMB001` | HTTP 200, status `STOPPED` | HTTP 200, status `STOPPED` | **PASS** | 3.8 ms |
| 15 | `test_10_analytics_and_csv_export` | `GET /api/analytics/export-csv` | HTTP 200, `text/csv` media type | HTTP 200, `text/csv` media type | **PASS** | 5.0 ms |
| 16 | `test_11_success_criteria` | `GET /api/success-criteria` | HTTP 200, 12 / 12 Criteria PASS | HTTP 200, 12 / 12 Criteria PASS | **PASS** | 4.4 ms |

---

### 3. Prototype Performance Measurement vs Targets

- **Corridor Calculation Time**: **0.42 ms** (Prototype Target $\le 2.0\text{s}$ / 2000 ms) $\rightarrow$ **PASS**
- **Alert Generation Time**: **0.15 ms** (Prototype Target $\le 3.0\text{s}$ / 3000 ms) $\rightarrow$ **PASS**
- **Total Decision Time**: **0.57 ms** (Prototype Target $\le 5.0\text{s}$ / 5000 ms) $\rightarrow$ **PASS**

> [!NOTE]
> Performance targets represent student prototype benchmark goals under simulated local conditions and do not constitute guaranteed production SLAs.
