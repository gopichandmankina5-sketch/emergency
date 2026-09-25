import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Switch } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useEmergency } from '../context/EmergencyContext';
import { CorridorMap } from '../components/CorridorMap';
import { VehicleStatCard } from '../components/VehicleStatCard';
import { ConnectionBadge } from '../components/ConnectionBadge';

export const EmergencyScreen: React.FC = () => {
  const {
    isEmergencyActive,
    emergencyVehicleId,
    emergencyType,
    latitude,
    longitude,
    speed,
    heading,
    activeCorridor,
    nearbyVehicles,
    isLiveGpsMode,
    connectionStatus,
    setEmergencyType,
    toggleLiveGpsMode,
    startEmergencyMission,
    stopEmergencyMission,
  } = useEmergency();

  const types = ['AMBULANCE', 'FIRE', 'POLICE'];

  return (
    <View style={styles.container}>
      {/* Header Bar */}
      <View style={styles.headerBar}>
        <View style={styles.headerTitleRow}>
          <Text style={styles.headerTitle}>🚨 Emergency Vehicle Mode</Text>
          <Text style={styles.vehicleIdBadge}>{emergencyVehicleId}</Text>
        </View>
        <ConnectionBadge status={connectionStatus} />
      </View>

      {/* Map View */}
      <View style={styles.mapContainer}>
        <CorridorMap
          centerLatitude={latitude}
          centerLongitude={longitude}
          corridor={activeCorridor}
          vehicles={nearbyVehicles}
          userVehicleId={emergencyVehicleId}
          isEmergencyVehicle={true}
        />
      </View>

      {/* Control & Telemetry Panel */}
      <ScrollView style={styles.controlPanel} contentContainerStyle={{ paddingBottom: 24 }}>
        {/* GPS Mode & Telemetry Header */}
        <View style={styles.gpsRow}>
          <View style={styles.gpsLabelGroup}>
            <Ionicons name="location-sharp" size={18} color={isLiveGpsMode ? '#34d399' : '#f59e0b'} />
            <Text style={styles.gpsLabel}>
              {isLiveGpsMode ? 'Real GPS Tracking (ON)' : 'Simulated GPS Stream'}
            </Text>
          </View>
          <Switch
            value={isLiveGpsMode}
            onValueChange={toggleLiveGpsMode}
            trackColor={{ false: '#475569', true: '#059669' }}
            thumbColor={isLiveGpsMode ? '#34d399' : '#cbd5e1'}
          />
        </View>

        {/* Emergency Type Selector */}
        <Text style={styles.sectionLabel}>EMERGENCY DISPATCH TYPE</Text>
        <View style={styles.typeRow}>
          {types.map((t) => (
            <TouchableOpacity
              key={t}
              style={[styles.typeBtn, emergencyType === t && styles.activeTypeBtn]}
              onPress={() => setEmergencyType(t)}
            >
              <Text style={[styles.typeBtnText, emergencyType === t && styles.activeTypeBtnText]}>{t}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Start / Stop Emergency Button */}
        <TouchableOpacity
          style={[styles.actionBtn, isEmergencyActive ? styles.stopBtn : styles.startBtn]}
          onPress={isEmergencyActive ? stopEmergencyMission : startEmergencyMission}
        >
          <Ionicons
            name={isEmergencyActive ? 'square-sharp' : 'flash-sharp'}
            size={22}
            color="#ffffff"
            style={{ marginRight: 8 }}
          />
          <Text style={styles.actionBtnText}>
            {isEmergencyActive ? 'STOP EMERGENCY MISSION' : 'START LIVE EMERGENCY'}
          </Text>
        </TouchableOpacity>

        {/* Telemetry Stats Bar */}
        <View style={styles.telemetryBar}>
          <Text style={styles.telemetryText}>Lat: {latitude.toFixed(4)}</Text>
          <Text style={styles.telemetryText}>Lon: {longitude.toFixed(4)}</Text>
          <Text style={styles.telemetryText}>Speed: {Math.round(speed)} km/h</Text>
          <Text style={styles.telemetryText}>Heading: {Math.round(heading)}°</Text>
        </View>

        {/* Corridor Analytics Stat Cards */}
        <View style={styles.statsRow}>
          <VehicleStatCard
            title="Nearby"
            value={activeCorridor?.totalNearbyVehicles ?? nearbyVehicles.length}
            icon="car-sport-outline"
            color="#38bdf8"
          />
          <VehicleStatCard
            title="Obstructing"
            value={activeCorridor?.obstructingVehiclesCount ?? 0}
            icon="warning-outline"
            color="#fbbf24"
          />
          <VehicleStatCard
            title="Instructed"
            value={activeCorridor?.instructedToMoveCount ?? 0}
            icon="git-branch-outline"
            color="#34d399"
          />
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0b0f19',
  },
  headerBar: {
    paddingTop: 48,
    paddingHorizontal: 16,
    paddingBottom: 12,
    backgroundColor: '#7f1d1d',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTitle: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '800',
  },
  vehicleIdBadge: {
    backgroundColor: '#991b1b',
    color: '#fef08a',
    fontSize: 11,
    fontWeight: '800',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
    marginLeft: 8,
  },
  mapContainer: {
    flex: 5,
    margin: 12,
  },
  controlPanel: {
    flex: 4,
    backgroundColor: '#0f172a',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingHorizontal: 16,
    paddingTop: 12,
  },
  gpsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
    backgroundColor: '#1e293b',
    padding: 10,
    borderRadius: 12,
  },
  gpsLabelGroup: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  gpsLabel: {
    color: '#e2e8f0',
    fontSize: 13,
    fontWeight: '600',
    marginLeft: 6,
  },
  sectionLabel: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.8,
    marginBottom: 6,
  },
  typeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  typeBtn: {
    flex: 1,
    backgroundColor: '#1e293b',
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
    marginHorizontal: 3,
    borderWidth: 1,
    borderColor: '#334155',
  },
  activeTypeBtn: {
    backgroundColor: '#dc2626',
    borderColor: '#fca5a5',
  },
  typeBtnText: {
    color: '#94a3b8',
    fontSize: 12,
    fontWeight: '700',
  },
  activeTypeBtnText: {
    color: '#ffffff',
  },
  actionBtn: {
    height: 50,
    borderRadius: 12,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  startBtn: {
    backgroundColor: '#dc2626',
  },
  stopBtn: {
    backgroundColor: '#475569',
  },
  actionBtnText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  telemetryBar: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    backgroundColor: '#1e293b',
    paddingVertical: 8,
    borderRadius: 10,
    marginBottom: 12,
  },
  telemetryText: {
    color: '#cbd5e1',
    fontSize: 11,
    fontWeight: '600',
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
});
