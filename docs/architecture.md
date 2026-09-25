# System Architecture Documentation

## Dynamic Emergency Corridor Allocation System (Student Prototype)

> [!IMPORTANT]
> **Scientific & Technical Disclaimers**:
> - **PROTOTYPE / SIMULATION**: This platform is an educational student prototype demonstrating predictive corridor allocation algorithm concepts.
> - **DATABASE PERSISTENCE**: Connects to MongoDB Atlas when `MONGODB_URI` environment variable is configured. When offline, operates in **DEVELOPMENT ONLY — IN-MEMORY FALLBACK (NON-PERSISTENT)** mode.
> - **PUSH NOTIFICATIONS**: When real FCM credentials are not configured, push alerts run in **FCM SIMULATION MODE — LOGGING ONLY**.
> - **CELL BROADCAST**: Architecture includes conceptual design notes for future telecom integration; no actual hardware cell broadcast is claimed.

---

### 1. System Data Flow Architecture

```
  ┌──────────────────────────┐
  │   Flutter Mobile App     │
  │ (Emergency & Driver UI)  │
  └─────────────┬────────────┘
                │ HTTPS REST API
                ▼
  ┌──────────────────────────┐
  │     FastAPI / Flask      │
  │     Backend Server       │
  └──────┬─────────────┬─────┘
         │             │
         ▼             ▼
┌─────────────────┐  ┌───────────────────────┐
│ MongoDB Atlas / │  │ Firebase Cloud        │
│ Dev Fallback Store│ │ Messaging (FCM Sim)  │
└─────────────────┘  └───────────────────────┘
```

---

### 2. Location Permission Logic Architecture

- **Location ON Mode**: Uses real-time GPS telemetry (latitude, longitude, speed, heading) to calculate perpendicular centerline offset $d_\perp$ and longitudinal offset $d_\parallel$. Enables precise lane shift instructions (`MOVE LEFT WHEN SAFE`, `MOVE RIGHT WHEN SAFE`).
- **Location OFF Mode**: Does NOT pretend stale GPS is current location. Displays a general proximity warning notice: *"Precise emergency corridor instructions require location access."* System design accounts for future cellular broadcast integration.

---

### 3. REST API Endpoint Mapping

- `POST /api/vehicles/register`: Registers vehicle ID and FCM token.
- `POST /api/vehicles/location`: Streams GPS, speed, heading, location permission status.
- `POST /api/emergency/start`: Initiates emergency mission for AMB001 / Fire / Police.
- `POST /api/emergency/location`: Streams high-frequency emergency vehicle location.
- `POST /api/emergency/stop`: Terminates active emergency mission.
- `GET /api/vehicles/nearby`: Queries nearby vehicles within search radius.
- `GET /api/emergency/{id}/corridor`: Fetches active emergency route, corridor polygon, and vehicle actions.
- `GET /api/alerts/{vehicleId}`: Fetches personalized instruction for vehicle ID.
- `POST /api/alerts/send`: Dispatches targeted alerts.
- `POST /api/road-users/observe`: Observes/updates unknown road user telemetry (registrationStatus: UNKNOWN).
- `POST /api/road-users/simulate`: Simulates position updates for unknown road users.
- `GET /api/road-users`: Lists all observed unknown road users.
- `DELETE /api/road-users/{vehicleId}`: Removes unknown road user and deactivates its infrastructure alerts.
- `GET /api/infrastructure/alerts`: Fetches software-based infrastructure simulation alerts for active emergency.
- `GET /api/analytics`: Summarizes performance metrics.
- `GET /api/analytics/export-csv`: Generates 13-column CSV export file for Excel project.
- `GET /api/success-criteria`: Returns PASS/FAIL evaluation for the 12 Prototype Success Criteria.
