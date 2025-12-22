package com.example.nfc_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.nfc_app/hce"
    private val MERCHANT_CHANNEL = "com.example.nfc_app/merchant_hce"

    private var methodChannel: MethodChannel? = null
    private var merchantChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Client HCE Channel (ancien)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        NfcHostApduService.methodChannel = methodChannel

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendResponse" -> {
                    try {
                        val approved = call.argument<Boolean>("approved") ?: false
                        val responseJson = call.argument<String>("responseJson") ?: ""

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

        // Merchant HCE NDEF Channel (nouveau)
        merchantChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MERCHANT_CHANNEL)
        NfcNdefHceService.methodChannel = merchantChannel

        merchantChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setNdefPayload" -> {
                    try {
                        val payload = call.argument<String>("payload") ?: ""
                        NfcNdefHceService.ndefPayload = jsonToNdefTlv(payload)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to set NDEF payload: ${e.message}", null)
                    }
                }
                "clearNdefPayload" -> {
                    try {
                        NfcNdefHceService.ndefPayload = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to clear NDEF payload: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun jsonToNdefTlv(jsonStr: String): ByteArray {
        // Convert JSON string to NDEF TLV format
        val textBytes = jsonStr.toByteArray(Charsets.UTF_8)
        val languageCode = "en".toByteArray(Charsets.UTF_8)
        val statusByte = languageCode.size.toByte() // 0x02 for "en"

        // Text Record payload: [status] [language] [text]
        val payload = byteArrayOf(statusByte) + languageCode + textBytes

        // NDEF Record: [flags] [type length] [payload length] [type] [payload]
        val flags = 0xD1.toByte() // MB=1, ME=1, SR=1, TNF=0x01
        val typeLength = 0x01.toByte()
        val payloadLength = payload.size.toByte()
        val type = byteArrayOf(0x54) // "T"

        val ndefMessage = byteArrayOf(flags, typeLength, payloadLength) + type + payload

        // TLV: [0x03] [length MSB] [length LSB] [message] [0xFE]
        val lengthMsb = (ndefMessage.size shr 8).toByte()
        val lengthLsb = (ndefMessage.size and 0xFF).toByte()

        return byteArrayOf(0x03, lengthMsb, lengthLsb) + ndefMessage + byteArrayOf(0xFE.toByte())
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        merchantChannel?.setMethodCallHandler(null)
        NfcHostApduService.methodChannel = null
        NfcNdefHceService.methodChannel = null
        super.onDestroy()
    }
}
