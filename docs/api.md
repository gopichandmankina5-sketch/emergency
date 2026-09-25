# REST API Documentation

### Base URL
`http://localhost:8000/api`

---

### Endpoints

#### 1. Vehicle Registration
- **POST** `/vehicles/register`
- **Request Body**:
```json
{
  "vehicleId": "V102",
  "isEmergency": false,
  "fcmToken": "optional_token"
}
```

#### 2. Vehicle Telemetry Update
- **POST** `/vehicles/location`
- **Request Body**:
```json
{
  "vehicleId": "V102",
  "latitude": 13.0827,
  "longitude": 80.2707,
  "speed": 32.0,
  "heading": 90.0,
  "locationEnabled": true
}
```

#### 3. Start Emergency Mission
- **POST** `/emergency/start`
- **Request Body**:
```json
{
  "vehicleId": "AMB001",
  "type": "AMBULANCE",
  "latitude": 13.0800,
  "longitude": 80.2680,
  "speed": 45.0,
  "heading": 90.0,
  "destination": {
    "latitude": 13.1000,
    "longitude": 80.3000
  }
}
```

#### 4. Emergency Telemetry Stream
- **POST** `/emergency/location`

#### 5. Stop Emergency Mission
- **POST** `/emergency/stop?vehicleId=AMB001`

#### 6. Nearby Vehicles Query
- **GET** `/vehicles/nearby?radius=800`

#### 7. Active Corridor Polylines & Actions
- **GET** `/emergency/{id}/corridor`

#### 8. Driver Personalized Alert Fetch
- **GET** `/alerts/{vehicleId}`

#### 9. Excel CSV Analytics Export
- **GET** `/analytics/export-csv`
