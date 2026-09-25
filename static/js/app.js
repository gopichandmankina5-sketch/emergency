// Dynamic Emergency Corridor System - Front-End JavaScript Engine

let map;
let evMarker = null;
let vehicleMarkers = {};
let unknownMarkers = {};
let predictedPolyline = null;
let corridorPolygonLayer = null;

let isEmergencyActive = false;
let currentMode = 'emergency';
let locationEnabled = true;
let infraSimulationTimer = null;
let isInfraSimulating = false;

const AMB_START = [13.08000, 80.26800];
const AMB_DEST = [13.08000, 80.30000];

// 10 Demo vehicles across 3 lanes for reproducible full demonstration
const DEMO_10_VEHICLES = [
  { id: 'V101', lat: 13.08300, lon: 80.26800, speed: 35, heading: 90, note: "Far North Out of Path" },
  { id: 'V102', lat: 13.08001, lon: 80.26950, speed: 32, heading: 90, note: "Center Lane Blocker -> MOVE RIGHT" },
  { id: 'V103', lat: 13.08004, lon: 80.26980, speed: 30, heading: 90, note: "Left Lane Adjacent -> MOVE RIGHT" },
  { id: 'V104', lat: 13.07997, lon: 80.27000, speed: 28, heading: 90, note: "Right Shoulder -> STAY IN LANE" },
  { id: 'V105', lat: 13.08000, lon: 80.27100, speed: 45, heading: 270, note: "Opposite Direction -> NO ALERT" },
  { id: 'V106', lat: 13.08001, lon: 80.27150, speed: 25, heading: 90, note: "Center Lane Blocker -> MOVE RIGHT" },
  { id: 'V107', lat: 13.08400, lon: 80.27050, speed: 40, heading: 90, note: "Far North -> NO ALERT" },
  { id: 'V108', lat: 13.07600, lon: 80.27000, speed: 38, heading: 90, note: "Far South -> NO ALERT" },
  { id: 'V109', lat: 13.08002, lon: 80.27250, speed: 22, heading: 90, note: "Ahead Center -> MOVE RIGHT" },
  { id: 'V110', lat: 13.07996, lon: 80.27280, speed: 30, heading: 90, note: "Right Lane -> STAY" }
];

// Initial demo unknown road users
const INITIAL_UNKNOWN_USERS = [
  { vehicleId: 'UNKNOWN-001', latitude: 13.08001, longitude: 80.26960, speed: 30, heading: 90, vehicleType: 'CAR' },
  { vehicleId: 'UNKNOWN-002', latitude: 13.08500, longitude: 80.27000, speed: 40, heading: 90, vehicleType: 'TRUCK' }
];

document.addEventListener('DOMContentLoaded', () => {
  initMap();
  registerDemoVehicles();
  registerInitialUnknownUsers();
  fetchSuccessCriteria();
  startGlobalPolling();
});

function initMap() {
  map = L.map('map').setView(AMB_START, 15);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '© OpenStreetMap contributors | Dynamic Emergency Corridor System'
  }).addTo(map);

  const evIcon = L.divIcon({
    className: 'ev-marker-pulse',
    html: `<div>🚑</div>`,
    iconSize: [40, 40],
    iconAnchor: [20, 20]
  });

  evMarker = L.marker(AMB_START, { icon: evIcon }).addTo(map);
  evMarker.bindPopup("<b>AMB001 (AMBULANCE)</b><br>Active Emergency Corridor Mission");
}

function switchMode(mode) {
  currentMode = mode;
  document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
  if (event && event.currentTarget) {
    event.currentTarget.classList.add('active');
  }

  document.getElementById('panel-emergency').style.display = (mode === 'emergency') ? 'block' : 'none';
  document.getElementById('panel-driver').style.display = (mode === 'driver') ? 'block' : 'none';
  document.getElementById('panel-infrastructure').style.display = (mode === 'infrastructure') ? 'block' : 'none';
  document.getElementById('panel-simulation').style.display = (mode === 'simulation') ? 'block' : 'none';

  if (mode === 'simulation') {
    fetchSuccessCriteria();
  } else if (mode === 'infrastructure') {
    fetchInfrastructureMonitorData();
  }
}

async function registerDemoVehicles() {
  for (const v of DEMO_10_VEHICLES) {
    try {
      await fetch('/api/vehicles/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ vehicleId: v.id, isEmergency: false })
      });

      await fetch('/api/vehicles/location', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          vehicleId: v.id,
          latitude: v.lat,
          longitude: v.lon,
          speed: v.speed,
          heading: v.heading,
          locationEnabled: true
        })
      });

      renderVehicleMarker(v, 'irrelevant');
    } catch (e) {
      console.warn("Register vehicle warning:", e);
    }
  }
}

async function registerInitialUnknownUsers() {
  for (const u of INITIAL_UNKNOWN_USERS) {
    try {
      await fetch('/api/road-users/observe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(u)
      });
    } catch (e) {
      console.warn("Register unknown user warning:", e);
    }
  }
  fetchInfrastructureMonitorData();
}

function renderVehicleMarker(v, statusType, actionText) {
  let badgeClass = 'v-irrelevant-badge';
  let badgeLabel = v.id;

  if (statusType === 'selected') {
    badgeClass = 'v-selected-badge';
    badgeLabel = `${v.id} ➡️ MOVE`;
  } else if (statusType === 'obstructing') {
    badgeClass = 'v-obstructing-badge';
    badgeLabel = `${v.id} ⚠️ STAY`;
  }

  const vIcon = L.divIcon({
    className: 'custom-v-marker',
    html: `<div style="text-align:center;">🚗<br><span class="${badgeClass}">${badgeLabel}</span></div>`,
    iconSize: [36, 36],
    iconAnchor: [18, 18]
  });

  if (vehicleMarkers[v.id]) {
    vehicleMarkers[v.id].setLatLng([v.lat, v.lon]);
    vehicleMarkers[v.id].setIcon(vIcon);
  } else {
    vehicleMarkers[v.id] = L.marker([v.lat, v.lon], { icon: vIcon }).addTo(map);
  }
  
  if (actionText) {
    vehicleMarkers[v.id].bindPopup(`<b>${v.id}</b><br>Status: ${actionText}`);
  }
}

function renderUnknownMarker(u, hasActiveAlert, actionText) {
  let badgeClass = hasActiveAlert ? 'v-unknown-alert-badge' : 'v-unknown-badge';
  let badgeLabel = hasActiveAlert ? `${u.vehicleId} ⚠️ ${actionText || 'ALERT'}` : `${u.vehicleId} (UNKNOWN)`;

  const uIcon = L.divIcon({
    className: 'custom-u-marker',
    html: `<div style="text-align:center;">⚪<br><span class="${badgeClass}">${badgeLabel}</span></div>`,
    iconSize: [40, 40],
    iconAnchor: [20, 20]
  });

  const lat = u.latitude || u.lat || 13.08001;
  const lon = u.longitude || u.lon || 80.26960;

  if (unknownMarkers[u.vehicleId]) {
    unknownMarkers[u.vehicleId].setLatLng([lat, lon]);
    unknownMarkers[u.vehicleId].setIcon(uIcon);
  } else {
    unknownMarkers[u.vehicleId] = L.marker([lat, lon], { icon: uIcon }).addTo(map);
  }

  unknownMarkers[u.vehicleId].bindPopup(
    `<b>⚪ ${u.vehicleId}</b><br>` +
    `Registration: UNKNOWN<br>` +
    `Type: ${u.vehicleType || 'CAR'}<br>` +
    `Speed: ${u.speed || 0} km/h | Heading: ${u.heading || 90}°<br>` +
    `Delivery: SOFTWARE SIMULATION<br>` +
    (hasActiveAlert ? `<span style="color:#ff5722; font-weight:bold;">Alert: ${actionText}</span>` : `Status: Clear`)
  );
}

async function toggleEmergencyMission() {
  const btn = document.getElementById('btn-start-emergency');
  const badge = document.getElementById('badge-status');

  if (!isEmergencyActive) {
    isEmergencyActive = true;
    btn.innerHTML = '⏹ STOP EMERGENCY MISSION';
    btn.style.background = '#334155';
    badge.innerText = 'MISSION ACTIVE';
    badge.style.color = '#ff3b5c';

    const response = await fetch('/api/emergency/start', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        vehicleId: 'AMB001',
        type: document.getElementById('select-emergency-type').value,
        latitude: AMB_START[0],
        longitude: AMB_START[1],
        speed: 45,
        heading: 90,
        destination: { latitude: AMB_DEST[0], longitude: AMB_DEST[1] }
      })
    });

    const data = await response.json();
    renderCorridor(data.corridor);
    pollDriverAlerts();
    fetchInfrastructureMonitorData();
  } else {
    isEmergencyActive = false;
    btn.innerHTML = '▶ START EMERGENCY MISSION';
    btn.style.background = 'linear-gradient(135deg, var(--accent-red), #be123c)';
    badge.innerText = 'STANDBY';
    badge.style.color = 'var(--text-secondary)';

    await fetch('/api/emergency/stop?vehicleId=AMB001', { method: 'POST' });
    clearCorridorGraphics();
    fetchInfrastructureMonitorData();
  }
}

async function runFullDemonstration() {
  await registerDemoVehicles();
  await registerInitialUnknownUsers();

  if (!isEmergencyActive) {
    await toggleEmergencyMission();
  }

  // Poll corridor and highlight vehicles on map
  const res = await fetch('/api/emergency/AMB001/corridor');
  const data = await res.json();
  renderCorridor(data);
  fetchInfrastructureMonitorData();
  fetchSuccessCriteria();
}

function renderCorridor(corridorData) {
  if (!corridorData) return;

  document.getElementById('metric-nearby').innerText = corridorData.totalNearbyVehicles || 0;
  document.getElementById('metric-obstructing').innerText = corridorData.obstructingVehiclesCount || 0;
  document.getElementById('metric-move').innerText = corridorData.instructedToMoveCount || 0;

  if (corridorData.performance) {
    document.getElementById('perf-calc').innerText = `${corridorData.performance.corridorCalculationTimeMs} ms`;
    document.getElementById('perf-alert').innerText = `${corridorData.performance.alertGenerationTimeMs} ms`;
    document.getElementById('perf-total').innerText = `${corridorData.performance.totalDecisionTimeMs} ms`;
  }

  clearCorridorGraphics();

  if (corridorData.predictedRoute && corridorData.predictedRoute.length > 0) {
    const latlngs = corridorData.predictedRoute.map(p => [p.latitude, p.longitude]);
    predictedPolyline = L.polyline(latlngs, { color: '#ffb703', weight: 4, dashArray: '8, 8' }).addTo(map);
  }

  if (corridorData.corridorPolygon && corridorData.corridorPolygon.length > 0) {
    const polyCoords = corridorData.corridorPolygon.map(p => [p.latitude, p.longitude]);
    corridorPolygonLayer = L.polygon(polyCoords, {
      color: '#ff3b5c',
      fillColor: '#ff3b5c',
      fillOpacity: 0.25,
      weight: 2
    }).addTo(map);
  }

  // Update visual markers based on evaluation analytics
  const alertMap = {};
  if (corridorData.alerts) {
    corridorData.alerts.forEach(a => alertMap[a.vehicleId] = a);
  }

  DEMO_10_VEHICLES.forEach(v => {
    const alert = alertMap[v.id];
    if (alert) {
      if (alert.action === 'MOVE_LEFT' || alert.action === 'MOVE_RIGHT') {
        renderVehicleMarker(v, 'selected', alert.actionText);
      } else {
        renderVehicleMarker(v, 'obstructing', alert.actionText);
      }
    } else {
      renderVehicleMarker(v, 'irrelevant', 'No Alert - Out of Path');
    }
  });
}

function clearCorridorGraphics() {
  if (predictedPolyline) map.removeLayer(predictedPolyline);
  if (corridorPolygonLayer) map.removeLayer(corridorPolygonLayer);
}

// --- Infrastructure Alert Monitor Logic ---

async function fetchInfrastructureMonitorData() {
  try {
    const evStatusLbl = document.getElementById('lbl-infra-ev-status');
    if (evStatusLbl) {
      evStatusLbl.innerText = isEmergencyActive ? 'ACTIVE' : 'INACTIVE';
      evStatusLbl.style.color = isEmergencyActive ? '#ff3b5c' : 'var(--text-secondary)';
    }

    const [usersRes, alertsRes] = await Promise.all([
      fetch('/api/road-users'),
      fetch('/api/infrastructure/alerts?emergencyVehicleId=AMB001')
    ]);

    const users = await usersRes.json();
    const alerts = await alertsRes.json();

    const alertMap = {};
    if (Array.isArray(alerts)) {
      alerts.forEach(a => {
        if (a.active) alertMap[a.vehicleId] = a;
      });
    }

    const container = document.getElementById('infra-users-container');
    if (!container) return;

    if (!Array.isArray(users) || users.length === 0) {
      container.innerHTML = `<div style="font-size:0.75rem; color:var(--text-secondary); text-align:center; padding:10px;">No unknown road users observed yet.</div>`;
      return;
    }

    container.innerHTML = '';
    users.forEach(u => {
      const activeAlert = alertMap[u.vehicleId];
      const hasActive = !!activeAlert;
      const riskColor = hasActive ? (activeAlert.riskLevel === 'HIGH' ? '#ff3b5c' : '#ffb703') : '#10b981';

      const card = document.createElement('div');
      card.style.cssText = `background:rgba(15,23,42,0.8); border:1px solid ${hasActive ? '#ff5722' : 'var(--border-color)'}; border-radius:8px; padding:8px; margin-bottom:6px; font-size:0.75rem;`;
      card.innerHTML = `
        <div style="display:flex; justify-content:space-between; font-weight:bold; margin-bottom:4px;">
          <span>⚪ ${u.vehicleId} (${u.vehicleType || 'CAR'})</span>
          <span style="color:${riskColor};">${hasActive ? '⚠️ ' + (activeAlert.riskLevel || 'ALERT') : 'SAFE'}</span>
        </div>
        <div style="color:var(--text-secondary); font-size:0.7rem; line-height:1.4;">
          <div>Registration: <strong>UNKNOWN</strong> | Delivery: <strong>SOFTWARE SIMULATION</strong></div>
          <div>Location: ${u.latitude.toFixed(5)}, ${u.longitude.toFixed(5)}</div>
          <div>Speed: ${u.speed} km/h | Heading: ${u.heading}°</div>
          ${hasActive ? `<div>Distance: <strong>${activeAlert.distanceMeters || '--'} m</strong></div>` : ''}
          ${hasActive ? `<div style="color:#ff5722; font-weight:bold; margin-top:2px;">Action: ${activeAlert.action}</div>` : '<div style="color:#94a3b8;">Current Action: NO ALERT</div>'}
          <div style="font-size:0.65rem; color:#64748b; margin-top:2px;">Last Seen: ${u.lastSeen ? new Date(u.lastSeen).toLocaleTimeString() : 'Just now'}</div>
        </div>
      `;
      container.appendChild(card);

      renderUnknownMarker(u, hasActive, activeAlert ? activeAlert.action : null);
    });
  } catch (e) {
    console.warn("Error fetching infrastructure monitor data:", e);
  }
}

async function createUnknownVehicle() {
  const vId = document.getElementById('infra-input-id').value.trim() || 'UNKNOWN-001';
  const type = document.getElementById('infra-input-type').value;
  const lat = parseFloat(document.getElementById('infra-input-lat').value);
  const lon = parseFloat(document.getElementById('infra-input-lon').value);
  const speed = parseFloat(document.getElementById('infra-input-speed').value);
  const heading = parseFloat(document.getElementById('infra-input-heading').value);

  await fetch('/api/road-users/observe', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      vehicleId: vId,
      vehicleType: type,
      latitude: lat,
      longitude: lon,
      speed: speed,
      heading: heading
    })
  });

  fetchInfrastructureMonitorData();
  if (isEmergencyActive) {
    const res = await fetch('/api/emergency/AMB001/corridor');
    renderCorridor(await res.json());
  }
}

async function updateUnknownVehiclePosition() {
  const vId = document.getElementById('infra-input-id').value.trim() || 'UNKNOWN-001';
  const lat = parseFloat(document.getElementById('infra-input-lat').value);
  const lon = parseFloat(document.getElementById('infra-input-lon').value);
  const speed = parseFloat(document.getElementById('infra-input-speed').value);
  const heading = parseFloat(document.getElementById('infra-input-heading').value);

  await fetch('/api/road-users/simulate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      vehicleId: vId,
      latitude: lat,
      longitude: lon,
      speed: speed,
      heading: heading
    })
  });

  fetchInfrastructureMonitorData();
  if (isEmergencyActive) {
    const res = await fetch('/api/emergency/AMB001/corridor');
    renderCorridor(await res.json());
  }
}

async function deleteUnknownVehicle() {
  const vId = document.getElementById('infra-input-id').value.trim() || 'UNKNOWN-001';
  await fetch(`/api/road-users/${vId}`, { method: 'DELETE' });

  if (unknownMarkers[vId]) {
    map.removeLayer(unknownMarkers[vId]);
    delete unknownMarkers[vId];
  }

  fetchInfrastructureMonitorData();
  if (isEmergencyActive) {
    const res = await fetch('/api/emergency/AMB001/corridor');
    renderCorridor(await res.json());
  }
}

function toggleInfrastructureSimulation() {
  const btn = document.getElementById('btn-toggle-infra-sim');
  if (!isInfraSimulating) {
    isInfraSimulating = true;
    btn.innerText = '[ STOP SIMULATION ]';
    btn.style.background = '#dc2626';
    btn.style.color = '#fff';

    infraSimulationTimer = setInterval(async () => {
      // Simulate automatic movement for UNKNOWN-001 along its heading
      const inputLat = document.getElementById('infra-input-lat');
      const inputLon = document.getElementById('infra-input-lon');
      let curLat = parseFloat(inputLat.value);
      let curLon = parseFloat(inputLon.value);

      curLon += 0.0001; // Movement along heading 90
      inputLat.value = curLat.toFixed(5);
      inputLon.value = curLon.toFixed(5);

      await updateUnknownVehiclePosition();
    }, 1500);
  } else {
    isInfraSimulating = false;
    clearInterval(infraSimulationTimer);
    infraSimulationTimer = null;
    btn.innerText = '[ START SIMULATION ]';
    btn.style.background = 'var(--accent-amber)';
    btn.style.color = '#000';
  }
}

function startGlobalPolling() {
  setInterval(() => {
    if (currentMode === 'infrastructure') {
      fetchInfrastructureMonitorData();
    }
  }, 2000);
}

function toggleDriverLocation() {
  const chk = document.getElementById('chk-location');
  locationEnabled = chk.checked;
  const statusLbl = document.getElementById('lbl-gps-status');

  if (locationEnabled) {
    statusLbl.innerText = "Location ON (High Precision)";
    statusLbl.style.color = "var(--text-secondary)";
  } else {
    statusLbl.innerText = "Location OFF (General Warning Mode)";
    statusLbl.style.color = "var(--accent-amber)";
  }

  fetch('/api/vehicles/location', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      vehicleId: 'V102',
      latitude: 13.08001,
      longitude: 80.26950,
      locationEnabled: locationEnabled
    })
  }).then(() => pollDriverAlerts());
}

async function pollDriverAlerts() {
  const res = await fetch('/api/alerts/V102');
  const data = await res.json();
  const card = document.getElementById('driver-alert-card');

  if (!locationEnabled) {
    card.className = "alert-card alert-warning";
    document.getElementById('alert-header-text').innerText = "GENERAL PROXIMITY WARNING";
    document.getElementById('alert-action-text').innerText = "🚨 EMERGENCY VEHICLE NEARBY";
    document.getElementById('alert-dist').innerText = "Approx. 150 m";
    document.getElementById('alert-eta').innerText = "-- s";
    return;
  }

  if (data.hasAlert && data.latestAlert) {
    const alert = data.latestAlert;
    card.className = "alert-card";
    document.getElementById('alert-header-text').innerText = "PERSONALIZED CORRIDOR INSTRUCTION";
    document.getElementById('alert-action-text').innerText = alert.actionText;
    document.getElementById('alert-dist').innerText = alert.distance + " m";
    document.getElementById('alert-eta').innerText = alert.eta + " s";
  } else {
    card.className = "alert-card alert-none";
    document.getElementById('alert-header-text').innerText = "PATH CLEAR";
    document.getElementById('alert-action-text').innerText = "STAY IN LANE";
    document.getElementById('alert-dist').innerText = "-- m";
    document.getElementById('alert-eta').innerText = "-- s";
  }
}

async function fetchSuccessCriteria() {
  try {
    const res = await fetch('/api/success-criteria');
    const data = await res.json();
    const tbody = document.getElementById('tbl-success-criteria');
    tbody.innerHTML = '';

    data.criteria.forEach(c => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${c.id}</td>
        <td><strong>${c.name}</strong><br><span style="font-size:0.7rem; color:var(--text-secondary);">${c.notes}</span></td>
        <td><span class="pass-badge">${c.status}</span></td>
      `;
      tbody.appendChild(tr);
    });

    document.getElementById('lbl-overall-pass').innerText = `${data.passed} / ${data.totalCriteria} PASS`;
  } catch (e) {
    console.warn("Error loading success criteria:", e);
  }
}

function exportAnalyticsCSV() {
  window.location.href = '/api/analytics/export-csv';
}
