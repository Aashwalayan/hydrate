package com.example.hydrate

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.hydrate/alarm"
        private const val ALARM_ACTION = "com.example.hydrate.HYDRATION_ALARM"
    }

    private var alarmChannel: MethodChannel? = null
    private var pendingAlarmIntent: Intent? = null
    private var deliveredInitialAlarm = false

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d("HydrationAlarm", "MAIN ACTIVITY onCreate")
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        dispatchAlarmIntent(intent, "onCreate")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.d("HydrationAlarm", "CONFIGURE FLUTTER ENGINE")
        super.configureFlutterEngine(flutterEngine)

        alarmChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        alarmChannel?.setMethodCallHandler { call, result ->
            when (call.method) {

                "scheduleAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId")
                    val label = call.argument<String>("label")
                    val scheduledTime = call.argument<Long>("scheduledTime")

                    if (alarmId == null || label == null || scheduledTime == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Missing alarm arguments",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    HydrationAlarmScheduler.schedule(
                        context = this,
                        alarmId = alarmId,
                        label = label,
                        scheduledTime = scheduledTime
                    )

                    result.success(null)
                }

                "cancelAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId")

                    if (alarmId == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Missing alarm ID",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    HydrationAlarmScheduler.cancel(
                        context = this,
                        alarmId = alarmId
                    )

                    result.success(null)
                }

                "getInitialAlarm" -> {
                    val alarmIntent = pendingAlarmIntent ?: intent
                    val alarmMap = alarmIntent?.toAlarmMap()

                    Log.d(
                        "HydrationAlarm",
                        "getInitialAlarm returning=${alarmMap != null}"
                    )

                    pendingAlarmIntent = null
                    deliveredInitialAlarm = true

                    result.success(alarmMap)
                }

                else -> result.notImplemented()
            }
        }

    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        setIntent(intent)
        dispatchAlarmIntent(intent, "onNewIntent")
    }

    private fun dispatchAlarmIntent(sourceIntent: Intent?, source: String) {
        if (sourceIntent?.action != ALARM_ACTION) return

        val alarmMap = sourceIntent.toAlarmMap() ?: return

        Log.d(
            "HydrationAlarm",
            "MAIN ACTIVITY RECEIVED ALARM INTENT from=$source id=${alarmMap["alarmId"]}"
        )

        if (alarmChannel == null) {
            pendingAlarmIntent = sourceIntent
            return
        }

        alarmChannel?.invokeMethod("alarmTriggered", alarmMap)
        deliveredInitialAlarm = true
    }

    private fun Intent.toAlarmMap(): Map<String, Any>? {
        if (action != ALARM_ACTION) return null

        val alarmId = getIntExtra("alarmId", -1)
        if (alarmId == -1) return null

        return mapOf(
            "alarmId" to alarmId,
            "label" to (getStringExtra("label") ?: "Hydration reminders"),
            "scheduledTime" to getLongExtra("scheduledTime", 0L)
        )
    }
}
