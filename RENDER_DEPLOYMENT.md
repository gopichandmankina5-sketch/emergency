# Render Backend Deployment Guide
## Dynamic Emergency Corridor Allocation System

This document provides complete, step-by-step guidelines for deploying the Python backend service to [Render](https://render.com/).

---

## 📋 Table of Contents
1. [Prerequisites](#-prerequisites)
2. [Project Structure Overview](#-project-structure-overview)
3. [Step 1: Database Setup (MongoDB Atlas)](#step-1-database-setup-mongodb-atlas)
4. [Step 2: Manual Deployment via Render Dashboard](#step-2-manual-deployment-via-render-dashboard)
5. [Step 3: Automated Deployment via Render Blueprint (`render.yaml`)](#step-3-automated-deployment-via-render-blueprint-renderyaml)
6. [Step 4: Environment Variables Configuration](#step-4-environment-variables-configuration)
7. [Step 5: Managing Firebase Service Account Key](#step-5-managing-firebase-service-account-key)
8. [Step 6: Updating Frontend and Mobile App API URLs](#step-6-updating-frontend-and-mobile-app-api-urls)
9. [Verification & Health Checks](#-verification--health-checks)
10. [Troubleshooting & Common Issues](#-troubleshooting--common-issues)

---

## 🔑 Prerequisites

Before initiating deployment, ensure you have:
* A [Render Account](https://dashboard.render.com/).
* A Git repository hosted on **GitHub** or **GitLab** containing your codebase.
* A [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) database cluster running in the cloud.
* (Optional) Firebase project with service account JSON key for FCM push notifications.

---

## 📁 Project Structure Overview

The repository is structured with the backend located in the `backend/` directory:

```text
.
├── backend/
│   ├── app/
│   │   ├── algorithms/
│   │   ├── database/
│   │   ├── models/
│   │   ├── notifications/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── config.py
│   │   └── main.py
│   ├── firebase-service-account.json
│   ├── requirements.txt
│   └── .env
├── render.yaml
└── RENDER_DEPLOYMENT.md
```

---

## Step 1: Database Setup (MongoDB Atlas)

Because Render Web Services use dynamic IP addresses, you must configure network access on your MongoDB Atlas cluster:

1. Log into **MongoDB Atlas**.
2. Select your project and navigate to **Network Access** under Security.
3. Click **+ Add IP Address**.
4. Click **Allow Access from Anywhere** (`0.0.0.0/0`) or enter `0.0.0.0/0` in the IP Address field.
5. Click **Confirm**.
6. Under **Database**, click **Connect** > **Drivers** to get your connection string:
   ```text
   mongodb+srv://<username>:<password>@cluster0.abcde.mongodb.net/?retryWrites=true&w=majority
   ```

---

## Step 2: Manual Deployment via Render Dashboard

### 1. Create a New Web Service
1. Go to the [Render Dashboard](https://dashboard.render.com/).
2. Click **New +** and select **Web Service**.
3. Connect your **GitHub / GitLab repository**.

### 2. Configure Service Parameters

Fill in the service details as follows:

| Field | Value | Notes |
| :--- | :--- | :--- |
| **Name** | `emergency-corridor-backend` | Unique identifier for your web service |
| **Region** | *Select closest region* (e.g. Singapore / Oregon) | Choose low-latency region |
| **Branch** | `main` | Production deployment branch |
| **Root Directory** | `backend` | **Crucial:** Points to the backend folder |
| **Runtime** | `Python 3` | Render automatically selects Python environment |
| **Build Command** | `pip install -r requirements.txt` | Installs dependencies |
| **Start Command** | `gunicorn --bind 0.0.0.0:$PORT --workers 2 app.main:app` | WSGI server bound to dynamic port |
| **Instance Type** | `Free` (or `Starter`) | Choose according to resource needs |

> **Note on Start Commands:**
> * For **Gunicorn (WSGI - Recommended)**: `gunicorn --bind 0.0.0.0:$PORT --workers 2 app.main:app`
> * For **Uvicorn (ASGI)**: `uvicorn app.main:asgi_app --host 0.0.0.0 --port $PORT`

---

## Step 3: Automated Deployment via Render Blueprint (`render.yaml`)

You can automate deployment using Infrastructure-as-Code by utilizing the included [`render.yaml`](file:///c:/Users/gopic/New%20folder%20%282%29/render.yaml) file:

1. Push `render.yaml` to the root of your GitHub repository.
2. In Render Dashboard, click **New +** > **Blueprint**.
3. Connect your repository. Render will automatically detect `render.yaml` and provision the web service with all pre-configured settings.

---

## Step 4: Environment Variables Configuration

In Render Dashboard, navigate to **Environment** tab under your Web Service settings and add the following keys:

| Environment Variable | Recommended Value / Example | Required | Description |
| :--- | :--- | :--- | :--- |
| `MONGODB_URI` | `mongodb+srv://user:pass@cluster.mongodb.net/...` | **Yes** | Cloud MongoDB Atlas URI |
| `MONGODB_DATABASE` | `corridor_db` | **Yes** | Primary database name |
| `DB_NAME` | `corridor_db` | Optional | Fallback database name |
| `FCM_SIMULATION` | `true` (or `false` for live FCM) | **Yes** | Toggle simulated vs real FCM |
| `GPS_STALE_TIMEOUT_SECONDS` | `60.0` | Optional | GPS timeout limit in seconds |
| `PYTHON_VERSION` | `3.11.0` | Optional | Pins Python version on Render |

---

## Step 5: Managing Firebase Service Account Key

If `FCM_SIMULATION` is set to `false`, the backend requires Firebase Admin SDK credentials. Choose one of the following methods:

### Method A: Render Secret Files (Recommended)
1. Go to your Web Service in Render Dashboard.
2. Navigate to **Environment** > **Secret Files**.
3. Click **Add Secret File**.
4. Set **Filename**: `firebase-service-account.json`.
5. Paste the contents of your Firebase service account JSON key into the file contents box.
6. Set the Environment Variable:
   ```env
   FIREBASE_CREDENTIALS_PATH=/etc/secrets/firebase-service-account.json
   ```

### Method B: Raw Environment Variable (`FIREBASE_CREDENTIALS_JSON`)
1. Copy the entire contents of `firebase-service-account.json` as a single string.
2. In Render Environment variables, add key `FIREBASE_CREDENTIALS_JSON` and paste the raw JSON string.

---

## Step 6: Updating Frontend and Mobile App API URLs

Once deployed, Render provides a public URL for your web service:
`https://emergency-corridor-backend.onrender.com`

Update the backend base URL across client applications:

### Flutter Mobile / Emergency Vehicle App (`lib/services/api_service.dart`)
```dart
class ApiService {
  // Update local URL to Render URL
  static const String baseUrl = "https://emergency-corridor-backend.onrender.com";
}
```

### React / Web Frontend (`frontend/src/config.js` or `.env`)
```env
VITE_API_BASE_URL=https://emergency-corridor-backend.onrender.com
```

---

## 🔍 Verification & Health Checks

### 1. View Deployment Logs
Go to **Logs** tab in Render Dashboard to confirm successful startup:
```text
==> Running 'gunicorn --bind 0.0.0.0:10000 --workers 2 app.main:app'
[INFO] Starting gunicorn 21.2.0
[INFO] Listening at: http://0.0.0.0:10000
[INFO] Using worker: sync
[INFO] Booting worker with pid: 52
```

### 2. Test Endpoints
Test public backend endpoints via browser or `curl`:

* **Health / Root Check:**
  ```bash
  curl -I https://emergency-corridor-backend.onrender.com/
  ```

* **Analytics API:**
  ```bash
  curl https://emergency-corridor-backend.onrender.com/api/analytics/summary
  ```

* **Vehicles API:**
  ```bash
  curl https://emergency-corridor-backend.onrender.com/api/vehicles
  ```

---

## 🛠 Troubleshooting & Common Issues

### 1. 🚨 Error: 502 Bad Gateway / Port Timeout
* **Cause:** The backend service is not binding to Render's dynamic `$PORT` environment variable.
* **Fix:** Ensure your start command uses `$PORT` (e.g. `gunicorn --bind 0.0.0.0:$PORT app.main:app`). Do **NOT** hardcode port `8000`.

### 2. 🔌 Error: `ServerSelectionTimeoutError` / MongoDB Connection Failure
* **Cause:** MongoDB Atlas is blocking incoming connections from Render's dynamic IP address range.
* **Fix:** Add `0.0.0.0/0` under MongoDB Atlas **Network Access** tab.

### 3. 📦 Error: `ModuleNotFoundError: No module named 'flask'` or `gunicorn`
* **Cause:** Dependencies are missing from `requirements.txt`.
* **Fix:** Ensure `requirements.txt` contains `flask`, `gunicorn`, `a2wsgi`, `pymongo`, `motor`, etc.

### 4. 💤 Free Tier Cold Starts
* **Note:** Render Free instances automatically spin down after 15 minutes of inactivity. The first request after spin-down may take 30–50 seconds to respond.
* **Mitigation:** Upgrade to a Starter instance or use a Uptime Monitoring ping service (e.g. UptimeRobot) to ping `/api/analytics/summary` every 10 minutes.

---
*Created for Dynamic Emergency Corridor Allocation System Deployment.*
