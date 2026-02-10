package com.example.minemusic

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    // 与 Flutter 通信的通道名
    private val CHANNEL = "mine_music/widget"
    private lateinit var playStateSP: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 初始化 SharedPreferences（用于保存播放状态）
        playStateSP = getSharedPreferences("play_state", Context.MODE_PRIVATE)

        // 设置 MethodChannel 处理器
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
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
    }

    /**
     * 更新所有小部件实例
     */
    private fun updateAllWidgets() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val componentName = ComponentName(this, MusicPlayerWidget::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        // 通知小部件更新
        val intent = Intent(this, MusicPlayerWidget::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        sendBroadcast(intent)
    }
}
