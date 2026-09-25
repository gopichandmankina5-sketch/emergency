import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

interface Props {
  isRunning: boolean;
  trafficDensity: number;
  emergencySpeed: number;
  onDensityChanged: (count: number) => void;
  onSpeedChanged: (speed: number) => void;
  onToggleSimulation: () => void;
}

export const SimulationControls: React.FC<Props> = ({
  isRunning,
  trafficDensity,
  emergencySpeed,
  onDensityChanged,
  onSpeedChanged,
  onToggleSimulation,
}) => {
  return (
    <View style={styles.container}>
      <View style={styles.controlRow}>
        <Text style={styles.label}>Traffic Density: {trafficDensity} vehicles</Text>
        <View style={styles.buttonGroup}>
          <TouchableOpacity
            style={styles.adjustBtn}
            onPress={() => onDensityChanged(Math.max(5, trafficDensity - 5))}
          >
            <Ionicons name="remove" size={18} color="#ffffff" />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.adjustBtn}
            onPress={() => onDensityChanged(Math.min(50, trafficDensity + 5))}
          >
            <Ionicons name="add" size={18} color="#ffffff" />
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.controlRow}>
        <Text style={styles.label}>Emergency Speed: {Math.round(emergencySpeed)} km/h</Text>
        <View style={styles.buttonGroup}>
          <TouchableOpacity
            style={styles.adjustBtn}
            onPress={() => onSpeedChanged(Math.max(20, emergencySpeed - 10))}
          >
            <Ionicons name="remove" size={18} color="#ffffff" />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.adjustBtn}
            onPress={() => onSpeedChanged(Math.min(120, emergencySpeed + 10))}
          >
            <Ionicons name="add" size={18} color="#ffffff" />
          </TouchableOpacity>
        </View>
      </View>

      <TouchableOpacity
        style={[styles.mainBtn, isRunning ? styles.stopBtn : styles.startBtn]}
        onPress={onToggleSimulation}
      >
        <Ionicons name={isRunning ? 'stop' : 'play'} size={22} color="#ffffff" style={{ marginRight: 8 }} />
        <Text style={styles.mainBtnText}>
          {isRunning ? 'STOP SIMULATION' : 'RUN EMERGENCY SIMULATION'}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#0f172a',
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#334155',
  },
  controlRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  label: {
    color: '#e2e8f0',
    fontSize: 14,
    fontWeight: '600',
  },
  buttonGroup: {
    flexDirection: 'row',
  },
  adjustBtn: {
    backgroundColor: '#334155',
    width: 32,
    height: 32,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 8,
  },
  mainBtn: {
    flexDirection: 'row',
    height: 48,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
  },
  startBtn: {
    backgroundColor: '#0d9488', // Teal
  },
  stopBtn: {
    backgroundColor: '#dc2626', // Red
  },
  mainBtnText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
});
