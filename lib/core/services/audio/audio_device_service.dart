/// Service for detecting audio device connections (headphones, Bluetooth)
abstract class AudioDeviceService {
  /// Check if headphones (wired or Bluetooth) are currently connected
  Future<bool> areHeadphonesConnected();

  /// Stream that emits true when headphones connect, false when disconnected
  Stream<bool> get headphoneConnectionStream;

  /// Dispose resources
  void dispose();
}
