import os

try:
    from dotenv import load_dotenv
    # Load .env from current directory, backend directory, or project root
    load_dotenv()
    load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))
    load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))
except ImportError:
    pass

class Settings:
    PROJECT_NAME: str = "Dynamic Emergency Corridor Allocation System"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api"
    
    # Database Configuration
    MONGODB_URI: str = os.getenv("MONGODB_URI", "")
    DB_NAME: str = os.getenv("MONGODB_DATABASE", os.getenv("DB_NAME", "corridor_db"))
    
    # FCM / Push Notification Configuration (Firebase Admin SDK / FCM HTTP v1)
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", os.getenv("GOOGLE_APPLICATION_CREDENTIALS", os.path.join(os.path.dirname(__file__), "..", "firebase-service-account.json")))
    FIREBASE_CREDENTIALS_JSON: str = os.getenv("FIREBASE_CREDENTIALS_JSON", "")
    # FCM Simulation Control: True = Log alerts locally; False = Dispatch real push notifications via Firebase Admin SDK
    FCM_SIMULATION: bool = os.getenv("FCM_SIMULATION", "false").lower() == "true"
    
    # Telemetry & GPS Stale Timeout
    GPS_STALE_TIMEOUT_SECONDS: float = float(os.getenv("GPS_STALE_TIMEOUT_SECONDS", "60.0"))
    
    # Corridor Algorithm Tuning Parameters
    CORRIDOR_WIDTH_METERS: float = 7.0  # Total lane width to clear
    SAFETY_BUFFER_METERS: float = 20.0  # Buffer ahead/behind emergency vehicle
    PREDICTION_HORIZON_SECONDS: float = 30.0  # Lookahead horizon
    MAX_OBSTRUCTION_DISTANCE_METERS: float = 500.0  # Spatial radius

settings = Settings()
