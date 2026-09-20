package com.attendly

import com.attendly.widgets.NextClassWidgetProvider as NextClassProviderImpl
import com.attendly.widgets.TodayAgendaWidgetProvider as TodayAgendaProviderImpl
import com.attendly.widgets.AttendanceGaugeWidgetProvider as AttendanceGaugeProviderImpl

/**
 * Root-package aliases for AppWidget providers to ensure backwards compatibility
 * and prevent ClassNotFoundException if the OS or external broadcasts reference
 * com.attendly.<ProviderName> instead of com.attendly.widgets.<ProviderName>.
 */
class NextClassWidgetProvider : NextClassProviderImpl()
class TodayAgendaWidgetProvider : TodayAgendaProviderImpl()
class AttendanceGaugeWidgetProvider : AttendanceGaugeProviderImpl()
