import { Alert, Platform } from 'react-native';

/** Asks before a destructive action. react-native-web's Alert is a no-op, so web uses window.confirm. */
export function confirmDestructive(
  title: string,
  message: string,
  labels: { cancel: string; confirm: string },
  onConfirm: () => void,
) {
  if (Platform.OS === 'web') {
    if (window.confirm(`${title}\n\n${message}`)) onConfirm();
    return;
  }
  Alert.alert(title, message, [
    { text: labels.cancel, style: 'cancel' },
    { text: labels.confirm, style: 'destructive', onPress: onConfirm },
  ]);
}

export function showMessage(title: string, message?: string) {
  if (Platform.OS === 'web') window.alert(message ? `${title}\n\n${message}` : title);
  else Alert.alert(title, message);
}
