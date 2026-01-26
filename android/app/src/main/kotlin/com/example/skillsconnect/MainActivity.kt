//package com.skillsconnect.app
//
//import android.annotation.SuppressLint
//import android.content.Intent
//import android.media.AudioManager
//import android.bluetooth.BluetoothAdapter
//import android.bluetooth.BluetoothProfile
//import android.os.Bundle
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//import android.util.Log
//import org.json.JSONObject
//
//class MainActivity : FlutterActivity() {
//
//    private val ROUTE_CHANNEL = "app.audio.route"
//    private val BG_CHANNEL    = "app.channel.move_to_background"
//
//    private fun L(tag: String, msg: String) = Log.d(tag, msg)
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        L("PJOIN", "onCreate() intent=$intent")
//        persistPendingJoinFromIntent(intent)
//    }
//
//    override fun onNewIntent(intent: Intent) {
//        super.onNewIntent(intent)
//        setIntent(intent)
//        L("PJOIN", "onNewIntent() intent=$intent")
//        persistPendingJoinFromIntent(intent)
//    }
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BG_CHANNEL)
//            .setMethodCallHandler { call, result ->
//                when (call.method) {
//                    "moveToBackground" -> {
//                        moveTaskToBack(true)
//                        result.success(true)
//                    }
//                    else -> result.notImplemented()
//                }
//            }
//
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ROUTE_CHANNEL)
//            .setMethodCallHandler { call, result ->
//                val am = getSystemService(AUDIO_SERVICE) as AudioManager
//                try {
//                    when (call.method) {
//                        "isBtAvailable" -> result.success(isBluetoothAvailable(am))
//
//                        // 🔹 NEW: report current route to Flutter
//                        "currentRoute" -> {
//                            result.success(getCurrentRoute(am))   // "bluetooth" | "speaker" | "earpiece"
//                        }
//
//                        "toBluetooth" -> {
//                            ensureCommModeAndFocus(am)
//                            am.isSpeakerphoneOn = false
//                            try { am.stopBluetoothSco() } catch (_: Exception) {}
//                            try {
//                                am.startBluetoothSco()
//                                am.isBluetoothScoOn = true         // <- important on many devices
//                            } catch (_: Exception) {}
//                            result.success(true)
//                        }
//
//                        "toSpeaker" -> {
//                            ensureCommModeAndFocus(am)
//                            try { am.stopBluetoothSco() } catch (_: Exception) {}
//                            am.isBluetoothScoOn = false
//                            am.isSpeakerphoneOn = true
//                            result.success(true)
//                        }
//
//                        "toEarpiece" -> {
//                            ensureCommModeAndFocus(am)
//                            try { am.stopBluetoothSco() } catch (_: Exception) {}
//                            am.isBluetoothScoOn = false
//                            am.isSpeakerphoneOn = false
//                            result.success(true)
//                        }
//
//                        else -> result.notImplemented()
//                    }
//                } catch (e: Exception) {
//                    result.error("AUDIO_ROUTE_ERR", e.message, null)
//                }
//            }
//    }
//
//
//
//    private fun ensureCommModeAndFocus(am: AudioManager) {
//        try {
//            @Suppress("DEPRECATION")
//            am.requestAudioFocus(null, AudioManager.STREAM_VOICE_CALL, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
//        } catch (_: Exception) {}
//        am.mode = AudioManager.MODE_IN_COMMUNICATION
//    }
//
//    @SuppressLint("MissingPermission")
//    private fun getCurrentRoute(am: AudioManager): String {
//        return try {
//            // अगर speaker on है -> speaker
//            if (am.isSpeakerphoneOn) return "speaker"
//
//            // अगर SCO active या BT connected है -> bluetooth
//            val bt = BluetoothAdapter.getDefaultAdapter()
//            val isBtConn =
//                (bt != null && bt.isEnabled &&
//                        (bt.getProfileConnectionState(BluetoothProfile.HEADSET) == BluetoothProfile.STATE_CONNECTED ||
//                                bt.getProfileConnectionState(BluetoothProfile.A2DP) == BluetoothProfile.STATE_CONNECTED)) ||
//                        am.isBluetoothScoOn
//
//            if (isBtConn) "bluetooth" else "earpiece"
//        } catch (_: Exception) {
//            "earpiece"
//        }
//    }
//
//
//    @SuppressLint("MissingPermission")
//    private fun isBluetoothAvailable(am: AudioManager): Boolean {
//        return try {
//            val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
//            if (!adapter.isEnabled) return false
//            val h = adapter.getProfileConnectionState(BluetoothProfile.HEADSET)
//            val a = adapter.getProfileConnectionState(BluetoothProfile.A2DP)
//            (h == BluetoothProfile.STATE_CONNECTED) ||
//                    (a == BluetoothProfile.STATE_CONNECTED) ||
//                    am.isBluetoothScoOn
//        } catch (_: Exception) { false }
//    }
//
//    /** --------- MOST IMPORTANT: normalize CallKit extras and persist --------- */
//    private fun persistPendingJoinFromIntent(intent: Intent?) {
//        try {
//            if (intent == null) { android.util.Log.d("PJOIN","persist: intent=null"); return }
//            val extras = intent.extras ?: run {
//                android.util.Log.d("PJOIN","persist: extras=null"); return
//            }
//            android.util.Log.d("PJOIN", "persist: keys=${extras.keySet()}")
//
//            fun firstNonBlank(vararg items: Any?): String? {
//                for (it in items) {
//                    val s = (it ?: "").toString().trim()
//                    if (s.isNotEmpty() && s.lowercase() != "null") return s
//                }
//                return null
//            }
//            fun bundleToMap(b: android.os.Bundle): Map<String, Any?> {
//                val r = mutableMapOf<String, Any?>()
//                for (k in b.keySet()) r[k] = b.get(k)
//                return r
//            }
//            fun jsonToMap(obj: org.json.JSONObject): Map<String, Any?> {
//                val map = mutableMapOf<String, Any?>()
//                val it = obj.keys()
//                while (it.hasNext()) {
//                    val k = it.next()
//                    val v = obj.opt(k)
//                    map[k] = when (v) {
//                        is org.json.JSONObject -> jsonToMap(v)
//                        is org.json.JSONArray -> {
//                            val list = mutableListOf<Any?>()
//                            for (i in 0 until v.length()) {
//                                val e = v.opt(i)
//                                list.add(if (e is org.json.JSONObject) jsonToMap(e) else e)
//                            }
//                            list
//                        }
//                        else -> v
//                    }
//                }
//                return map
//            }
//
//            var callData: MutableMap<String, Any?>? = null
//
//            // A) common bundle/string under EXTRA_CALLKIT_CALL_DATA
//            (extras.get("EXTRA_CALLKIT_CALL_DATA") as? android.os.Bundle)?.let {
//                callData = bundleToMap(it).toMutableMap()
//            }
//            if (callData == null) {
//                extras.getString("EXTRA_CALLKIT_CALL_DATA")?.let { s ->
//                    try { callData = jsonToMap(org.json.JSONObject(s)).toMutableMap() } catch (_: Exception) {}
//                }
//            }
//
//            // B) flat keys
//            if (callData == null) {
//                val m = mutableMapOf<String, Any?>()
//                fun putIf(k: String) { if (extras.containsKey(k)) m[k] = extras.get(k) }
//                arrayOf(
//                    "EXTRA_CALLKIT_ID",
//                    "EXTRA_CALLKIT_NAME_CALLER",
//                    "EXTRA_CALLKIT_HANDLE",
//                    "EXTRA_CALLKIT_TYPE",
//                    "EXTRA_CALLKIT_IS_VIDEO",
//                    "EXTRA_CALLKIT_DURATION",
//                    "id","nameCaller","handle" // plugin kabhi in naamon se bhi bhejta
//                ).forEach(::putIf)
//
//                val ex = extras.get("EXTRA_CALLKIT_EXTRA")
//                when (ex) {
//                    is android.os.Bundle -> m["extra"] = bundleToMap(ex)
//                    is String -> try { m["extra"] = jsonToMap(org.json.JSONObject(ex)) } catch (_: Exception) {}
//                }
//                if (m.isNotEmpty()) callData = m
//            }
//
//            // C) worst-case: full extras dump
//            if (callData == null) callData = bundleToMap(extras).toMutableMap()
//
//            // ---- normalize ----
//            val normalized = mutableMapOf<String, Any?>()
//
//            // merge nested 'extra' first (taa ki callerId/receiverId agar aaye to retain ho)
//            val extraAny = callData!!["extra"]
//            if (extraAny is Map<*, *>) {
//                for ((k, v) in extraAny) if (k is String) normalized[k] = v
//            } else if (extraAny is String) {
//                try {
//                    val jo = org.json.JSONObject(extraAny)
//                    for (k in jo.keys()) normalized[k] = jo.get(k)
//                } catch (_: Exception) {}
//            }
//
//            // id/channel
//            val id = firstNonBlank(
//                callData!!["id"],
//                callData!!["EXTRA_CALLKIT_ID"],
//                callData!!["callId"],
//                callData!!["channel"]
//            ) ?: ""
//            if (id.isNotEmpty()) {
//                normalized["callId"] = id
//                if (firstNonBlank(normalized["channel"]).isNullOrBlank()) normalized["channel"] = id
//            }
//
//            // receiverId from Flutter prefs (critical)
//            val sp = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
//            val selfId = sp.getString("flutter.user_id", null)
//            if (!selfId.isNullOrBlank() && firstNonBlank(normalized["receiverId"]).isNullOrBlank()) {
//                normalized["receiverId"] = selfId
//            }
//
//            // callerName fallback
//            val callerName = firstNonBlank(
//                normalized["callerName"],
//                callData!!["EXTRA_CALLKIT_NAME_CALLER"],
//                callData!!["nameCaller"],
//                callData!!["name"]
//            )
//            if (!callerName.isNullOrBlank()) normalized["callerName"] = callerName
//
//            // callerId resolution
//            var callerId = firstNonBlank(
//                normalized["callerId"],
//                callData!!["callerId"],
//                callData!!["EXTRA_CALLKIT_HANDLE"],
//                callData!!["handle"],
//                callData!!["fromUserId"],
//                callData!!["from"],
//                callData!!["userId"],
//                callData!!["uid"],
//                callData!!["number"],
//                callData!!["phoneNumber"]
//            )
//
//            // 🔥 last-resort: pick from last saved Dart extras if plugin stripped it
//            if (callerId.isNullOrBlank()) {
//                val last = sp.getString("flutter.last_callkit_extra", null)
//                if (!last.isNullOrBlank()) {
//                    try {
//                        val jo = org.json.JSONObject(last)
//                        val lastCaller = jo.optString("callerId", "")
//                        if (lastCaller.isNotBlank()) callerId = lastCaller
//                        // also merge channel/receiverId if missing
//                        if (firstNonBlank(normalized["channel"]).isNullOrBlank()) {
//                            val ch = jo.optString("channel", "")
//                            if (ch.isNotBlank()) normalized["channel"] = ch
//                        }
//                        if (firstNonBlank(normalized["receiverId"]).isNullOrBlank()) {
//                            val rid = jo.optString("receiverId", "")
//                            if (rid.isNotBlank()) normalized["receiverId"] = rid
//                        }
//                        if (firstNonBlank(normalized["callerName"]).isNullOrBlank()) {
//                            val cn = jo.optString("callerName", "")
//                            if (cn.isNotBlank()) normalized["callerName"] = cn
//                        }
//                    } catch (_: Exception) {}
//                }
//            }
//
//            if (!callerId.isNullOrBlank()) normalized["callerId"] = callerId!!.trim()
//
//            // channel fallback
//            if ((firstNonBlank(normalized["channel"]) ?: "").isBlank() && id.isNotEmpty()) {
//                normalized["channel"] = id
//            }
//
//            val finalJson = org.json.JSONObject(normalized as Map<*, *>).toString()
//            val ok = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
//                .edit()
//                .putString("flutter.pending_join", finalJson)
//                .commit()
//
//            android.util.Log.d("PJOIN", "persist: saved=$ok json=$finalJson")
//        } catch (e: Exception) {
//            android.util.Log.e("PJOIN", "persist: error=${e.message}", e)
//        }
//    }
//
//    private fun bundleToMap(bundle: Bundle): Map<String, Any?> {
//        val r = mutableMapOf<String, Any?>()
//        for (key in bundle.keySet()) {
//            val v = bundle.get(key)
//            r[key] = when (v) {
//                is Bundle -> bundleToMap(v)
//                else -> v
//            }
//        }
//        return r
//    }
//
//    private fun jsonToMap(jo: JSONObject): Map<String, Any?> {
//        val r = mutableMapOf<String, Any?>()
//        val it = jo.keys()
//        while (it.hasNext()) {
//            val k = it.next()
//            val v = jo.get(k)
//            r[k] = when (v) {
//                is JSONObject -> jsonToMap(v)
//                else -> v
//            }
//        }
//        return r
//    }
//}















package com.skillsconnect.app

import android.annotation.SuppressLint
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothProfile
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import android.provider.Settings
import android.content.Context
import androidx.core.app.NotificationCompat

import java.io.File
import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.provider.DocumentsContract
import androidx.core.content.FileProvider
import android.app.PendingIntent
import android.database.Cursor
import android.net.Uri


class MainActivity : FlutterActivity() {

    private val ROUTE_CHANNEL = "app.audio.route"
    private val BG_CHANNEL    = "app.channel.move_to_background"

    private val DEV_CH = "app.security.devoptions"
    private val NOTIFY_CH  = "skillsconnect/notify"



    private fun L(tag: String, msg: String) = Log.d(tag, msg)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        L("PJOIN", "onCreate() intent=$intent")
        persistPendingJoinFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        L("PJOIN", "onNewIntent() intent=$intent")
        persistPendingJoinFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Developer option disable code

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEV_CH)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDevOptionsEnabled" -> {
                        result.success(isDevOptionsOn())
                    }
                    "openDevOptions" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            result.success(true)
                        } catch (e: Exception) {
                            // fallback: settings main
                            try {
                                startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            } catch (_: Exception) {}
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }


        // ---- Native “open directly on tap” download notification ----
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFY_CH)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showFileOpenNotification" -> {
                        val name = call.argument<String>("name") ?: "file"
                        val absPath = call.argument<String>("path") ?: ""
                        val mime = call.argument<String>("mime") ?: "application/octet-stream"
                        try {
                            showFileOpenNotification(name, absPath, mime)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }




        // Move app to background
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "moveToBackground" -> {
                        moveTaskToBack(true)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // --------- AUDIO ROUTING (Bluetooth / Speaker / Earpiece) ---------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ROUTE_CHANNEL)
            .setMethodCallHandler { call, result ->
                val am = getSystemService(AUDIO_SERVICE) as AudioManager
                try {
                    when (call.method) {
                        "isBtAvailable" -> result.success(isBluetoothAvailable(am))
                        "currentRoute"  -> result.success(getCurrentRoute(am)) // "bluetooth" | "speaker" | "earpiece"

                        "toBluetooth" -> {
                            ensureCommModeAndFocus(am)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                // Prefer HFP (SCO) device if present
                                val dev = am.availableCommunicationDevices.firstOrNull {
                                    it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                                            it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP
                                }
                                // clear existing route if stuck
                                try { am.clearCommunicationDevice() } catch (_: Exception) {}
                                dev?.let { am.setCommunicationDevice(it) }
                            } else {
                                try { am.stopBluetoothSco() } catch (_: Exception) {}
                                am.isSpeakerphoneOn = false
                                try { am.startBluetoothSco() } catch (_: Exception) {}
                                try { @Suppress("DEPRECATION") am.isBluetoothScoOn = true } catch (_: Exception) {}
                            }
                            result.success(true)
                        }

                        "toSpeaker" -> {
                            ensureCommModeAndFocus(am)

                            // (तुम्हारा मौजूदा exact code ज्यों का त्यों)
                            try { am.stopBluetoothSco() } catch (_: Exception) {}
                            try { @Suppress("DEPRECATION") am.isBluetoothScoOn = false } catch (_: Exception) {}
                            try { am.clearCommunicationDevice() } catch (_: Exception) {}
                            try {
                                am.mode = AudioManager.MODE_NORMAL
                                am.isSpeakerphoneOn = false
                                am.mode = AudioManager.MODE_IN_COMMUNICATION
                            } catch (_: Exception) {}

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                val sp = am.availableCommunicationDevices.firstOrNull {
                                    it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
                                }
                                val ok = try { sp != null && am.setCommunicationDevice(sp) } catch (_: Exception) { false }
                                if (!ok) {
                                    try { am.stopBluetoothSco() } catch (_: Exception) {}
                                    try { @Suppress("DEPRECATION") am.isBluetoothScoOn = false } catch (_: Exception) {}
                                    am.isSpeakerphoneOn = true
                                } else {
                                    am.isSpeakerphoneOn = true
                                }
                            } else {
                                try { am.stopBluetoothSco() } catch (_: Exception) {}
                                try { @Suppress("DEPRECATION") am.isBluetoothScoOn = false } catch (_: Exception) {}
                                am.isSpeakerphoneOn = true
                            }

                            // 🔴 NEW: 3.5s तक speaker पर sticky रखो
                            stickTo(am, AudioDeviceInfo.TYPE_BUILTIN_SPEAKER, 3500)

                            result.success(true)
                        }

                        "toEarpiece" -> {
                            ensureCommModeAndFocus(am)

                            // (तुम्हारा मौजूदा exact code ज्यों का त्यों)
                            try { am.stopBluetoothSco() } catch (_: Exception) {}
                            try { @Suppress("DEPRECATION") am.isBluetoothScoOn = false } catch (_: Exception) {}
                            try { am.clearCommunicationDevice() } catch (_: Exception) {}
                            try {
                                am.mode = AudioManager.MODE_NORMAL
                                am.isSpeakerphoneOn = false
                                am.mode = AudioManager.MODE_IN_COMMUNICATION
                            } catch (_: Exception) {}

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                val ep = am.availableCommunicationDevices.firstOrNull {
                                    it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE
                                }
                                val ok = try { ep != null && am.setCommunicationDevice(ep) } catch (_: Exception) { false }

                                if (!ok) {
                                    try { am.clearCommunicationDevice() } catch (_: Exception) {}
                                }
                                am.isSpeakerphoneOn = false
                            } else {
                                try { am.stopBluetoothSco() } catch (_: Exception) {}
                                try { @Suppress("DEPRECATION") am.isBluetoothScoOn = false } catch (_: Exception) {}
                                am.isSpeakerphoneOn = false
                            }

                            // 🔴 NEW: 3.5s तक earpiece पर sticky रखो
                            stickTo(am, AudioDeviceInfo.TYPE_BUILTIN_EARPIECE, 3500)

                            result.success(true)
                        }



                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("AUDIO_ROUTE_ERR", e.message, null)
                }
            }
    }


    /// Developer option code

    private fun isDevOptionsOn(): Boolean {
        val cr = contentResolver
        // 1) Developer options master toggle (hidden key but readable)
        val devEnabled = try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR1) {
                Settings.Global.getInt(cr, "development_settings_enabled", 0) == 1
            } else {
                @Suppress("DEPRECATION")
                Settings.Secure.getInt(cr, "development_settings_enabled", 0) == 1
            }
        } catch (_: Exception) { false }

        // 2) USB debugging (often a good proxy even if OEM hides the master toggle)
        val adbEnabled = try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR1) {
                Settings.Global.getInt(cr, Settings.Global.ADB_ENABLED, 0) == 1
            } else {
                @Suppress("DEPRECATION")
                Settings.Secure.getInt(cr, Settings.Secure.ADB_ENABLED, 0) == 1
            }
        } catch (_: Exception) { false }

        return devEnabled || adbEnabled
    }


    // ---- helpers for audio routing ----
// ---- Sticky route enforcement (3.5s) ----
    private var stickyHandler: android.os.Handler? = null
    private var stickyUntil: Long = 0

    private fun stickTo(am: AudioManager, targetType: Int, durationMs: Long = 3500) {
        if (stickyHandler == null) stickyHandler = android.os.Handler(mainLooper)
        stickyUntil = System.currentTimeMillis() + durationMs
        stickyHandler?.removeCallbacksAndMessages(null)

        val task = object : Runnable {
            override fun run() {
                if (System.currentTimeMillis() > stickyUntil) {
                    stickyHandler?.removeCallbacks(this)
                    return
                }
                val curType = try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        am.communicationDevice?.type
                    } else {
                        when {
                            @Suppress("DEPRECATION") am.isBluetoothScoOn -> AudioDeviceInfo.TYPE_BLUETOOTH_SCO
                            am.isSpeakerphoneOn -> AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
                            else -> AudioDeviceInfo.TYPE_BUILTIN_EARPIECE
                        }
                    }
                } catch (_: Exception) { null }

                if (curType != targetType) {
                    when (targetType) {
                        AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> {
                            try { am.stopBluetoothSco() } catch (_: Exception) {}
                            try { @Suppress("DEPRECATION") am.isBluetoothScoOn = false } catch (_: Exception) {}
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                val sp = am.availableCommunicationDevices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                                sp?.let { try { am.setCommunicationDevice(it) } catch (_: Exception) {} }
                            }
                            am.isSpeakerphoneOn = true
                        }
                        AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> {
                            try { am.stopBluetoothSco() } catch (_: Exception) {}
                            try { @Suppress("DEPRECATION") am.isBluetoothScoOn = false } catch (_: Exception) {}
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                val ep = am.availableCommunicationDevices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
                                if (ep != null) {
                                    try { am.setCommunicationDevice(ep) } catch (_: Exception) {}
                                } else {
                                    try { am.clearCommunicationDevice() } catch (_: Exception) {}
                                }
                            } else {
                                am.isSpeakerphoneOn = false
                            }
                        }
                        AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> {
                            am.isSpeakerphoneOn = false
                            try { am.startBluetoothSco() } catch (_: Exception) {}
                            try { @Suppress("DEPRECATION") am.isBluetoothScoOn = true } catch (_: Exception) {}
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                val bt = am.availableCommunicationDevices.firstOrNull {
                                    it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO || it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP
                                }
                                bt?.let { try { am.setCommunicationDevice(it) } catch (_: Exception) {} }
                            }
                        }
                    }
                }
                stickyHandler?.postDelayed(this, 200)
            }
        }
        stickyHandler?.post(task)
    }



    private fun breakSco(am: AudioManager) {
        // Aggressive way to get out of BT SCO on stubborn devices
        try { am.stopBluetoothSco() } catch (_: Exception) {}
        try { @Suppress("DEPRECATION") am.isBluetoothScoOn = false } catch (_: Exception) {}

        // some vendors need a short mode toggle to fully drop HFP
        try {
            am.mode = AudioManager.MODE_NORMAL
            am.isSpeakerphoneOn = false
            Thread.sleep(120)
            am.mode = AudioManager.MODE_IN_COMMUNICATION
        } catch (_: Exception) {}
    }

    /** try setCommunicationDevice(type). if fails, return false */
    private fun setCommDeviceWithFallback(am: AudioManager, type: Int): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val dev = am.availableCommunicationDevices.firstOrNull { it.type == type }
                if (dev != null) {
                    // clear any sticky device first
                    try { am.clearCommunicationDevice() } catch (_: Exception) {}
                    if (am.setCommunicationDevice(dev)) return true
                }
            } catch (_: Exception) {}
        }
        return false
    }


    private fun ensureCommModeAndFocus(am: AudioManager) {
        try {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(null, AudioManager.STREAM_VOICE_CALL, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        } catch (_: Exception) {}
        am.mode = AudioManager.MODE_IN_COMMUNICATION
    }

    private fun getCurrentRoute(am: AudioManager): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                when (am.communicationDevice?.type) {
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "bluetooth"
                    AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
                    else -> "earpiece"
                }
            } else {
                when {
                    am.isSpeakerphoneOn -> "speaker"
                    am.isBluetoothScoOn -> "bluetooth"
                    else -> "earpiece"
                }
            }
        } catch (_: Exception) {
            "earpiece"
        }
    }

    private fun isBluetoothAvailable(am: AudioManager): Boolean {
        // Modern way (no special permission): check output devices list
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val outs = try { am.getDevices(AudioManager.GET_DEVICES_OUTPUTS) } catch (_: Exception) { emptyArray() }
            if (outs.any {
                    it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                            it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP
                }) return true
        }
        // Fallback (needs BLUETOOTH_CONNECT on Android 12+)
        return try {
            val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
            if (!adapter.isEnabled) return false
            val h = adapter.getProfileConnectionState(BluetoothProfile.HEADSET)
            val a = adapter.getProfileConnectionState(BluetoothProfile.A2DP)
            (h == BluetoothProfile.STATE_CONNECTED) ||
                    (a == BluetoothProfile.STATE_CONNECTED) ||
                    am.isBluetoothScoOn
        } catch (_: SecurityException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    /** --------- CallKit extras persist (UNCHANGED) --------- */
    private fun persistPendingJoinFromIntent(intent: Intent?) {
        try {
            if (intent == null) { android.util.Log.d("PJOIN","persist: intent=null"); return }
            val extras = intent.extras ?: run {
                android.util.Log.d("PJOIN","persist: extras=null"); return
            }
            android.util.Log.d("PJOIN", "persist: keys=${extras.keySet()}")

            fun firstNonBlank(vararg items: Any?): String? {
                for (it in items) {
                    val s = (it ?: "").toString().trim()
                    if (s.isNotEmpty() && s.lowercase() != "null") return s
                }
                return null
            }
            fun bundleToMap(b: android.os.Bundle): Map<String, Any?> {
                val r = mutableMapOf<String, Any?>()
                for (k in b.keySet()) r[k] = b.get(k)
                return r
            }
            fun jsonToMap(obj: org.json.JSONObject): Map<String, Any?> {
                val map = mutableMapOf<String, Any?>()
                val it = obj.keys()
                while (it.hasNext()) {
                    val k = it.next()
                    val v = obj.opt(k)
                    map[k] = when (v) {
                        is org.json.JSONObject -> jsonToMap(v)
                        is org.json.JSONArray -> {
                            val list = mutableListOf<Any?>()
                            for (i in 0 until v.length()) {
                                val e = v.opt(i)
                                list.add(if (e is org.json.JSONObject) jsonToMap(e) else e)
                            }
                            list
                        }
                        else -> v
                    }
                }
                return map
            }

            var callData: MutableMap<String, Any?>? = null

            (extras.get("EXTRA_CALLKIT_CALL_DATA") as? android.os.Bundle)?.let {
                callData = bundleToMap(it).toMutableMap()
            }
            if (callData == null) {
                extras.getString("EXTRA_CALLKIT_CALL_DATA")?.let { s ->
                    try { callData = jsonToMap(org.json.JSONObject(s)).toMutableMap() } catch (_: Exception) {}
                }
            }
            if (callData == null) {
                val m = mutableMapOf<String, Any?>()
                fun putIf(k: String) { if (extras.containsKey(k)) m[k] = extras.get(k) }
                arrayOf(
                    "EXTRA_CALLKIT_ID",
                    "EXTRA_CALLKIT_NAME_CALLER",
                    "EXTRA_CALLKIT_HANDLE",
                    "EXTRA_CALLKIT_TYPE",
                    "EXTRA_CALLKIT_IS_VIDEO",
                    "EXTRA_CALLKIT_DURATION",
                    "id","nameCaller","handle"
                ).forEach(::putIf)

                val ex = extras.get("EXTRA_CALLKIT_EXTRA")
                when (ex) {
                    is android.os.Bundle -> m["extra"] = bundleToMap(ex)
                    is String -> try { m["extra"] = jsonToMap(org.json.JSONObject(ex)) } catch (_: Exception) {}
                }
                if (m.isNotEmpty()) callData = m
            }
            if (callData == null) callData = (run {
                val r = mutableMapOf<String, Any?>()
                for (k in extras.keySet()) r[k] = extras.get(k)
                r
            })

            val normalized = mutableMapOf<String, Any?>()

            val extraAny = callData!!["extra"]
            if (extraAny is Map<*, *>) {
                for ((k, v) in extraAny) if (k is String) normalized[k] = v
            } else if (extraAny is String) {
                try {
                    val jo = org.json.JSONObject(extraAny)
                    for (k in jo.keys()) normalized[k] = jo.get(k)
                } catch (_: Exception) {}
            }

            val id = firstNonBlank(
                callData!!["id"],
                callData!!["EXTRA_CALLKIT_ID"],
                callData!!["callId"],
                callData!!["channel"]
            ) ?: ""
            if (id.isNotEmpty()) {
                normalized["callId"] = id
                if (firstNonBlank(normalized["channel"]).isNullOrBlank()) normalized["channel"] = id
            }

            val sp = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val selfId = sp.getString("flutter.user_id", null)
            if (!selfId.isNullOrBlank() && firstNonBlank(normalized["receiverId"]).isNullOrBlank()) {
                normalized["receiverId"] = selfId
            }

            val callerName = firstNonBlank(
                normalized["callerName"],
                callData!!["EXTRA_CALLKIT_NAME_CALLER"],
                callData!!["nameCaller"],
                callData!!["name"]
            )
            if (!callerName.isNullOrBlank()) normalized["callerName"] = callerName

            var callerId = firstNonBlank(
                normalized["callerId"],
                callData!!["callerId"],
                callData!!["EXTRA_CALLKIT_HANDLE"],
                callData!!["handle"],
                callData!!["fromUserId"],
                callData!!["from"],
                callData!!["userId"],
                callData!!["uid"],
                callData!!["number"],
                callData!!["phoneNumber"]
            )

            if (callerId.isNullOrBlank()) {
                val last = sp.getString("flutter.last_callkit_extra", null)
                if (!last.isNullOrBlank()) {
                    try {
                        val jo = org.json.JSONObject(last)
                        val lastCaller = jo.optString("callerId", "")
                        if (lastCaller.isNotBlank()) callerId = lastCaller
                        if (firstNonBlank(normalized["channel"]).isNullOrBlank()) {
                            val ch = jo.optString("channel", "")
                            if (ch.isNotBlank()) normalized["channel"] = ch
                        }
                        if (firstNonBlank(normalized["receiverId"]).isNullOrBlank()) {
                            val rid = jo.optString("receiverId", "")
                            if (rid.isNotBlank()) normalized["receiverId"] = rid
                        }
                        if (firstNonBlank(normalized["callerName"]).isNullOrBlank()) {
                            val cn = jo.optString("callerName", "")
                            if (cn.isNotBlank()) normalized["callerName"] = cn
                        }
                    } catch (_: Exception) {}
                }
            }

            if (!callerId.isNullOrBlank()) normalized["callerId"] = callerId!!.trim()

            if ((firstNonBlank(normalized["channel"]) ?: "").isBlank() && id.isNotEmpty()) {
                normalized["channel"] = id
            }

            val finalJson = org.json.JSONObject(normalized as Map<*, *>).toString()
            val now = System.currentTimeMillis()
            val callIdOrCh = (normalized["channel"] ?: normalized["callId"] ?: id).toString()

            // 🔥 60s TTL CLEANUP (minimal change)
            val prevAt = sp.getLong("flutter.pending_join_at", 0L)
            if (prevAt > 0L && (now - prevAt) > 60_000L) {
                sp.edit()
                    .remove("flutter.pending_join")
                    .remove("flutter.pending_join_at")
                    .remove("flutter.pending_boot_pump")
                    .remove("flutter.pending_join_callId")
                    .apply()
                android.util.Log.d("PJOIN", "🧹 pending_join cleared (TTL expired >60s)")

            }

            val ok = sp.edit()
                .putString("flutter.pending_join", finalJson)
                .putLong("flutter.pending_join_at", now)          // ✅ timestamp
                .putBoolean("flutter.pending_boot_pump", true)    // ✅ boot marker
                .putString("flutter.pending_join_callId", callIdOrCh) // ✅ pending id
                .remove("flutter.pjoin_consumed_callId")          // ✅ clear any old consumed
                .commit()

            android.util.Log.d("PJOIN", "persist: saved=$ok json=$finalJson")
        } catch (e: Exception) {
            android.util.Log.e("PJOIN", "persist: error=${e.message}", e)
        }
    }

//    private fun persistPendingJoinFromIntent(intent: Intent?) {
//        try {
//            if (intent == null) { android.util.Log.d("PJOIN","persist: intent=null"); return }
//            val extras = intent.extras ?: run {
//                android.util.Log.d("PJOIN","persist: extras=null"); return
//            }
//            android.util.Log.d("PJOIN", "persist: keys=${extras.keySet()}")
//
//            fun firstNonBlank(vararg items: Any?): String? {
//                for (it in items) {
//                    val s = (it ?: "").toString().trim()
//                    if (s.isNotEmpty() && s.lowercase() != "null") return s
//                }
//                return null
//            }
//            fun bundleToMap(b: android.os.Bundle): Map<String, Any?> {
//                val r = mutableMapOf<String, Any?>()
//                for (k in b.keySet()) r[k] = b.get(k)
//                return r
//            }
//            fun jsonToMap(obj: org.json.JSONObject): Map<String, Any?> {
//                val map = mutableMapOf<String, Any?>()
//                val it = obj.keys()
//                while (it.hasNext()) {
//                    val k = it.next()
//                    val v = obj.opt(k)
//                    map[k] = when (v) {
//                        is org.json.JSONObject -> jsonToMap(v)
//                        is org.json.JSONArray -> {
//                            val list = mutableListOf<Any?>()
//                            for (i in 0 until v.length()) {
//                                val e = v.opt(i)
//                                list.add(if (e is org.json.JSONObject) jsonToMap(e) else e)
//                            }
//                            list
//                        }
//                        else -> v
//                    }
//                }
//                return map
//            }
//
//            var callData: MutableMap<String, Any?>? = null
//
//            (extras.get("EXTRA_CALLKIT_CALL_DATA") as? android.os.Bundle)?.let {
//                callData = bundleToMap(it).toMutableMap()
//            }
//            if (callData == null) {
//                extras.getString("EXTRA_CALLKIT_CALL_DATA")?.let { s ->
//                    try { callData = jsonToMap(org.json.JSONObject(s)).toMutableMap() } catch (_: Exception) {}
//                }
//            }
//            if (callData == null) {
//                val m = mutableMapOf<String, Any?>()
//                fun putIf(k: String) { if (extras.containsKey(k)) m[k] = extras.get(k) }
//                arrayOf(
//                    "EXTRA_CALLKIT_ID",
//                    "EXTRA_CALLKIT_NAME_CALLER",
//                    "EXTRA_CALLKIT_HANDLE",
//                    "EXTRA_CALLKIT_TYPE",
//                    "EXTRA_CALLKIT_IS_VIDEO",
//                    "EXTRA_CALLKIT_DURATION",
//                    "id","nameCaller","handle"
//                ).forEach(::putIf)
//
//                val ex = extras.get("EXTRA_CALLKIT_EXTRA")
//                when (ex) {
//                    is android.os.Bundle -> m["extra"] = bundleToMap(ex)
//                    is String -> try { m["extra"] = jsonToMap(org.json.JSONObject(ex)) } catch (_: Exception) {}
//                }
//                if (m.isNotEmpty()) callData = m
//            }
//            if (callData == null) callData = (run {
//                val r = mutableMapOf<String, Any?>()
//                for (k in extras.keySet()) r[k] = extras.get(k)
//                r
//            })
//
//            val normalized = mutableMapOf<String, Any?>()
//
//            val extraAny = callData!!["extra"]
//            if (extraAny is Map<*, *>) {
//                for ((k, v) in extraAny) if (k is String) normalized[k] = v
//            } else if (extraAny is String) {
//                try {
//                    val jo = org.json.JSONObject(extraAny)
//                    for (k in jo.keys()) normalized[k] = jo.get(k)
//                } catch (_: Exception) {}
//            }
//
//            val id = firstNonBlank(
//                callData!!["id"],
//                callData!!["EXTRA_CALLKIT_ID"],
//                callData!!["callId"],
//                callData!!["channel"]
//            ) ?: ""
//            if (id.isNotEmpty()) {
//                normalized["callId"] = id
//                if (firstNonBlank(normalized["channel"]).isNullOrBlank()) normalized["channel"] = id
//            }
//
//            val sp = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
//            val selfId = sp.getString("flutter.user_id", null)
//            if (!selfId.isNullOrBlank() && firstNonBlank(normalized["receiverId"]).isNullOrBlank()) {
//                normalized["receiverId"] = selfId
//            }
//
//            val callerName = firstNonBlank(
//                normalized["callerName"],
//                callData!!["EXTRA_CALLKIT_NAME_CALLER"],
//                callData!!["nameCaller"],
//                callData!!["name"]
//            )
//            if (!callerName.isNullOrBlank()) normalized["callerName"] = callerName
//
//            var callerId = firstNonBlank(
//                normalized["callerId"],
//                callData!!["callerId"],
//                callData!!["EXTRA_CALLKIT_HANDLE"],
//                callData!!["handle"],
//                callData!!["fromUserId"],
//                callData!!["from"],
//                callData!!["userId"],
//                callData!!["uid"],
//                callData!!["number"],
//                callData!!["phoneNumber"]
//            )
//
//            if (callerId.isNullOrBlank()) {
//                val last = sp.getString("flutter.last_callkit_extra", null)
//                if (!last.isNullOrBlank()) {
//                    try {
//                        val jo = org.json.JSONObject(last)
//                        val lastCaller = jo.optString("callerId", "")
//                        if (lastCaller.isNotBlank()) callerId = lastCaller
//                        if (firstNonBlank(normalized["channel"]).isNullOrBlank()) {
//                            val ch = jo.optString("channel", "")
//                            if (ch.isNotBlank()) normalized["channel"] = ch
//                        }
//                        if (firstNonBlank(normalized["receiverId"]).isNullOrBlank()) {
//                            val rid = jo.optString("receiverId", "")
//                            if (rid.isNotBlank()) normalized["receiverId"] = rid
//                        }
//                        if (firstNonBlank(normalized["callerName"]).isNullOrBlank()) {
//                            val cn = jo.optString("callerName", "")
//                            if (cn.isNotBlank()) normalized["callerName"] = cn
//                        }
//                    } catch (_: Exception) {}
//                }
//            }
//
//            if (!callerId.isNullOrBlank()) normalized["callerId"] = callerId!!.trim()
//
//            if ((firstNonBlank(normalized["channel"]) ?: "").isBlank() && id.isNotEmpty()) {
//                normalized["channel"] = id
//            }
//
//            val finalJson = org.json.JSONObject(normalized as Map<*, *>).toString()
//            val now = System.currentTimeMillis()
//            val callIdOrCh = (normalized["channel"] ?: normalized["callId"] ?: id).toString()
//
//
//            val ok = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
//                .edit()
//
//                .putString("flutter.pending_join", finalJson)
//                .putLong("flutter.pending_join_at", now)                 // ✅ timestamp
//                .putBoolean("flutter.pending_boot_pump", true)           // ✅ boot marker
//                .putString("flutter.pending_join_callId", callIdOrCh)    // ✅ pending id
//                .remove("flutter.pjoin_consumed_callId")                 // ✅ clear any old consumed
//                .commit()
//
//            android.util.Log.d("PJOIN", "persist: saved=$ok json=$finalJson")
//        } catch (e: Exception) {
//            android.util.Log.e("PJOIN", "persist: error=${e.message}", e)
//        }
//    }

    // (utility conversions used above – unchanged)
    private fun bundleToMap(bundle: Bundle): Map<String, Any?> {
        val r = mutableMapOf<String, Any?>()
        for (key in bundle.keySet()) {
            val v = bundle.get(key)
            r[key] = when (v) {
                is Bundle -> bundleToMap(v)
                else -> v
            }
        }
        return r
    }

    private fun jsonToMap(jo: JSONObject): Map<String, Any?> {
        val r = mutableMapOf<String, Any?>()
        val it = jo.keys()
        while (it.hasNext()) {
            val k = it.next()
            val v = jo.get(k)
            r[k] = when (v) {
                is JSONObject -> jsonToMap(v)
                else -> v
            }
        }
        return r
    }

    // Native File Download Notification
    private fun showFileOpenNotification(title: String, absPath: String, mime: String) {
        if (absPath.isEmpty()) return
        val file = File(absPath)
        if (!file.exists()) return

        val ctx = this
        val channelId = "downloads_open_direct"

        // Ensure channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val ch = NotificationChannel(channelId, "Downloads", NotificationManager.IMPORTANCE_HIGH)
            nm.createNotificationChannel(ch)
        }

        // Build a content:// URI via FileProvider and grant read permission
        val uri: Uri = FileProvider.getUriForFile(ctx, "${ctx.packageName}.fileprovider", file)
        val view = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mime)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        // PendingIntent that opens the viewer app (NOT your app)
        val pi = PendingIntent.getActivity(
            ctx,
            0,
            view,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(ctx, channelId)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle("Download complete")
            .setContentText(title)
            .setContentIntent(pi)      // tap → open viewer directly
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(System.currentTimeMillis().toInt(), builder.build())
    }



}











































