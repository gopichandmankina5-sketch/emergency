import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';
import { EmergencyProvider } from './src/context/EmergencyContext';
import { DriverProvider } from './src/context/DriverContext';
import { SimulationProvider } from './src/context/SimulationContext';
import { EmergencyScreen } from './src/screens/EmergencyScreen';
import { DriverScreen } from './src/screens/DriverScreen';
import { SimulationScreen } from './src/screens/SimulationScreen';
import { AnalyticsScreen } from './src/screens/AnalyticsScreen';

type TabType = 'emergency' | 'driver' | 'simulation' | 'analytics';

export default function App() {
  const [activeTab, setActiveTab] = useState<TabType>('emergency');

  const renderScreen = () => {
    switch (activeTab) {
      case 'emergency':
        return <EmergencyScreen />;
      case 'driver':
        return <DriverScreen />;
      case 'simulation':
        return <SimulationScreen />;
      case 'analytics':
        return <AnalyticsScreen />;
      default:
        return <EmergencyScreen />;
    }
  };

  return (
    <EmergencyProvider>
      <DriverProvider>
        <SimulationProvider>
          <SafeAreaView style={styles.safeArea}>
            <StatusBar style="light" backgroundColor="#0b0f19" />

            {/* Screen View */}
            <View style={styles.screenContainer}>
              {renderScreen()}
            </View>

            {/* Bottom Tab Navigation Bar */}
            <View style={styles.tabBar}>
              <TouchableOpacity
                style={[styles.tabItem, activeTab === 'emergency' && styles.activeTabItem]}
                onPress={() => setActiveTab('emergency')}
              >
                <Ionicons
                  name={activeTab === 'emergency' ? 'medical' : 'medical-outline'}
                  size={22}
                  color={activeTab === 'emergency' ? '#ef4444' : '#94a3b8'}
                />
                <Text style={[styles.tabLabel, activeTab === 'emergency' && styles.activeEmergencyLabel]}>
                  Emergency
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.tabItem, activeTab === 'driver' && styles.activeTabItem]}
                onPress={() => setActiveTab('driver')}
              >
                <Ionicons
                  name={activeTab === 'driver' ? 'car' : 'car-outline'}
                  size={22}
                  color={activeTab === 'driver' ? '#818cf8' : '#94a3b8'}
                />
                <Text style={[styles.tabLabel, activeTab === 'driver' && styles.activeDriverLabel]}>
                  Driver
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.tabItem, activeTab === 'simulation' && styles.activeTabItem]}
                onPress={() => setActiveTab('simulation')}
              >
                <Ionicons
                  name={activeTab === 'simulation' ? 'game-controller' : 'game-controller-outline'}
                  size={22}
                  color={activeTab === 'simulation' ? '#2dd4bf' : '#94a3b8'}
                />
                <Text style={[styles.tabLabel, activeTab === 'simulation' && styles.activeSimLabel]}>
                  Simulation
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.tabItem, activeTab === 'analytics' && styles.activeTabItem]}
                onPress={() => setActiveTab('analytics')}
              >
                <Ionicons
                  name={activeTab === 'analytics' ? 'analytics' : 'analytics-outline'}
                  size={22}
                  color={activeTab === 'analytics' ? '#38bdf8' : '#94a3b8'}
                />
                <Text style={[styles.tabLabel, activeTab === 'analytics' && styles.activeAnalyticsLabel]}>
                  Analytics
                </Text>
              </TouchableOpacity>
            </View>
          </SafeAreaView>
        </SimulationProvider>
      </DriverProvider>
    </EmergencyProvider>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#0b0f19',
  },
  screenContainer: {
    flex: 1,
  },
  tabBar: {
    flexDirection: 'row',
    height: 64,
    backgroundColor: '#0f172a',
    borderTopWidth: 1,
    borderTopColor: '#1e293b',
    justifyContent: 'space-around',
    alignItems: 'center',
    paddingBottom: 4,
  },
  tabItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 6,
  },
  activeTabItem: {
    borderTopWidth: 2,
    borderTopColor: '#38bdf8',
  },
  tabLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: '#94a3b8',
    marginTop: 2,
  },
  activeEmergencyLabel: {
    color: '#ef4444',
    fontWeight: '800',
  },
  activeDriverLabel: {
    color: '#818cf8',
    fontWeight: '800',
  },
  activeSimLabel: {
    color: '#2dd4bf',
    fontWeight: '800',
  },
  activeAnalyticsLabel: {
    color: '#38bdf8',
    fontWeight: '800',
  },
});
