package com.example.learnova

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.learnova.app/audio_device"
    private var methodChannel: MethodChannel? = null
    private var headphoneReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "areHeadphonesConnected" -> {
                    val isConnected = checkHeadphonesConnected()
                    result.success(isConnected)
                }
                else -> result.notImplemented()
            }
        }

        // Register broadcast receiver for headphone connection changes
        registerHeadphoneReceiver()
    }

    private fun checkHeadphonesConnected(): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6.0+ (API 23+)
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            devices.any { device ->
                device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
            }
        } else {
            // Fallback for older Android versions
            audioManager.isWiredHeadsetOn || audioManager.isBluetoothA2dpOn
        }
    }

    private fun registerHeadphoneReceiver() {
        headphoneReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_HEADSET_PLUG -> {
                        val state = intent.getIntExtra("state", -1)
                        val isConnected = state == 1
                        methodChannel?.invokeMethod(
                            "onHeadphoneConnectionChanged",
                            isConnected
                        )
                    }
                    AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED,
                    BluetoothDevice.ACTION_ACL_CONNECTED,
                    BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                        val isConnected = checkHeadphonesConnected()
                        methodChannel?.invokeMethod(
                            "onHeadphoneConnectionChanged",
                            isConnected
                        )
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_HEADSET_PLUG)
            addAction(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
        }

        registerReceiver(headphoneReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        headphoneReceiver?.let {
            unregisterReceiver(it)
        }
    }
}
