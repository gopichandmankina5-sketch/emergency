import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

interface Props {
  title: string;
  value: string | number;
  icon: keyof typeof Ionicons.glyphMap;
  color: string;
}

export const VehicleStatCard: React.FC<Props> = ({ title, value, icon, color }) => {
  return (
    <View style={[styles.card, { borderLeftColor: color }]}>
      <View style={styles.row}>
        <Ionicons name={icon} size={20} color={color} />
        <Text style={styles.title} numberOfLines={1}>{title}</Text>
      </View>
      <Text style={[styles.value, { color }]}>{value}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    flex: 1,
    backgroundColor: '#1e293b',
    padding: 12,
    borderRadius: 12,
    borderLeftWidth: 4,
    marginHorizontal: 4,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  title: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '600',
    marginLeft: 6,
  },
  value: {
    fontSize: 20,
    fontWeight: '800',
  },
});
