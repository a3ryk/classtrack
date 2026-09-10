package com.classtrack.app.widgets

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast
import com.classtrack.app.MainActivity

class WidgetActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_MARK_ATTENDANCE = "com.classtrack.app.widgets.ACTION_MARK_ATTENDANCE"
        const val EXTRA_SESSION_ID = "extra_session_id"
        const val EXTRA_OUTCOME = "extra_outcome"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_MARK_ATTENDANCE) {
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: ""
            val outcome = intent.getStringExtra(EXTRA_OUTCOME) ?: ""

            if (sessionId.isNotBlank()) {
                val outcomeLabel = if (outcome == "PRESENT") "Present" else "Absent"
                Toast.makeText(context, "Attendance: $outcomeLabel", Toast.LENGTH_SHORT).show()

                // Launch MainActivity with extras so Flutter marks and resyncs
                val appIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("from_widget", true)
                    putExtra("widget_session_id", sessionId)
                    putExtra("widget_outcome", outcome)
                }
                context.startActivity(appIntent)
            }
        }
    }
}
