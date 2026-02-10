package com.example.minemusic

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.minemusic.appwidgets.AppWidgetCircle
import com.example.minemusic.appwidgets.AppWidgetMD3
import com.example.minemusic.model.Song
import com.example.minemusic.service.MusicService
import com.example.minemusic.service.MusicService.Companion.APP_WIDGET_UPDATE
import com.example.minemusic.service.MusicService.Companion.EXTRA_APP_WIDGET_NAME

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "mine_music/widget"
    private lateinit var playStateSP: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val serviceIntent = Intent(this, MusicService::class.java)
        startService(serviceIntent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 初始化 SharedPreferences（用于保存播放状态）
        playStateSP = getSharedPreferences("play_state", Context.MODE_PRIVATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "syncPlayState" -> {
                    val songTitle = call.argument<String>("songTitle") ?: ""
                    val artist = call.argument<String>("artist") ?: ""
                    val coverId = call.argument<String>("coverId") ?: ""
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false

                    playStateSP.edit()
                        .putString("current_song_title", songTitle)
                        .putString("current_artist", artist)
                        .putString("current_cover_id", coverId)
                        .putBoolean("is_playing", isPlaying)
                        .apply()

                    MusicService.currentSong = Song(
                        title = songTitle,
                        artistName = artist,
                        coverArt = coverId
                    )
                    MusicService.isPlaying = isPlaying

                    updateAllWidgets()

                    result.success(true)
                }
                "updateWidget" -> {
                    updateAllWidgets()
                    result.success(true)
                }
                "updateMD3Widget" -> {
                    updateMD3Widgets()
                    result.success(true)
                }
                "updateCircleWidget" -> {
                    updateCircleWidgets()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun updateAllWidgets() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val componentName = ComponentName(this, MusicPlayerWidget::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        val intent = Intent(this, MusicPlayerWidget::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        sendBroadcast(intent)

        updateMD3Widgets()
        updateCircleWidgets()
    }

    private fun updateMD3Widgets() {
        val updateIntent = Intent(APP_WIDGET_UPDATE)
        updateIntent.putExtra(EXTRA_APP_WIDGET_NAME, AppWidgetMD3.NAME)
        updateIntent.addFlags(Intent.FLAG_RECEIVER_REGISTERED_ONLY)
        LocalBroadcastManager.getInstance(this).sendBroadcast(updateIntent)
    }

    private fun updateCircleWidgets() {
        val updateIntent = Intent(APP_WIDGET_UPDATE)
        updateIntent.putExtra(EXTRA_APP_WIDGET_NAME, AppWidgetCircle.NAME)
        updateIntent.addFlags(Intent.FLAG_RECEIVER_REGISTERED_ONLY)
        LocalBroadcastManager.getInstance(this).sendBroadcast(updateIntent)
    }
}
