package com.example.minemusic

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter 与原生通信的通道插件
 * 实现 FlutterPlugin 接口，确保即使主 Activity 不是 MainActivity，也能注册 MethodChannel
 */
class WidgetMethodChannel : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var playStateSP: SharedPreferences

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mine_music/widget")
        channel.setMethodCallHandler(this)
        
        // 初始化 SharedPreferences（用于保存播放状态）
        playStateSP = context.getSharedPreferences("play_state", Context.MODE_PRIVATE)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "syncPlayState" -> {
                // 同步播放状态到原生
                val songTitle = call.argument<String>("songTitle") ?: ""
                val artist = call.argument<String>("artist") ?: ""
                val coverId = call.argument<String>("coverId") ?: ""
                val isPlaying = call.argument<Boolean>("isPlaying") ?: false

                // 保存播放状态到 SharedPreferences
                playStateSP.edit()
                    .putString("current_song_title", songTitle)
                    .putString("current_artist", artist)
                    .putString("current_cover_id", coverId)
                    .putBoolean("is_playing", isPlaying)
                    .apply()

                // 同步后更新小部件
                updateAllWidgets()

                result.success(true)
            }
            "updateWidget" -> {
                // 手动触发小部件更新
                updateAllWidgets()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    /**
     * 更新所有小部件实例
     */
    private fun updateAllWidgets() {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, MusicPlayerWidget::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        // 通知小部件更新
        val intent = android.content.Intent(context, MusicPlayerWidget::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        context.sendBroadcast(intent)
    }
}
