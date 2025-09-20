# Flutter and Dart specific rules for modern Flutter (SDK 35+)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Support for 16 KB memory page sizes
-keep class androidx.lifecycle.DefaultLifecycleObserver

# Keep native method names for Flutter
-keepclassmembers class * {
    native <methods>;
}

# Material Design Components
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# Keep application class
-keep public class * extends android.app.Application

# Modern Flutter (no deprecated Play Core dependencies)
# Ignore missing classes that are not used in this build configuration
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager