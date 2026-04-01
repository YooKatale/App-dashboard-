# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store Split Install — suppress missing class errors from R8
# These classes are optionally present when using deferred components
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }

# Flutterwave
-keep class com.flutterwave.** { *; }

# OkHttp / Retrofit (used by http package)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.** { *; }

# Kotlin serialization
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Model classes (JSON deserialization)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Don't remove stack trace info
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Remove debug logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
