package com.example.hydrate

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object HydrationAlarmScheduler {

    private const val REQUEST_CODE_OFFSET = 100000

    fun schedule(
        context: Context,
        alarmId: Int,
        label: String,
        scheduledTime: Long
    ) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val pendingIntent = createPendingIntent(
            context = context,
            alarmId = alarmId,
            label = label,
            scheduledTime = scheduledTime
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                throw SecurityException(
                    "Exact alarm permission is not granted."
                )
            }
        }

        Log.d(
            "HydrationAlarm",
            "SCHEDULING alarmId=$alarmId scheduledTime=$scheduledTime now=${System.currentTimeMillis()} delta=${scheduledTime - System.currentTimeMillis()}"
        )

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            scheduledTime,
            pendingIntent
        )
    }

    fun cancel(
        context: Context,
        alarmId: Int
    ) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val pendingIntent = createPendingIntent(
            context = context,
            alarmId = alarmId,
            label = "",
            scheduledTime = 0L
        )

        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun createPendingIntent(
        context: Context,
        alarmId: Int,
        label: String,
        scheduledTime: Long
    ): PendingIntent {

        val intent = Intent(
            context,
            HydrationAlarmReceiver::class.java
        ).apply {
            putExtra("alarmId", alarmId)
            putExtra("label", label)
            putExtra("scheduledTime", scheduledTime)
        }

        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_OFFSET + alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )
    }
}