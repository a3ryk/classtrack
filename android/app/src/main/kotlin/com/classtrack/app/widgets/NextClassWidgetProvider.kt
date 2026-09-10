package com.classtrack.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.classtrack.app.MainActivity
import com.classtrack.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

open class NextClassWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val prefsFallback = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        fun getString(key: String, def: String): String {
            fun readFrom(prefs: SharedPreferences, k: String): String? {
                val value = prefs.all[k] ?: return null
                return when (value) {
                    is String -> value
                    else -> value.toString()
                }
            }
            return readFrom(widgetData, key)
                ?: readFrom(widgetData, "flutter.$key")
                ?: readFrom(prefsFallback, "flutter.$key")
                ?: readFrom(prefsFallback, key)
                ?: def
        }

        fun getInt(key: String, def: Int): Int {
            fun readFrom(prefs: SharedPreferences, k: String): Int? {
                val value = prefs.all[k] ?: return null
                return when (value) {
                    is Number -> value.toInt()
                    is String -> value.toIntOrNull()
                    is Boolean -> if (value) 1 else 0
                    else -> null
                }
            }
            return readFrom(widgetData, key)
                ?: readFrom(widgetData, "flutter.$key")
                ?: readFrom(prefsFallback, "flutter.$key")
                ?: readFrom(prefsFallback, key)
                ?: def
        }

        val subject = getString("next_class_subject", "ClassTrack")
        val time = getString("next_class_time", "Tap to open timetable")
        val room = getString("next_class_room", "")
        val countdown = getString("next_class_countdown", "Next")
        val statusDotColor = getInt("next_class_status_dot", 0xFF3B82F6.toInt())
        val compositeBgColor = getInt("widget_bg_color", 0xE61C1D22.toInt())
        val opacityInt = getInt("widget_opacity_int", 217)

        val timeAndRoom = if (room.isNotBlank()) "$time • $room" else time

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_next_class)

            views.setTextViewText(R.id.widget_subject_name, subject)
            views.setTextViewText(R.id.widget_time_room, timeAndRoom)
            views.setTextViewText(R.id.widget_countdown_chip, countdown)
            views.setTextColor(R.id.widget_countdown_chip, statusDotColor)

            // Dynamic status dot tint
            views.setInt(R.id.widget_status_dot, "setColorFilter", statusDotColor)

            // Dynamic theme background & opacity
            views.setInt(R.id.widget_background, "setColorFilter", compositeBgColor)
            views.setInt(R.id.widget_background, "setImageAlpha", opacityInt)

            // Open app on click (Android 14/15 safe)
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_next_class_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
