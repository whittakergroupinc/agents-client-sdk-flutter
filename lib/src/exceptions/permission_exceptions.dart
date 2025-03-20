part of 'exceptions.dart';

/// Thrown when required permissions are not granted.
///
/// This can happen when:
/// - Microphone permission is denied
/// - Bluetooth permissions are denied on Android
sealed class PermissionException extends AgentException {
  const PermissionException(super.code, super.readableMessage);
}

/// Thrown when microphone permission is not granted.
final class MicrophonePermissionDenied extends PermissionException {
  const MicrophonePermissionDenied()
      : super(
          'microphone_permission_denied',
          'Microphone permission not granted',
        );
}

/// Thrown when Bluetooth permissions are denied on Android.
final class BluetoothPermissionDenied extends PermissionException {
  const BluetoothPermissionDenied()
      : super('bluetooth_permission_denied', 'Bluetooth permissions disabled');
}
