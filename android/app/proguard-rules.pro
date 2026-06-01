# ProGuard rules for GROUPE NIKEFA Flutter app

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Riverpod
-keep class dev.fluttercommunity.riverpod.** { *; }

# Hive
-keep class com.hivemq.** { *; }
-dontwarn com.hivemq.**

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep model classes used with JSON serialization
-keep class net.nikefa.app.data.models.** { *; }

# Keep native method signatures
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Core (referenced by Flutter engine for deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
