package com.example.minemusic

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.example.minemusic.widget.CoverLoader

class MusicPlayerWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.minemusic.ACTION_PLAY_PAUSE"
        const val ACTION_PREVIOUS = "com.example.minemusic.ACTION_PREVIOUS"
        const val ACTION_NEXT = "com.example.minemusic.ACTION_NEXT"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_music_player)

        // 绑定封面图片的点击事件 - 打开应用的主Activity
        val openAppIntent = Intent(context, Class.forName("com.ryanheise.audioservice.AudioServiceActivity"))
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.iv_album_art, openAppPendingIntent)

        // 加载播放状态（当前歌曲、艺术家、封面、播放状态）
        val sp = context.getSharedPreferences("play_state", Context.MODE_PRIVATE)
        val songTitle = sp.getString("current_song_title", "暂无播放歌曲") ?: ""
        val artist = sp.getString("current_artist", "未知艺术家") ?: ""
        val coverId = sp.getString("current_cover_id", "") ?: "" // Subsonic的coverArt ID
        val isPlaying = sp.getBoolean("is_playing", false)

        // 设置歌曲信息
        views.setTextViewText(R.id.tv_song_title, songTitle)
        views.setTextViewText(R.id.tv_artist, artist)

        // 加载封面图片
        CoverLoader(context, appWidgetId, views).loadCover(coverId)

        // 根据播放状态设置图标
        if (isPlaying) {
            views.setImageViewResource(R.id.btn_play_pause, R.drawable.ic_pause)
        } else {
            views.setImageViewResource(R.id.btn_play_pause, R.drawable.ic_play_arrow)
        }

        // 绑定播放/暂停按钮的点击事件
        val playPauseIntent = Intent(context, MusicWidgetReceiver::class.java).apply {
            action = ACTION_PLAY_PAUSE
        }
        val playPausePendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            playPauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_play_pause, playPausePendingIntent)

        // 绑定下一曲按钮的点击事件
        val nextIntent = Intent(context, MusicWidgetReceiver::class.java).apply {
            action = ACTION_NEXT
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_next, nextPendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    // 用于更新所有 Widget 实例
    fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, MusicPlayerWidget::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        onUpdate(context, appWidgetManager, appWidgetIds)
    }
}