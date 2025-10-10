# Flutter 核心规则（必须）
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 你的项目依赖
-keep class com.ryanheise.** { *; }      # just_audio
-keep class just.audio.** { *; }         # just_audio
-keep class com.cached_network_image.** { *; }  # cached_network_image
-keep class com.github.** { *; }         # http 库

# Shared Preferences
-keep class com.sharepreferences.** { *; }

# Dynamic Color
-keep class io.dynamic_color.** { *; }

# 必要的 Android 组件
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver

# 保留数据模型类（防止 JSON 解析问题）
-keepclassmembers class * {
    public <init>();
    public *;
}