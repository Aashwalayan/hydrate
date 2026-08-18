package com.example.hydrate

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class HydrationAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val CHANNEL_ID = "native_hydration_alarms"
        private const val CHANNEL_NAME = "Hydration Alarms"
        private const val NOTIFICATION_ID_OFFSET = 200000
    }

    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("alarmId", -1)
        val label = intent.getStringExtra("label") ?: "Hydration reminders"
        val scheduledTime = intent.getLongExtra("scheduledTime", 0L)

        if (alarmId == -1) return

        android.util.Log.d(
            "HydrationAlarm",
            "RECEIVER FIRED: id=$alarmId label=$label"
        )

        createNotificationChannel(context)

        val activityIntent = Intent(
            context,
            MainActivity::class.java
        ).apply {
            action = "com.example.hydrate.HYDRATION_ALARM"

            flags =
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP

            putExtra("alarmId", alarmId)
            putExtra("label", label)
            putExtra("scheduledTime", scheduledTime)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            alarmId,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            android.util.Log.d(
                "HydrationAlarm",
                "Full-screen intent allowed: " +
                    notificationManager.canUseFullScreenIntent()
            )
        }

        val notification = android.app.Notification.Builder(
            context,
            CHANNEL_ID
        )
            .setSmallIcon(com.example.hydrate.R.mipmap.ic_launcher)
            .setContentTitle("Time to hydrate")
            .setContentText(label)
            .setCategory(android.app.Notification.CATEGORY_ALARM)
            .setPriority(android.app.Notification.PRIORITY_MAX)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .setOngoing(true)
            .setVisibility(android.app.Notification.VISIBILITY_PUBLIC)
            .setFullScreenIntent(pendingIntent, true)
            .build()

        android.util.Log.d(
            "HydrationAlarm",
            "POSTING NATIVE NOTIFICATION: id=${NOTIFICATION_ID_OFFSET + alarmId}"
        )

        notificationManager.notify(
            NOTIFICATION_ID_OFFSET + alarmId,
            notification
        )
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager

        val existingChannel =
            notificationManager.getNotificationChannel(CHANNEL_ID)

        if (existingChannel != null) {
            android.util.Log.d(
                "HydrationAlarm",
                "CHANNEL STATE: id=$CHANNEL_ID importance=${existingChannel.importance} sound=${existingChannel.sound}"
            )
        }

        if (existingChannel != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Full-screen hydration alarms"
            setSound(
                android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI,
                android.media.AudioAttributes.Builder()
                    .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                    .build()
            )
            enableVibration(true)
            setBypassDnd(true)
        }

        notificationManager.createNotificationChannel(channel)
    }
}
