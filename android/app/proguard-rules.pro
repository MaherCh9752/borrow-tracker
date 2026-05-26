# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WorkManager plugin (keeps FlutterBackgroundExecutor Worker class)
-keep class dev.fluttercommunity.workmanager.** { *; }

# flutter_local_notifications (native AlarmManager receivers)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Keep all Worker subclasses so WorkManager can instantiate them after app death
-keep class * extends androidx.work.Worker { *; }

# Keep all BroadcastReceivers (needed for scheduled alarms to survive R8)
-keep class * extends android.content.BroadcastReceiver { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Gson (used by flutter_local_notifications for JSON serialization of scheduled notifications)
# Without these rules R8 obfuscates/removes Gson internals → deserialization in
# ScheduledNotificationReceiver fails → notification never shows.
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Play Core SplitCompat (optional — used by Flutter for deferred components, not needed here)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
