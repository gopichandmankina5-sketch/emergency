import os
import json
import unittest
from app.notifications.fcm_handler import FCMNotificationHandler
from app.config import settings

class TestFCMAuthentication(unittest.TestCase):
    def test_firebase_admin_initialization_with_credentials_file(self):
        handler = FCMNotificationHandler()
        initialized = handler._ensure_initialized()
        self.assertTrue(initialized, "Firebase Admin SDK should initialize successfully with Certificate credentials file.")
        self.assertIsNotNone(handler._firebase_app, "Explicit _firebase_app instance must be created.")

    def test_firebase_admin_initialization_with_credentials_json_env(self):
        service_account_path = os.path.join(os.path.dirname(__file__), "firebase-service-account.json")
        if os.path.exists(service_account_path):
            with open(service_account_path, "r", encoding="utf-8") as f:
                json_content = f.read()

            old_path = settings.FIREBASE_CREDENTIALS_PATH
            old_json = settings.FIREBASE_CREDENTIALS_JSON

            try:
                settings.FIREBASE_CREDENTIALS_PATH = ""
                settings.FIREBASE_CREDENTIALS_JSON = json_content

                handler = FCMNotificationHandler()
                initialized = handler._ensure_initialized()
                self.assertTrue(initialized, "Firebase Admin SDK should initialize successfully with FIREBASE_CREDENTIALS_JSON env.")
                self.assertIsNotNone(handler._firebase_app, "Explicit _firebase_app instance must be created.")
            finally:
                settings.FIREBASE_CREDENTIALS_PATH = old_path
                settings.FIREBASE_CREDENTIALS_JSON = old_json

    def test_firebase_credentials_missing_error_handling(self):
        old_path = settings.FIREBASE_CREDENTIALS_PATH
        old_json = settings.FIREBASE_CREDENTIALS_JSON

        try:
            settings.FIREBASE_CREDENTIALS_PATH = "/invalid/nonexistent/path.json"
            settings.FIREBASE_CREDENTIALS_JSON = ""

            handler = FCMNotificationHandler()
            initialized = handler._ensure_initialized()
            self.assertFalse(initialized, "FCM initialization must fail cleanly when no valid credentials exist.")
            self.assertTrue(handler.is_simulation, "Handler should fall back to simulation mode when credentials unavailable.")
        finally:
            settings.FIREBASE_CREDENTIALS_PATH = old_path
            settings.FIREBASE_CREDENTIALS_JSON = old_json

if __name__ == "__main__":
    unittest.main()
