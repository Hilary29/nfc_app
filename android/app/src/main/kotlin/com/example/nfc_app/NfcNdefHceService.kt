package com.example.nfc_app

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class NfcNdefHceService : HostApduService() {

    companion object {
        private const val TAG = "NfcNdefHceService"

        // NDEF Application AID (standard)
        private val NDEF_AID = byteArrayOf(
            0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01
        )

        // File IDs
        private val CC_FILE_ID = byteArrayOf(0xE1.toByte(), 0x03)
        private val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04)

        // Status codes
        private val SUCCESS = byteArrayOf(0x90.toByte(), 0x00)
        private val FAILED = byteArrayOf(0x6F.toByte(), 0x00)
        private val NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        private val FILE_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())

        // Static reference to communicate with Flutter
        var methodChannel: MethodChannel? = null
        var ndefPayload: ByteArray? = null
        private var selectedFileId: ByteArray? = null
        private var isAppSelected = false
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "NFC NDEF HCE Service created")
    }

    override fun onDeactivated(reason: Int) {
        val reasonText = when (reason) {
            DEACTIVATION_LINK_LOSS -> "Link lost"
            DEACTIVATION_DESELECTED -> "Deselected"
            else -> "Unknown"
        }
        Log.d(TAG, "Service deactivated: $reasonText")

        // Reset state
        isAppSelected = false
        selectedFileId = null
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null || commandApdu.size < 4) {
            Log.w(TAG, "Invalid APDU command")
            return FAILED
        }

        val cla = commandApdu[0]
        val ins = commandApdu[1]
        val p1 = commandApdu[2]
        val p2 = commandApdu[3]

        Log.d(TAG, "Received APDU - CLA: ${String.format("0x%02X", cla)}, INS: ${String.format("0x%02X", ins)}, P1: ${String.format("0x%02X", p1)}, P2: ${String.format("0x%02X", p2)}")

        return when {
            // SELECT command (CLA=00, INS=A4)
            cla.toInt() == 0x00 && ins.toInt() == 0xA4.toByte().toInt() -> {
                handleSelectCommand(commandApdu)
            }
            // READ BINARY command (CLA=00, INS=B0)
            cla.toInt() == 0x00 && ins.toInt() == 0xB0.toByte().toInt() -> {
                handleReadBinaryCommand(commandApdu)
            }
            else -> {
                Log.w(TAG, "Unknown command")
                NOT_FOUND
            }
        }
    }

    private fun handleSelectCommand(command: ByteArray): ByteArray {
        if (command.size < 5) {
            Log.w(TAG, "SELECT command too short")
            return FAILED
        }

        val p1 = command[2]
        val p2 = command[3]
        val lc = command[4].toInt() and 0xFF

        if (command.size < 5 + lc) {
            Log.w(TAG, "SELECT command invalid length")
            return FAILED
        }

        val data = command.sliceArray(5 until 5 + lc)

        return when {
            // SELECT by AID (P1=04, P2=00)
            p1.toInt() == 0x04 && p2.toInt() == 0x00 -> {
                if (data.contentEquals(NDEF_AID)) {
                    Log.d(TAG, "NDEF Application selected")
                    isAppSelected = true
                    selectedFileId = null
                    SUCCESS
                } else {
                    Log.w(TAG, "Unknown AID")
                    isAppSelected = false
                    NOT_FOUND
                }
            }
            // SELECT by File ID (P1=00, P2=0C for first occurrence)
            p1.toInt() == 0x00 && p2.toInt() == 0x0C -> {
                if (!isAppSelected) {
                    Log.w(TAG, "NDEF app not selected")
                    return FILE_NOT_FOUND
                }

                when {
                    data.contentEquals(CC_FILE_ID) -> {
                        Log.d(TAG, "Capability Container selected")
                        selectedFileId = CC_FILE_ID
                        SUCCESS
                    }
                    data.contentEquals(NDEF_FILE_ID) -> {
                        Log.d(TAG, "NDEF File selected")
                        selectedFileId = NDEF_FILE_ID
                        SUCCESS
                    }
                    else -> {
                        Log.w(TAG, "Unknown File ID")
                        FILE_NOT_FOUND
                    }
                }
            }
            else -> {
                Log.w(TAG, "Unsupported SELECT parameters")
                FAILED
            }
        }
    }

    private fun handleReadBinaryCommand(command: ByteArray): ByteArray {
        if (!isAppSelected) {
            Log.w(TAG, "NDEF app not selected for READ BINARY")
            return FILE_NOT_FOUND
        }

        val p1 = command[2].toInt() and 0xFF
        val p2 = command[3].toInt() and 0xFF
        val offset = (p1 shl 8) or p2
        val le = if (command.size > 4) command[4].toInt() and 0xFF else 256

        Log.d(TAG, "READ BINARY - Offset: $offset, Length: $le")

        return when {
            selectedFileId?.contentEquals(CC_FILE_ID) == true -> {
                // Return Capability Container
                val cc = createCapabilityContainer()
                val dataToRead = if (offset < cc.size) {
                    val endIndex = minOf(offset + le, cc.size)
                    cc.sliceArray(offset until endIndex)
                } else {
                    byteArrayOf()
                }
                Log.d(TAG, "Returning CC data: ${dataToRead.size} bytes")
                dataToRead + SUCCESS
            }
            selectedFileId?.contentEquals(NDEF_FILE_ID) == true -> {
                // Return NDEF payload
                if (ndefPayload == null) {
                    Log.w(TAG, "No NDEF payload available")
                    return FILE_NOT_FOUND + SUCCESS
                }

                val dataToRead = if (offset < ndefPayload!!.size) {
                    val endIndex = minOf(offset + le, ndefPayload!!.size)
                    ndefPayload!!.sliceArray(offset until endIndex)
                } else {
                    byteArrayOf()
                }
                Log.d(TAG, "Returning NDEF data: ${dataToRead.size} bytes from offset $offset")
                dataToRead + SUCCESS
            }
            else -> {
                Log.w(TAG, "No file selected for READ BINARY")
                FILE_NOT_FOUND
            }
        }
    }

    private fun createCapabilityContainer(): ByteArray {
        // Capability Container format:
        // Byte 0-1: CCLEN (15 bytes = 0x000F)
        // Byte 2: Mapping Version (2.0 = 0x20)
        // Byte 3-4: MLe (Maximum R-APDU data size) = 0x00FF (255 bytes)
        // Byte 5-6: MLc (Maximum C-APDU data size) = 0x00FF (255 bytes)
        // Byte 7-10: NDEF File Control TLV
        //   - Type: 0x04 (NDEF File Control)
        //   - Length: 0x06
        //   - File ID: 0xE104
        //   - Max NDEF size: 0x00FF (255 bytes, can be larger)
        //   - Read access: 0x00 (always)
        //   - Write access: 0xFF (never)

        val ndefMaxSize = 0x00FF // 255 bytes max NDEF message size

        return byteArrayOf(
            0x00, 0x0F,                    // CCLEN = 15 bytes
            0x20,                          // Mapping version 2.0
            0x00, 0xFF.toByte(),           // MLe = 255 bytes
            0x00, 0xFF.toByte(),           // MLc = 255 bytes
            0x04,                          // T: NDEF File Control TLV
            0x06,                          // L: 6 bytes
            0xE1.toByte(), 0x04,           // File ID = E104
            (ndefMaxSize shr 8).toByte(),  // Max NDEF size MSB
            (ndefMaxSize and 0xFF).toByte(), // Max NDEF size LSB
            0x00,                          // Read access: always
            0xFF.toByte()                  // Write access: never
        )
    }
}
