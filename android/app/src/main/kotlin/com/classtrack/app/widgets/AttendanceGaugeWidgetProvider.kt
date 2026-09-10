package com.classtrack.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.classtrack.app.MainActivity
import com.classtrack.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

open class AttendanceGaugeWidgetProvider : HomeWidgetProvider() {

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

        val pctStr = getString("gauge_pct_str", "--%")
        val bunksStr = getString("gauge_safe_bunks_str", "Tap to check")
        val lowestStr = getString("gauge_lowest_subject", "")
        val pctValue = getInt("gauge_pct_value", 75)
        val statusColor = getInt("gauge_status_color", 0xFF3B82F6.toInt())
        val compositeBgColor = getInt("widget_bg_color", 0xE61C1D22.toInt())
        val opacityInt = getInt("widget_opacity_int", 217)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_attendance_gauge)

            // Dynamic theme background & opacity
            views.setInt(R.id.widget_background, "setColorFilter", compositeBgColor)
            views.setInt(R.id.widget_background, "setImageAlpha", opacityInt)

            views.setTextViewText(R.id.widget_gauge_pct, pctStr)
            views.setTextColor(R.id.widget_gauge_pct, statusColor)
            views.setProgressBar(R.id.widget_gauge_progress, 100, pctValue.coerceIn(0, 100), false)
            views.setTextViewText(R.id.widget_gauge_bunks, bunksStr)

            if (lowestStr.isNotBlank()) {
                views.setTextViewText(R.id.widget_gauge_lowest, lowestStr)
                views.setViewVisibility(R.id.widget_gauge_lowest, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_gauge_lowest, View.GONE)
            }

            // Click root opens MainActivity safely (Android 14/15 compatible)
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_gauge_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
