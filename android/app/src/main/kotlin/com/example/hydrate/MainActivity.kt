package com.example.hydrate

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.hydrate/alarm_launch"
    }

    private var alarmLaunchData: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        handleAlarmIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        handleAlarmIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "getInitialAlarm" -> {
                    result.success(alarmLaunchData)
                    alarmLaunchData = null
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun handleAlarmIntent(intent: Intent?) {
        if (intent?.action != "com.gdelataillade.alarm.action.RING") {
            return
        }

        val alarmId = intent.getIntExtra("alarmId", -1)

        if (alarmId == -1) {
            return
        }

        alarmLaunchData = mapOf(
            "alarmId" to alarmId,
            "alarmTitle" to intent.getStringExtra("alarmTitle"),
            "alarmBody" to intent.getStringExtra("alarmBody"),
        )
    }
}