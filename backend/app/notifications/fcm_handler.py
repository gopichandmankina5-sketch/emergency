import logging
import os
import json
import time
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
        if self._initialized and self._firebase_app:
            return True

        if settings.FCM_SIMULATION:
            logger.info("[FCM] Running in FCM_SIMULATION mode. Firebase Admin initialization skipped.")
            return False

        try:
            import firebase_admin
            from firebase_admin import credentials

            cred = None
            log_source = None
            project_id = None

            # 1. Try FIREBASE_CREDENTIALS_JSON from env / settings
            cred_json_str = settings.FIREBASE_CREDENTIALS_JSON or os.getenv("FIREBASE_CREDENTIALS_JSON", "")
            if cred_json_str and cred_json_str.strip():
                try:
                    cred_dict = json.loads(cred_json_str.strip())
                    if isinstance(cred_dict, dict) and "private_key" in cred_dict:
                        cred = credentials.Certificate(cred_dict)
                        project_id = cred_dict.get("project_id", "unknown")
                        log_source = "FIREBASE_CREDENTIALS_JSON env"
                    else:
                        logger.error("[FCM] FIREBASE_CREDENTIALS_JSON is invalid: missing private_key field.")
                except Exception as json_err:
                    logger.error(f"[FCM] Failed to parse FIREBASE_CREDENTIALS_JSON env: {json_err}")

            # 2. Try FIREBASE_CREDENTIALS_PATH or GOOGLE_APPLICATION_CREDENTIALS file
            if not cred:
                cred_path = settings.FIREBASE_CREDENTIALS_PATH or os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
                if cred_path and os.path.isfile(cred_path):
                    try:
                        with open(cred_path, "r", encoding="utf-8") as f:
                            cred_dict = json.load(f)
                            project_id = cred_dict.get("project_id", "unknown")
                        cred = credentials.Certificate(cred_path)
                        log_source = f"file ({os.path.basename(cred_path)})"
                    except Exception as file_err:
                        logger.error(f"[FCM] Failed to load credentials from file {cred_path}: {file_err}")

            # 3. If no explicit credentials were found, fail clearly (DO NOT fall back to ApplicationDefault)
            if not cred:
                logger.error("[FCM] Firebase credentials unavailable")
                logger.error("[FCM] Missing configuration: Neither valid FIREBASE_CREDENTIALS_JSON env nor FIREBASE_CREDENTIALS_PATH file was found.")
                logger.error("[FCM] Please set FIREBASE_CREDENTIALS_JSON or FIREBASE_CREDENTIALS_PATH environment variable on Render.")
                return False

            if firebase_admin._apps:
                self._firebase_app = firebase_admin.get_app()
            else:
                self._firebase_app = firebase_admin.initialize_app(cred)

            self._initialized = True
            logger.info(f"[FCM] Firebase credentials loaded")
            logger.info(f"[FCM] Firebase project: {project_id or getattr(self._firebase_app, 'project_id', 'unknown')}")
            return True

        except ImportError:
            logger.warning("[FCM] 'firebase-admin' package is not installed. Running in simulation mode.")
            return False
        except Exception as e:
            logger.error(f"[FCM] Failed to initialize Firebase Admin SDK: {e}")
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
            str_data.setdefault("type", "EMERGENCY_CORRIDOR_ALERT")
            str_data.setdefault("vehicleId", v_id)
            str_data.setdefault("emergencyVehicleId", str(data_payload.get("emergencyVehicleId", "AMB001")))
            str_data.setdefault("action", str(data_payload.get("action", "")))
            str_data.setdefault("actionText", str(data_payload.get("actionText", "")))
            str_data.setdefault("distance", str(data_payload.get("distance", "0")))
            str_data.setdefault("eta", str(data_payload.get("eta", "0")))
            str_data.setdefault("timestamp", str(data_payload.get("timestamp", "")))
            str_data.setdefault("alertId", str(data_payload.get("alertId", f"alert-{v_id}-{int(time.time())}")))
            str_data.setdefault("emergencyActive", "true")

            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        channel_id="emergency_corridor_loud_v3",
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

            response_id = messaging.send(message, app=self._firebase_app)
            logger.info(f"[FCM] Message sent successfully: {response_id}")
            return True

        except Exception as e:
            logger.error(f"[FCM] Notification dispatch failed: {e}")
            return False

fcm_handler = FCMNotificationHandler()
