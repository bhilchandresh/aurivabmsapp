# Minimal ProGuard rules for Flutter, Firebase, and OneSignal

# Keep Flutter core classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Ignore missing Play Core classes referenced by Flutter's deferred components
-dontwarn com.google.android.play.core.**

# Firebase (Mostly handled automatically by consumer rules in AAR)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# OneSignal (Mostly handled automatically, but kept for safety in aggressive shrinking)
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Standard Kotlin rules
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-dontwarn kotlin.**

# Keep standard Android classes
-keep public class * extends android.app.Application
-keep public class * extends android.app.Activity
