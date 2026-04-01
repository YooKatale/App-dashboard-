# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

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
