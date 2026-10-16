# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve annotations and type signatures
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Supabase / Postgrest / Gotrue / Realtime
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# OkHttp & Coroutines
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Gson / JSON Serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Image Picker & Webview
-dontwarn com.google.android.material.**

# Google Play Core / Deferred Components
-dontwarn com.google.android.play.core.**
