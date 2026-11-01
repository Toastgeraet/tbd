import * as Updates from 'expo-updates';
import { useCallback } from 'react';
import { Platform } from 'react-native';

/**
 * State of over-the-air updates plus the two actions the UI needs. The app checks for an update on every
 * start and downloads it in the background (expo-updates default); `isUpdatePending` then means it is
 * downloaded and applies on restart.
 */
// The web module reports isEnabled = true, but there are no OTA updates for the web preview.
const isEnabled = Updates.isEnabled && Platform.OS !== 'web';

export function useAppUpdates() {
  const state = Updates.useUpdates();

  const checkAndDownload = useCallback(async () => {
    if (!isEnabled) return;
    try {
      const result = await Updates.checkForUpdateAsync();
      if (result.isAvailable) await Updates.fetchUpdateAsync();
    } catch {
      // Surfaced through state.checkError / state.downloadError.
    }
  }, []);

  const restart = useCallback(() => {
    if (isEnabled) Updates.reloadAsync().catch(() => {});
  }, []);

  return { ...state, isEnabled, checkAndDownload, restart };
}
