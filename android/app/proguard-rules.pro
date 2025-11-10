# Keep WebView JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep YouTube Player classes
-keep class com.sarbagyastha.youtube_player_flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep WebView classes
-keep class android.webkit.** { *; }
-keepclassmembers class android.webkit.** { *; }

# Keep InAppWebView (used by youtube_player_flutter)
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keepclassmembers class com.pichillilorenzo.flutter_inappwebview.** { *; }

# Prevent obfuscation of video player
-keep class com.google.android.exoplayer2.** { *; }
-keep interface com.google.android.exoplayer2.** { *; }

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# AR Flutter Plugin
-keep class com.difrancescogianmarco.arcore_flutter_plugin.** { *; }
-keep class io.github.sceneview.** { *; }
-keepclassmembers class io.github.sceneview.** { *; }

# Google AR Core
-keep class com.google.ar.** { *; }
-keepclassmembers class com.google.ar.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Camera and Image Picker
-keep class io.flutter.plugins.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# Photo Manager
-keep class com.fluttercandies.photo_manager.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Suppress warnings
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.annotations.**
