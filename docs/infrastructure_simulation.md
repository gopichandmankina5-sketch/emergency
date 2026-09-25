# Unknown Vehicle / Infrastructure Simulation

## Software-Based Infrastructure Alert Simulation Layer

> [!IMPORTANT]
> **Technical Disclaimer**:
> - This module provides a **SOFTWARE-ONLY simulation** of an infrastructure/roadside alert layer.
> - The prototype supports road users that are NOT registered with the Driver App.
> - Since an unregistered vehicle has no FCM token, the system **does NOT claim to directly notify that vehicle via push notifications**.
> - Instead, the backend generates a **Software-Based Infrastructure Alert Simulation** representing a future roadside V2X / smart infrastructure delivery interface.
> - **NO actual V2X hardware or physical roadside units are claimed or used.**

---

### 1. Architectural Concept

In a real-world Dynamic Emergency Corridor System, not all road users will have the Driver App installed or active on their devices. Unregistered vehicles, commercial trucks, or transient traffic are classified as **Unknown Road Users**.

To maintain emergency corridor safety without breaking registration requirements:
1. **Registered Vehicles** (e.g. `V102`, `V103`): Receive direct mobile push notifications via **Firebase Cloud Messaging (FCM)** + Driver App sound and vibration.
2. **Unknown Road Users** (e.g. `UNKNOWN-001`, `UNKNOWN-002`): Evaluated dynamically by the corridor engine for path obstruction. When an unknown vehicle is identified as an obstruction along the emergency corridor, the system generates a **Software Infrastructure Alert** (`deliveryChannel: "SOFTWARE_INFRASTRUCTURE_SIMULATION"`, `deliveryStatus: "SIMULATED"`).
3. **FCM Isolation**: Unknown vehicles **NEVER** receive FCM push notifications or require Driver App registration.

---

### 2. Infrastructure Alert Data Model

```json
{
  "alertId": "infra-UNKNOWN-001-AMB001",
  "vehicleId": "UNKNOWN-001",
  "emergencyVehicleId": "AMB001",
  "action": "MOVE LEFT WHEN SAFE",
  "distanceMeters": 42.5,
  "riskLevel": "HIGH",
  "registrationStatus": "UNKNOWN",
  "deliveryChannel": "SOFTWARE_INFRASTRUCTURE_SIMULATION",
  "deliveryStatus": "SIMULATED",
  "active": true,
  "createdAt": "2026-09-24T12:00:00.000Z"
}
```

---

### 3. REST API Specification

- `POST /api/road-users/observe`: Observes or updates telemetry for an unknown road user. (`registrationStatus` remains `"UNKNOWN"`).
- `POST /api/road-users/simulate`: Simulates position updates for an unknown vehicle and triggers corridor recalculation.
- `GET /api/road-users`: Lists all active unknown road users.
- `DELETE /api/road-users/{vehicleId}`: Removes an unknown road user from simulation and deactivates associated infrastructure alerts.
- `GET /api/infrastructure/alerts?emergencyVehicleId=AMB001`: Returns active software infrastructure alerts for the specified emergency vehicle.

---

### 4. Lifecycle & Deactivation Rules

- **No Emergency**: No active infrastructure alerts are generated.
- **Emergency Start**: Corridor algorithm evaluates unknown road users along path and generates active infrastructure alerts for obstructions.
- **Emergency Stop**: All active infrastructure alerts for the emergency mission are automatically deactivated (`active: false`).
- **Vehicle Exits Corridor**: If an unknown vehicle moves outside the corridor obstruction path, its active infrastructure alert is deactivated.
