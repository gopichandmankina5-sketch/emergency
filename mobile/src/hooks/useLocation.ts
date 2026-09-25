import { useState, useEffect, useCallback } from 'react';
import { locationService, LocationData } from '../services/locationService';

export function useLocation(autoStart: boolean = false, updateIntervalMs: number = 2000) {
  const [location, setLocation] = useState<LocationData | null>(null);
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [isLocating, setIsLocating] = useState<boolean>(false);

  const requestPermission = useCallback(async () => {
    const granted = await locationService.requestPermission();
    setHasPermission(granted);
    return granted;
  }, []);

  const refreshLocation = useCallback(async () => {
    setIsLocating(true);
    const data = await locationService.getCurrentLocation();
    if (data) {
      setLocation(data);
      setHasPermission(true);
    }
    setIsLocating(false);
    return data;
  }, []);

  useEffect(() => {
    if (!autoStart) return;

    let isMounted = true;

    async function initTracking() {
      const granted = await locationService.requestPermission();
      if (!isMounted) return;
      setHasPermission(granted);

      if (granted) {
        await locationService.startLocationUpdates((data) => {
          if (isMounted) setLocation(data);
        }, updateIntervalMs);
      }
    }

    initTracking();

    return () => {
      isMounted = false;
      locationService.stopLocationUpdates();
    };
  }, [autoStart, updateIntervalMs]);

  return {
    location,
    hasPermission,
    isLocating,
    requestPermission,
    refreshLocation,
  };
}
