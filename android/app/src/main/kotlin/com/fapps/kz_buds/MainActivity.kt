package com.fapps.kz_buds

import android.annotation.SuppressLint
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var audioLinkReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "kz_buds/bluetooth")
            .setMethodCallHandler { call, result ->
                if (call.method == "connectedAudioDevices") {
                    connectedAudioDevices(result)
                } else {
                    result.notImplemented()
                }
            }
        EventChannel(messenger, "kz_buds/bluetooth/audio_link")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    watchAudioLink(events)
                }

                override fun onCancel(arguments: Any?) {
                    stopWatchingAudioLink()
                }
            })
    }

    override fun onDestroy() {
        stopWatchingAudioLink()
        super.onDestroy()
    }

    // Signals every audio connection change and Bluetooth on/off. It carries
    // no data: the listener asks for the connected devices again.
    private fun watchAudioLink(events: EventChannel.EventSink) {
        stopWatchingAudioLink()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                events.success(null)
            }
        }
        val filter = IntentFilter().apply {
            addAction(BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED)
            addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Exported on purpose: the Bluetooth stack broadcasts from its own
            // UID, which a non-exported receiver never hears. These are
            // protected system broadcasts, so other apps cannot send them.
            applicationContext.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            applicationContext.registerReceiver(receiver, filter)
        }
        audioLinkReceiver = receiver
    }

    private fun stopWatchingAudioLink() {
        audioLinkReceiver?.let { applicationContext.unregisterReceiver(it) }
        audioLinkReceiver = null
    }

    // Addresses with A2DP or HFP up. BluetoothDevice.isConnected() is a hidden
    // API, so this reads the public profile proxies instead. Replies with an
    // error rather than an empty list when a profile could not be read: empty
    // means "nothing connected" to the caller.
    @SuppressLint("MissingPermission")
    private fun connectedAudioDevices(result: MethodChannel.Result) {
        val adapter = getSystemService(BluetoothManager::class.java)?.adapter
        if (adapter == null) {
            result.error("unavailable", "No Bluetooth adapter", null)
            return
        }
        val profiles = listOf(BluetoothProfile.A2DP, BluetoothProfile.HEADSET)
        val addresses = LinkedHashSet<String>()
        var pending = profiles.size
        var failed = false
        var replied = false

        fun done() {
            pending -= 1
            if (pending > 0 || replied) return
            replied = true
            if (failed && addresses.isEmpty()) {
                result.error("unavailable", "Bluetooth profiles did not answer", null)
            } else {
                result.success(addresses.toList())
            }
        }

        for (profile in profiles) {
            val listener = object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    try {
                        proxy.connectedDevices.forEach { addresses.add(it.address) }
                    } catch (e: SecurityException) {
                        failed = true
                    }
                    adapter.closeProfileProxy(profile, proxy)
                    done()
                }

                override fun onServiceDisconnected(profile: Int) {}
            }
            val bound = try {
                adapter.getProfileProxy(applicationContext, listener, profile)
            } catch (e: SecurityException) {
                false
            }
            if (!bound) {
                failed = true
                done()
            }
        }
    }
}
