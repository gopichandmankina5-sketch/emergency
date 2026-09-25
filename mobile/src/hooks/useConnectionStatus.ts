import { useState, useEffect } from 'react';

export type ConnectionState = 'LIVE' | 'CONNECTING' | 'OFFLINE' | 'GPS_STALE';

export interface ConnectionStatus {
  state: ConnectionState;
  statusText: string;
  badgeColor: string;
  dotColor: string;
  lastUpdateSecondsAgo: number;
  isGpsStale: boolean;
  recordSuccess: () => void;
  recordFailure: () => void;
  setGpsStale: (stale: boolean) => void;
}

export function useConnectionStatus(): ConnectionStatus {
  const [lastSuccessTime, setLastSuccessTime] = useState<number | null>(null);
  const [consecutiveFailures, setConsecutiveFailures] = useState<number>(0);
  const [isGpsStale, setIsGpsStale] = useState<boolean>(false);
  const [now, setNow] = useState<number>(Date.now());

  useEffect(() => {
    const timer = setInterval(() => {
      setNow(Date.now());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const recordSuccess = () => {
    setLastSuccessTime(Date.now());
    setConsecutiveFailures(0);
  };

  const recordFailure = () => {
    setConsecutiveFailures((prev) => prev + 1);
  };

  const setGpsStale = (stale: boolean) => {
    setIsGpsStale(stale);
  };

  const timeDiffMs = lastSuccessTime ? now - lastSuccessTime : Infinity;
  const lastUpdateSecondsAgo = lastSuccessTime ? Math.floor(timeDiffMs / 1000) : 999;

  let state: ConnectionState = 'OFFLINE';
  let statusText = '🔴 OFFLINE';
  let badgeColor = '#ef4444';
  let dotColor = '#f87171';

  if (isGpsStale) {
    state = 'GPS_STALE';
    statusText = '⚠️ GPS STALE';
    badgeColor = '#f59e0b';
    dotColor = '#fbbf24';
  } else if (lastSuccessTime && timeDiffMs < 3500 && consecutiveFailures === 0) {
    state = 'LIVE';
    statusText = '🟢 LIVE';
    badgeColor = '#10b981';
    dotColor = '#34d399';
  } else if (lastSuccessTime && timeDiffMs < 7000 && consecutiveFailures < 3) {
    state = 'CONNECTING';
    statusText = '🟡 CONNECTING';
    badgeColor = '#eab308';
    dotColor = '#fde047';
  } else {
    state = 'OFFLINE';
    statusText = '🔴 OFFLINE';
    badgeColor = '#ef4444';
    dotColor = '#f87171';
  }

  return {
    state,
    statusText,
    badgeColor,
    dotColor,
    lastUpdateSecondsAgo,
    isGpsStale,
    recordSuccess,
    recordFailure,
    setGpsStale,
  };
}
