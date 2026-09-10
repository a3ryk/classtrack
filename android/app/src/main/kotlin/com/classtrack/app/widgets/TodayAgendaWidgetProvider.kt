package com.classtrack.app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.classtrack.app.MainActivity
import com.classtrack.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

open class TodayAgendaWidgetProvider : HomeWidgetProvider() {

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

        fun getBoolean(key: String, def: Boolean): Boolean {
            fun readFrom(prefs: SharedPreferences, k: String): Boolean? {
                val value = prefs.all[k] ?: return null
                return when (value) {
                    is Boolean -> value
                    is Number -> value.toInt() != 0
                    is String -> value.toBooleanStrictOrNull()
                    else -> null
                }
            }
            return readFrom(widgetData, key)
                ?: readFrom(widgetData, "flutter.$key")
                ?: readFrom(prefsFallback, "flutter.$key")
                ?: readFrom(prefsFallback, key)
                ?: def
        }

        val dateStr = getString("agenda_date_str", "Today's Schedule")
        val pctStr = getString("agenda_attendance_pct", "--%")
        val heroSubject = getString("next_class_subject", "No Class In Progress")
        val heroTime = getString("next_class_time", "")
        val heroRoom = getString("next_class_room", "")
        val heroSessionId = getString("next_class_session_id", "")
        val upcomingJson = getString("agenda_upcoming_json", "[]")
        val directMarking = getBoolean("widget_direct_marking", true)
        val compositeBgColor = getInt("widget_bg_color", 0xE61C1D22.toInt())
        val opacityInt = getInt("widget_opacity_int", 217)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_today_agenda)

            // Dynamic theme background & opacity
            views.setInt(R.id.widget_background, "setColorFilter", compositeBgColor)
            views.setInt(R.id.widget_background, "setImageAlpha", opacityInt)

            views.setTextViewText(R.id.widget_agenda_date, dateStr)
            views.setTextViewText(R.id.widget_agenda_pct, pctStr)
            views.setTextViewText(R.id.widget_hero_subject, heroSubject)
            views.setTextViewText(R.id.widget_hero_time, heroTime)

            if (heroRoom.isNotBlank()) {
                views.setTextViewText(R.id.widget_hero_room, heroRoom)
                views.setViewVisibility(R.id.widget_hero_room, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_hero_room, View.GONE)
            }

            // Only show direct attendance marking buttons when an active class is in session
            // and the user has direct attendance marking enabled
            if (heroSessionId.isNotBlank() && directMarking) {
                views.setViewVisibility(R.id.widget_btn_present, View.VISIBLE)
                views.setViewVisibility(R.id.widget_btn_absent, View.VISIBLE)

                // Click Present button
                val presentIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                    action = WidgetActionReceiver.ACTION_MARK_ATTENDANCE
                    putExtra(WidgetActionReceiver.EXTRA_SESSION_ID, heroSessionId)
                    putExtra(WidgetActionReceiver.EXTRA_OUTCOME, "PRESENT")
                }
                val presentPendingIntent = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 10 + 1,
                    presentIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_btn_present, presentPendingIntent)

                // Click Absent button
                val absentIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                    action = WidgetActionReceiver.ACTION_MARK_ATTENDANCE
                    putExtra(WidgetActionReceiver.EXTRA_SESSION_ID, heroSessionId)
                    putExtra(WidgetActionReceiver.EXTRA_OUTCOME, "ABSENT")
                }
                val absentPendingIntent = PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 10 + 2,
                    absentIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_btn_absent, absentPendingIntent)
            } else {
                views.setViewVisibility(R.id.widget_btn_present, View.GONE)
                views.setViewVisibility(R.id.widget_btn_absent, View.GONE)
            }

            // Parse upcoming lectures
            try {
                val array = JSONArray(upcomingJson)
                if (array.length() > 0) {
                    val first = array.getJSONObject(0)
                    val name = first.optString("name", "")
                    val time = first.optString("time", "")
                    views.setTextViewText(R.id.widget_upcoming_1, "Next: $name ($time)")
                    views.setViewVisibility(R.id.widget_upcoming_1, View.VISIBLE)
                } else {
                    views.setTextViewText(R.id.widget_upcoming_1, "No upcoming lectures today")
                    views.setViewVisibility(R.id.widget_upcoming_1, View.VISIBLE)
                }

                if (array.length() > 1) {
                    val second = array.getJSONObject(1)
                    val name = second.optString("name", "")
                    val time = second.optString("time", "")
                    views.setTextViewText(R.id.widget_upcoming_2, "Then: $name ($time)")
                    views.setViewVisibility(R.id.widget_upcoming_2, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_upcoming_2, View.GONE)
                }
            } catch (e: Exception) {
                views.setTextViewText(R.id.widget_upcoming_1, "Tap to view schedule")
                views.setViewVisibility(R.id.widget_upcoming_2, View.GONE)
            }

            // Click root opens MainActivity safely (Android 14/15 compatible)
            val openAppPendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_agenda_root, openAppPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
