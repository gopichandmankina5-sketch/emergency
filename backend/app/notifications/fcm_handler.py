import logging
import os
import json
from typing import Dict, Any, Optional
from app.config import settings

logger = logging.getLogger("fcm_handler")

class FCMNotificationHandler:
    """
    Firebase Cloud Messaging (FCM) Handler using Firebase Admin SDK (HTTP v1 API).
    Dispatches targeted push alerts to specific driver device tokens.
    Supports both FCM_SIMULATION=True (Logging mode) and FCM_SIMULATION=False (Live push dispatch).
    """
    def __init__(self):
        self._firebase_app = None
        self._initialized = False

    def _ensure_initialized(self) -> bool:
        if self._initialized:
            return True

        if settings.FCM_SIMULATION:
            logger.info("[FCM] Running in FCM_SIMULATION mode. Firebase Admin initialization skipped.")
            return False

        try:
            import firebase_admin
            from firebase_admin import credentials

            if firebase_admin._apps:
                self._firebase_app = firebase_admin.get_app()
                self._initialized = True
                return True

            cred = None
            if settings.FIREBASE_CREDENTIALS_PATH and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                logger.info(f"[FCM] Initializing Firebase Admin with credentials file: {settings.FIREBASE_CREDENTIALS_PATH}")
            elif settings.FIREBASE_CREDENTIALS_JSON:
                try:
                    cred_dict = json.loads(settings.FIREBASE_CREDENTIALS_JSON)
                    cred = credentials.Certificate(cred_dict)
                    logger.info("[FCM] Initializing Firebase Admin with FIREBASE_CREDENTIALS_JSON env.")
                except Exception as json_err:
                    logger.error(f"[FCM] Failed to parse FIREBASE_CREDENTIALS_JSON: {json_err}")
            elif os.getenv("GOOGLE_APPLICATION_CREDENTIALS") and os.path.exists(os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")):
                cred = credentials.Certificate(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))
                logger.info(f"[FCM] Initializing Firebase Admin with GOOGLE_APPLICATION_CREDENTIALS file.")
            else:
                try:
                    cred = credentials.ApplicationDefault()
                    logger.info("[FCM] Initializing Firebase Admin with ApplicationDefault credentials.")
                except Exception as app_def_err:
                    logger.warning(f"[FCM] ApplicationDefault credentials not available: {app_def_err}")

            if cred:
                self._firebase_app = firebase_admin.initialize_app(cred)
                self._initialized = True
                logger.info("[FCM] Firebase Admin SDK initialized successfully.")
                return True
            else:
                logger.warning("[FCM] No valid Firebase credentials found. Falling back to FCM simulation mode.")
                return False

        except ImportError:
            logger.warning("[FCM] 'firebase-admin' package is not installed. Running in simulation mode.")
            return False
        except Exception as e:
            logger.error(f"[FCM] Failed to initialize Firebase Admin SDK: {e}. Falling back to simulation mode.")
            return False

    @property
    def is_simulation(self) -> bool:
        if settings.FCM_SIMULATION:
            return True
        return not self._ensure_initialized()

    def get_fcm_status(self) -> Dict[str, Any]:
        return self.get_status()

    def get_status(self) -> Dict[str, Any]:
        sim = self.is_simulation
        return {
            "fcmSimulation": sim,
            "mode": "FCM SIMULATION MODE — LOGGING ONLY" if sim else "FCM LIVE PUSH DISPATCH (Firebase Admin SDK v1)",
            "firebaseAdminInitialized": self._initialized
        }

    def send_push_notification(self, fcm_token: str, title: str, body: str, data_payload: Dict[str, Any]) -> bool:
        """Dispatches an FCM HTTP v1 push notification specifically to fcm_token."""
        v_id = str(data_payload.get("vehicleId", "UNKNOWN"))
        if self.is_simulation or not fcm_token or fcm_token.startswith("mock_"):
            logger.info(f"[FCM SIMULATION MODE — LOGGING ONLY] Target Device Token: {fcm_token[:12] if fcm_token else 'NONE'}... | Title: {title} | Body: {body}")
            return True

        try:
            from firebase_admin import messaging

            logger.info("[FCM] REAL SEND START")
            logger.info(f"[FCM] Target vehicle: {v_id}")
            logger.info("[FCM] Target token found")

            # Ensure all values in data payload are strings (FCM requirement)
            str_data = {str(k): str(v) for k, v in data_payload.items()}
            str_data.setdefault("type", "EMERGENCY_CORRIDOR")
            str_data.setdefault("vehicleId", v_id)
            str_data.setdefault("emergencyVehicleId", str(data_payload.get("emergencyVehicleId", "AMB001")))
            str_data.setdefault("action", str(data_payload.get("action", "")))
            str_data.setdefault("actionText", str(data_payload.get("actionText", "")))
            str_data.setdefault("distance", str(data_payload.get("distance", "0")))
            str_data.setdefault("eta", str(data_payload.get("eta", "0")))
            str_data.setdefault("timestamp", str(data_payload.get("timestamp", "")))

            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        channel_id="emergency_corridor_loud_v2",
                        sound="emergency_alert",
                        priority="max",
                        visibility="public",
                        default_vibrate_timings=False,
                        vibrate_timings_millis=[0, 500, 200, 500, 200, 500],
                    ),
                ),
                data=str_data,
                token=fcm_token,
            )

            response_id = messaging.send(message)
            logger.info(f"[FCM] FCM message sent successfully: {response_id}")
            return True

        except Exception as e:
            logger.error(f"[FCM] Notification dispatch failed for token {fcm_token[:12] if fcm_token else 'NONE'}...: {e}. Non-fatal for corridor algorithm.")
            return False

fcm_handler = FCMNotificationHandler()
