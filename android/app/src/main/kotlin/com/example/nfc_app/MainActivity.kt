package com.example.nfc_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.nfc_app/hce"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Set the channel reference for the HCE service
        NfcHostApduService.methodChannel = methodChannel

        // Handle calls from Flutter
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendResponse" -> {
                    try {
                        val approved = call.argument<Boolean>("approved") ?: false
                        val responseJson = call.argument<String>("responseJson") ?: ""

                        // This will be called by the static instance
                        // We need to find the service instance
                        // For now, we'll use a static reference
                        NfcHostApduService.pendingResponse = if (approved) {
                            val bytes = responseJson.toByteArray(Charsets.UTF_8)
                            bytes + byteArrayOf(0x90.toByte(), 0x00)
                        } else {
                            responseJson.toByteArray(Charsets.UTF_8) + byteArrayOf(0x90.toByte(), 0x00)
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to send response: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        NfcHostApduService.methodChannel = null
        super.onDestroy()
    }
}
