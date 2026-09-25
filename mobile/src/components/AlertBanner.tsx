import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { CorridorAlert } from '../models/alert';

interface Props {
  alert: CorridorAlert | null;
  locationEnabled: boolean;
}

export const AlertBanner: React.FC<Props> = ({ alert, locationEnabled }) => {
  // Case 1: Location Disabled
  if (!locationEnabled) {
    return (
      <View style={[styles.container, styles.warningBorder, { backgroundColor: '#7c2d12' }]}>
        <Ionicons name="warning-outline" size={36} color="#fbbf24" style={styles.iconCenter} />
        <Text style={styles.alertTitleWarning}>🚨 EMERGENCY VEHICLE NEARBY</Text>
        <Text style={styles.warningMessage}>
          Precise emergency corridor instructions require location access.
        </Text>
      </View>
    );
  }

  // Case 2: No active alert or NO_ALERT
  if (!alert || alert.action === 'NO_ALERT') {
    return (
      <View style={[styles.container, styles.clearBorder, { backgroundColor: '#064e3b22' }]}>
        <View style={styles.clearRow}>
          <Ionicons name="checkmark-circle-outline" size={32} color="#34d399" />
          <View style={styles.clearTextContainer}>
            <Text style={styles.clearTitle}>PATH CLEAR</Text>
            <Text style={styles.clearSubtext}>No active emergency corridor intervention required.</Text>
          </View>
        </View>
      </View>
    );
  }

  // Case 3: Active Emergency Action Alert
  let backgroundColor = '#991b1b'; // Red
  let iconName: keyof typeof Ionicons.glyphMap = 'arrow-back';
  let actionHeader = 'MOVE LEFT WHEN SAFE';

  switch (alert.action) {
    case 'MOVE_LEFT':
      iconName = 'arrow-back-circle-outline';
      actionHeader = alert.actionText || '➡️ MOVE LEFT WHEN SAFE';
      backgroundColor = '#991b1b';
      break;
    case 'MOVE_RIGHT':
      iconName = 'arrow-forward-circle-outline';
      actionHeader = alert.actionText || '➡️ MOVE RIGHT WHEN SAFE';
      backgroundColor = '#991b1b';
      break;
    case 'SLOW_DOWN':
      iconName = 'speedometer-outline';
      actionHeader = alert.actionText || '⚠️ SLOW DOWN & YIELD';
      backgroundColor = '#c2410c';
      break;
    case 'STAY':
      iconName = 'hand-left-outline';
      actionHeader = alert.actionText || '🛑 STAY IN LANE';
      backgroundColor = '#1e3a8a';
      break;
    case 'LOCATION_OFF_WARNING':
      iconName = 'warning-outline';
      actionHeader = 'LOCATION REQUIRED';
      backgroundColor = '#7c2d12';
      break;
  }

  return (
    <View style={[styles.container, styles.alertBorder, { backgroundColor }]}>
      <View style={styles.headerRow}>
        <MaterialCommunityIcons name="vibrate" size={24} color="#fde047" />
        <Text style={styles.headerTitle}>🚨 EMERGENCY VEHICLE APPROACHING</Text>
      </View>

      <View style={styles.divider} />

      <View style={styles.bodyRow}>
        <View style={styles.iconCircle}>
          <Ionicons name={iconName} size={36} color="#7f1d1d" />
        </View>
        <View style={styles.actionTextContainer}>
          <Text style={styles.vehicleIdText}>Target Vehicle ID: {alert.vehicleId}</Text>
          <Text style={styles.actionText}>{actionHeader}</Text>
        </View>
      </View>

      <View style={styles.metricsRow}>
        <View style={styles.metricCard}>
          <Text style={styles.metricLabel}>Distance</Text>
          <Text style={styles.metricValue}>{Math.round(alert.distance)} m</Text>
        </View>
        <View style={styles.metricCard}>
          <Text style={styles.metricLabel}>ETA</Text>
          <Text style={styles.metricValue}>{Math.round(alert.eta)} sec</Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 16,
    borderRadius: 16,
    marginVertical: 8,
  },
  warningBorder: {
    borderWidth: 2,
    borderColor: '#f59e0b',
  },
  clearBorder: {
    borderWidth: 1.5,
    borderColor: '#059669',
  },
  alertBorder: {
    borderWidth: 2,
    borderColor: '#ffffff',
    shadowColor: '#ef4444',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 10,
    elevation: 8,
  },
  iconCenter: {
    alignSelf: 'center',
    marginBottom: 6,
  },
  alertTitleWarning: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '800',
    textAlign: 'center',
    marginBottom: 4,
  },
  warningMessage: {
    color: '#fef08a',
    fontSize: 13,
    textAlign: 'center',
  },
  clearRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  clearTextContainer: {
    marginLeft: 12,
    flex: 1,
  },
  clearTitle: {
    color: '#34d399',
    fontSize: 15,
    fontWeight: '700',
  },
  clearSubtext: {
    color: '#94a3b8',
    fontSize: 13,
    marginTop: 2,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    color: '#fde047',
    fontSize: 15,
    fontWeight: '800',
    marginLeft: 6,
  },
  divider: {
    height: 1,
    backgroundColor: '#ffffff44',
    marginVertical: 12,
  },
  bodyRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconCircle: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: '#ffffff',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 14,
  },
  actionTextContainer: {
    flex: 1,
  },
  vehicleIdText: {
    color: '#f8fafc',
    fontSize: 12,
    fontWeight: '500',
    opacity: 0.85,
  },
  actionText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '800',
    marginTop: 2,
  },
  metricsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 14,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#ffffff22',
  },
  metricCard: {
    alignItems: 'center',
  },
  metricLabel: {
    color: '#cbd5e1',
    fontSize: 11,
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  metricValue: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '800',
    marginTop: 2,
  },
});
