# Flutter 基础规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保留第三方库
-keep class com.ryanheise.** { *; }
-keep class just.audio.** { *; }
-keep class com.cached_network_image.** { *; }

# 保留数据类
-keepclassmembers class * {
    public <init>();
}