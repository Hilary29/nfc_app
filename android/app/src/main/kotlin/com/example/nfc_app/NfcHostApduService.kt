package com.example.nfc_app

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets

class NfcHostApduService : HostApduService() {

    companion object {
        private const val TAG = "NfcHostApduService"

        // AID must match apduservice.xml
        private val AID = byteArrayOf(
            0xF0.toByte(), 0x01, 0x02, 0x03, 0x04, 0x05, 0x06
        )

        // Status codes
        private val SUCCESS = byteArrayOf(0x90.toByte(), 0x00)
        private val FAILED = byteArrayOf(0x6F.toByte(), 0x00)
        private val NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())

        // Static reference to communicate with Flutter
        var methodChannel: MethodChannel? = null
        var pendingResponse: ByteArray? = null
        private var isWaitingForResponse = false
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "NFC HCE Service created")
    }

    override fun onDeactivated(reason: Int) {
        val reasonText = when (reason) {
            DEACTIVATION_LINK_LOSS -> "Link lost"
            DEACTIVATION_DESELECTED -> "Deselected"
            else -> "Unknown"
        }
        Log.d(TAG, "Service deactivated: $reasonText")
        isWaitingForResponse = false
        pendingResponse = null

        // Notify Flutter
        methodChannel?.invokeMethod("onDeactivated", mapOf("reason" to reasonText))
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null || commandApdu.size < 4) {
            Log.w(TAG, "Invalid APDU command")
            return FAILED
        }

        val cla = commandApdu[0]
        val ins = commandApdu[1]

        Log.d(TAG, "Received APDU - CLA: ${String.format("0x%02X", cla)}, INS: ${String.format("0x%02X", ins)}")

        return when {
            // SELECT command (CLA=00, INS=A4)
            cla.toInt() == 0x00 && ins.toInt() == 0xA4.toByte().toInt() -> {
                handleSelectCommand(commandApdu)
            }
            // PAYMENT command (CLA=80, INS=01)
            cla.toInt() == 0x80.toByte().toInt() && ins.toInt() == 0x01 -> {
                handlePaymentCommand(commandApdu)
            }
            else -> {
                Log.w(TAG, "Unknown command")
                NOT_FOUND
            }
        }
    }

    private fun handleSelectCommand(command: ByteArray): ByteArray {
        Log.d(TAG, "Processing SELECT command")

        // Verify AID if present in command
        if (command.size >= 12) {
            val receivedAid = command.sliceArray(5..11)
            if (receivedAid.contentEquals(AID)) {
                Log.d(TAG, "AID matched - App selected")

                // Notify Flutter that merchant device detected
                methodChannel?.invokeMethod("onMerchantDetected", null)

                return SUCCESS
            } else {
                Log.w(TAG, "AID mismatch")
                return NOT_FOUND
            }
        }

        return FAILED
    }

    private fun handlePaymentCommand(command: ByteArray): ByteArray {
        Log.d(TAG, "Processing PAYMENT command")

        if (command.size < 5) {
            Log.w(TAG, "Payment command too short")
            return FAILED
        }

        try {
            // Extract data length and payload
            val lc = command[4].toInt() and 0xFF
            if (command.size < 5 + lc) {
                Log.w(TAG, "Invalid payload length")
                return FAILED
            }

            val data = command.sliceArray(5 until 5 + lc)
            val jsonStr = String(data, StandardCharsets.UTF_8)

            Log.d(TAG, "Payment request received: $jsonStr")

            // Send to Flutter for user approval
            isWaitingForResponse = true
            pendingResponse = null

            methodChannel?.invokeMethod("onPaymentRequest", mapOf("data" to jsonStr))

            // Wait for Flutter response (with timeout)
            var waitTime = 0
            val timeout = 30000 // 30 seconds
            val checkInterval = 100L // 100ms

            while (isWaitingForResponse && waitTime < timeout) {
                Thread.sleep(checkInterval)
                waitTime += checkInterval.toInt()

                if (pendingResponse != null) {
                    break
                }
            }

            return if (pendingResponse != null) {
                Log.d(TAG, "Sending payment response to merchant")
                val response = pendingResponse!!
                pendingResponse = null
                isWaitingForResponse = false
                response
            } else {
                Log.w(TAG, "Response timeout or no response")
                isWaitingForResponse = false
                FAILED
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error processing payment command", e)
            isWaitingForResponse = false
            return FAILED
        }
    }

    // Called from Flutter to send response
    fun sendResponse(approved: Boolean, responseJson: String) {
        try {
            val responseBytes = responseJson.toByteArray(StandardCharsets.UTF_8)
            val apduResponse = responseBytes + SUCCESS

            pendingResponse = apduResponse
            isWaitingForResponse = false

            Log.d(TAG, "Response prepared: approved=$approved, json=$responseJson")
        } catch (e: Exception) {
            Log.e(TAG, "Error preparing response", e)
            pendingResponse = FAILED
            isWaitingForResponse = false
        }
    }
}
