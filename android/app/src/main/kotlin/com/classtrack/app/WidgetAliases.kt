package com.classtrack.app

import com.classtrack.app.widgets.NextClassWidgetProvider as NextClassProviderImpl
import com.classtrack.app.widgets.TodayAgendaWidgetProvider as TodayAgendaProviderImpl
import com.classtrack.app.widgets.AttendanceGaugeWidgetProvider as AttendanceGaugeProviderImpl

/**
 * Root-package aliases for AppWidget providers to ensure backwards compatibility
 * and prevent ClassNotFoundException if the OS or external broadcasts reference
 * com.classtrack.app.<ProviderName> instead of com.classtrack.app.widgets.<ProviderName>.
 */
class NextClassWidgetProvider : NextClassProviderImpl()
class TodayAgendaWidgetProvider : TodayAgendaProviderImpl()
class AttendanceGaugeWidgetProvider : AttendanceGaugeProviderImpl()
