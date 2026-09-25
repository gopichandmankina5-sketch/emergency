import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { ConnectionStatus } from '../hooks/useConnectionStatus';

interface Props {
  status: ConnectionStatus;
  showTimeAgo?: boolean;
}

export const ConnectionBadge: React.FC<Props> = ({ status, showTimeAgo = true }) => {
  return (
    <View style={[styles.container, { backgroundColor: status.badgeColor + '22', borderColor: status.badgeColor }]}>
      <View style={[styles.dot, { backgroundColor: status.dotColor }]} />
      <Text style={[styles.statusText, { color: status.dotColor }]}>{status.statusText}</Text>

      {showTimeAgo && status.lastUpdateSecondsAgo < 300 && (
        <Text style={styles.timeAgoText}>
          {status.lastUpdateSecondsAgo === 0 ? ' (just now)' : ` (${status.lastUpdateSecondsAgo}s ago)`}
        </Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 20,
    borderWidth: 1,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 6,
  },
  statusText: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  timeAgoText: {
    fontSize: 11,
    color: '#94a3b8',
    marginLeft: 2,
  },
});
