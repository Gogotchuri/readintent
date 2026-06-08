# Keep rules for native/JNI-backed plugins so R8 shrinking (release builds) does
# not strip classes reached only from native code or reflection.

# ONNX Runtime (TTS inference) — JNI bindings.
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# media_kit / mpv — native player backend.
-keep class com.alexmercerind.** { *; }
-keep class media_kit_** { *; }
-dontwarn com.alexmercerind.**

# audio_service + just_audio — background playback service & media session.
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# sqlite3 / drift native libraries.
-keep class com.github.requery.android.database.** { *; }
-dontwarn com.github.requery.android.database.**

# Flutter embedding (defensive; usually covered by the default Flutter rules).
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
