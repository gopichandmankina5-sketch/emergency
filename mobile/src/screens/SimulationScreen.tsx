import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useSimulation } from '../context/SimulationContext';
import { CorridorMap } from '../components/CorridorMap';
import { SimulationControls } from '../components/SimulationControls';
import { VehicleStatCard } from '../components/VehicleStatCard';
import { ConnectionBadge } from '../components/ConnectionBadge';

export const SimulationScreen: React.FC = () => {
  const {
    isSimulationRunning,
    trafficDensityCount,
    emergencySpeedKmh,
    corridorResult,
    simulatedVehicles,
    connectionStatus,
    setTrafficDensity,
    setEmergencySpeed,
    runEmergencySimulation,
    stopSimulation,
  } = useSimulation();

  return (
    <View style={styles.container}>
      {/* Header Bar */}
      <View style={styles.headerBar}>
        <Text style={styles.headerTitle}>🎮 Interactive Corridor Simulator</Text>
        <ConnectionBadge status={connectionStatus} />
      </View>

      {/* Corridor Map */}
      <View style={styles.mapContainer}>
        <CorridorMap
          centerLatitude={13.0800}
          centerLongitude={80.2680}
          corridor={corridorResult}
          vehicles={simulatedVehicles}
          userVehicleId="AMB001"
          isEmergencyVehicle={true}
        />
      </View>

      {/* Control Panel & Stat Summary */}
      <ScrollView style={styles.controlPanel} contentContainerStyle={{ paddingBottom: 24 }}>
        <View style={styles.statsRow}>
          <VehicleStatCard
            title="Total Vehicles"
            value={corridorResult?.totalNearbyVehicles ?? simulatedVehicles.length}
            icon="car-sport"
            color="#38bdf8"
          />
          <VehicleStatCard
            title="Obstructing"
            value={corridorResult?.obstructingVehiclesCount ?? 0}
            icon="warning"
            color="#fbbf24"
          />
          <VehicleStatCard
            title="Instructed"
            value={corridorResult?.instructedToMoveCount ?? 0}
            icon="git-branch"
            color="#34d399"
          />
        </View>

        <View style={{ marginTop: 12 }}>
          <SimulationControls
            isRunning={isSimulationRunning}
            trafficDensity={trafficDensityCount}
            emergencySpeed={emergencySpeedKmh}
            onDensityChanged={setTrafficDensity}
            onSpeedChanged={setEmergencySpeed}
            onToggleSimulation={isSimulationRunning ? stopSimulation : runEmergencySimulation}
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
    backgroundColor: '#134e4a', // Dark Teal
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '800',
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
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
});
