# Flutter Deferred Components & Play Core (optional dependencies)
-dontwarn com.google.android.play.core.**

# Google ML Kit Optional Language Recognizers (Chinese, Japanese, Korean, Devanagari)
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.**

# Keep rules for Flutter Engine & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit & Barcode rules
-keep class com.google.mlkit.** { *; }
-keepclassmembers class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# SQLite rules
-keep class org.sqlite.** { *; }

# ClassTrack Home Screen Widgets & HomeWidget plugin
-keep class com.classtrack.app.widgets.** { *; }
-keep class com.classtrack.app.NextClassWidgetProvider { *; }
-keep class com.classtrack.app.TodayAgendaWidgetProvider { *; }
-keep class com.classtrack.app.AttendanceGaugeWidgetProvider { *; }
-keep class es.antonborri.home_widget.** { *; }

