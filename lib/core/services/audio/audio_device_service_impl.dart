import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'audio_device_service.dart';

/// Implementation of audio device detection using platform channels
class AudioDeviceServiceImpl implements AudioDeviceService {
  static const MethodChannel _channel = MethodChannel(
    'com.learnova.app/audio_device',
  );

  final StreamController<bool> _headphoneStreamController =
      StreamController<bool>.broadcast();

  AudioDeviceServiceImpl() {
    // Listen for headphone connection changes from platform
    _channel.setMethodCallHandler(_handleMethodCall);
    _configureAudioSession();
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
      ),
    );
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onHeadphoneConnectionChanged') {
      final bool isConnected = call.arguments as bool;
      _headphoneStreamController.add(isConnected);
    }
  }

  @override
  Future<bool> areHeadphonesConnected() async {
    try {
      final bool isConnected = await _channel.invokeMethod(
        'areHeadphonesConnected',
      );
      return isConnected;
    } on PlatformException catch (_) {
      // If platform channel fails, assume headphones not connected
      return false;
    }
  }

  @override
  Stream<bool> get headphoneConnectionStream =>
      _headphoneStreamController.stream;

  @override
  void dispose() {
    _headphoneStreamController.close();
  }
}
