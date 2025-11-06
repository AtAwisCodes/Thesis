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
