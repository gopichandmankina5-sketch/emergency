import React from 'react';
import { View, Text, StyleSheet, ScrollView, Switch } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useDriver } from '../context/DriverContext';
import { CorridorMap } from '../components/CorridorMap';
import { AlertBanner } from '../components/AlertBanner';
import { ConnectionBadge } from '../components/ConnectionBadge';

export const DriverScreen: React.FC = () => {
  const {
    vehicleId,
    locationEnabled,
    latitude,
    longitude,
    speed,
    heading,
    activeAlert,
    connectionStatus,
    toggleLocationPermission,
  } = useDriver();

  return (
    <View style={styles.container}>
      {/* Header Bar */}
      <View style={styles.headerBar}>
        <View style={styles.headerLeft}>
          <Text style={styles.headerTitle}>🚗 Driver Mode</Text>
          <Text style={styles.vehicleIdBadge}>{vehicleId}</Text>
        </View>

        <View style={styles.headerRight}>
          <ConnectionBadge status={connectionStatus} />
          <View style={styles.gpsToggleGroup}>
            <Text style={[styles.gpsText, locationEnabled ? styles.gpsOn : styles.gpsOff]}>
              {locationEnabled ? 'GPS ON' : 'GPS OFF'}
            </Text>
            <Switch
              value={locationEnabled}
              onValueChange={toggleLocationPermission}
              trackColor={{ false: '#78350f', true: '#047857' }}
              thumbColor={locationEnabled ? '#34d399' : '#f59e0b'}
            />
          </View>
        </View>
      </View>

      {/* Corridor Map */}
      <View style={styles.mapContainer}>
        <CorridorMap
          centerLatitude={latitude}
          centerLongitude={longitude}
          userVehicleId={vehicleId}
          isEmergencyVehicle={false}
        />
      </View>

      {/* Alert Banner & Telemetry Footer */}
      <ScrollView style={styles.controlPanel} contentContainerStyle={{ paddingBottom: 24 }}>
        <AlertBanner alert={activeAlert} locationEnabled={locationEnabled} />

        {/* Live Telemetry Info Card */}
        <View style={styles.telemetryCard}>
          <View style={styles.telemetryItem}>
            <Ionicons name="car-sharp" size={16} color="#818cf8" />
            <Text style={styles.telemetryLabel}>Vehicle ID</Text>
            <Text style={styles.telemetryValue}>{vehicleId}</Text>
          </View>

          <View style={styles.dividerVertical} />

          <View style={styles.telemetryItem}>
            <Ionicons name="speedometer-sharp" size={16} color="#38bdf8" />
            <Text style={styles.telemetryLabel}>Speed</Text>
            <Text style={styles.telemetryValue}>{Math.round(speed)} km/h</Text>
          </View>

          <View style={styles.dividerVertical} />

          <View style={styles.telemetryItem}>
            <Ionicons name="compass-sharp" size={16} color="#34d399" />
            <Text style={styles.telemetryLabel}>Heading</Text>
            <Text style={styles.telemetryValue}>{Math.round(heading)}°</Text>
          </View>
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
    backgroundColor: '#1e1b4b', // Dark Indigo
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTitle: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '800',
  },
  vehicleIdBadge: {
    backgroundColor: '#312e81',
    color: '#a5b4fc',
    fontSize: 12,
    fontWeight: '800',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    marginLeft: 8,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  gpsToggleGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    marginLeft: 10,
  },
  gpsText: {
    fontSize: 11,
    fontWeight: '800',
    marginRight: 4,
  },
  gpsOn: {
    color: '#34d399',
  },
  gpsOff: {
    color: '#fbbf24',
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
  telemetryCard: {
    flexDirection: 'row',
    backgroundColor: '#1e293b',
    borderRadius: 14,
    padding: 12,
    justifyContent: 'space-around',
    alignItems: 'center',
    marginTop: 8,
    borderWidth: 1,
    borderColor: '#334155',
  },
  telemetryItem: {
    alignItems: 'center',
  },
  telemetryLabel: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '600',
    marginTop: 2,
  },
  telemetryValue: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '800',
    marginTop: 2,
  },
  dividerVertical: {
    width: 1,
    height: 30,
    backgroundColor: '#334155',
  },
});
