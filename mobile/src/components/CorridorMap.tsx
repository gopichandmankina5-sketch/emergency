import React from 'react';
import { View, StyleSheet, Text } from 'react-native';
import MapView, { Marker, Polyline, Polygon, PROVIDER_DEFAULT } from 'react-native-maps';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { CorridorResult } from '../models/corridor';
import { Vehicle } from '../models/vehicle';

interface Props {
  centerLatitude: number;
  centerLongitude: number;
  corridor?: CorridorResult | null;
  vehicles?: Vehicle[];
  userVehicleId?: string;
  isEmergencyVehicle?: boolean;
}

export const CorridorMap: React.FC<Props> = ({
  centerLatitude,
  centerLongitude,
  corridor,
  vehicles = [],
  userVehicleId = 'V102',
  isEmergencyVehicle = false,
}) => {
  const initialRegion = {
    latitude: centerLatitude || 13.0827,
    longitude: centerLongitude || 80.2707,
    latitudeDelta: 0.015,
    longitudeDelta: 0.015,
  };

  const predictedRouteCoords = (corridor?.predictedRoute || []).map((pt) => ({
    latitude: pt.latitude,
    longitude: pt.longitude,
  }));

  const corridorPolygonCoords = (corridor?.corridorPolygon || []).map((pt) => ({
    latitude: pt.latitude,
    longitude: pt.longitude,
  }));

  return (
    <View style={styles.container}>
      <MapView
        provider={PROVIDER_DEFAULT}
        style={styles.map}
        initialRegion={initialRegion}
        region={{
          latitude: centerLatitude || 13.0827,
          longitude: centerLongitude || 80.2707,
          latitudeDelta: 0.015,
          longitudeDelta: 0.015,
        }}
        userInterfaceStyle="dark"
      >
        {/* Render Emergency Corridor Boundary Polygon */}
        {corridorPolygonCoords.length >= 3 && (
          <Polygon
            coordinates={corridorPolygonCoords}
            fillColor="rgba(239, 68, 68, 0.25)"
            strokeColor="#ef4444"
            strokeWidth={2}
          />
        )}

        {/* Render Predicted Emergency Vector Route Line */}
        {predictedRouteCoords.length >= 2 && (
          <Polyline
            coordinates={predictedRouteCoords}
            strokeColor="#38bdf8"
            strokeWidth={4}
            lineDashPattern={[6, 4]}
          />
        )}

        {/* Center Vehicle Marker (User or Emergency) */}
        <Marker
          coordinate={{ latitude: centerLatitude, longitude: centerLongitude }}
          title={isEmergencyVehicle ? 'Emergency Vehicle (AMB001)' : `My Vehicle (${userVehicleId})`}
          anchor={{ x: 0.5, y: 0.5 }}
        >
          <View style={[styles.markerBadge, isEmergencyVehicle ? styles.emergencyBadge : styles.driverBadge]}>
            <MaterialCommunityIcons
              name={isEmergencyVehicle ? 'ambulance' : 'car'}
              size={22}
              color="#ffffff"
            />
          </View>
        </Marker>

        {/* Render Nearby Traffic Vehicles */}
        {vehicles.map((v) => {
          if (v.vehicleId === userVehicleId || (isEmergencyVehicle && v.vehicleId === 'AMB001')) {
            return null; // Skip duplicate of self
          }
          const isEv = v.isEmergency || v.vehicleId.startsWith('AMB');
          return (
            <Marker
              key={v.vehicleId}
              coordinate={{ latitude: v.latitude, longitude: v.longitude }}
              title={`Vehicle ${v.vehicleId}`}
              description={`Speed: ${Math.round(v.speed)} km/h | Heading: ${Math.round(v.heading)}°`}
              anchor={{ x: 0.5, y: 0.5 }}
            >
              <View style={[styles.markerBadge, isEv ? styles.emergencyBadge : styles.nearbyBadge]}>
                <Ionicons
                  name={isEv ? 'medical' : 'car-outline'}
                  size={16}
                  color={isEv ? '#ffffff' : '#cbd5e1'}
                />
                <Text style={styles.markerText}>{v.vehicleId}</Text>
              </View>
            </Marker>
          );
        })}
      </MapView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    borderRadius: 16,
    overflow: 'hidden',
    backgroundColor: '#1e293b',
  },
  map: {
    width: '100%',
    height: '100%',
  },
  markerBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 5,
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: '#ffffff',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
  },
  emergencyBadge: {
    backgroundColor: '#dc2626',
    borderColor: '#fef08a',
  },
  driverBadge: {
    backgroundColor: '#4f46e5',
    borderColor: '#818cf8',
  },
  nearbyBadge: {
    backgroundColor: '#334155',
    borderColor: '#64748b',
  },
  markerText: {
    color: '#ffffff',
    fontSize: 10,
    fontWeight: '700',
    marginLeft: 4,
  },
});
