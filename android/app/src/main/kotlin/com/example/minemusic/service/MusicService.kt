package com.example.minemusic.service

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Binder
import android.os.IBinder
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.example.minemusic.appwidgets.AppWidgetCircle
import com.example.minemusic.appwidgets.AppWidgetMD3
import com.example.minemusic.model.Song

class MusicService : Service() {

    companion object {
        const val ACTION_TOGGLE_PAUSE = "com.example.minemusic.togglepause"
        const val ACTION_REWIND = "com.example.minemusic.rewind"
        const val ACTION_SKIP = "com.example.minemusic.skip"
        const val TOGGLE_FAVORITE = "com.example.minemusic.togglefavorite"
        const val APP_WIDGET_UPDATE = "com.example.minemusic.appwidget.update"
        const val PLAY_STATE_CHANGED = "com.example.minemusic.playstatechanged"
        const val FAVORITE_STATE_CHANGED = "com.example.minemusic.favoritestatechanged"
        const val META_CHANGED = "com.example.minemusic.metachanged"
        const val EXTRA_APP_WIDGET_NAME = "app_widget_name"

        var currentSong: Song = Song()
        var isPlaying: Boolean = false
        var isFavorite: Boolean = false
    }

    private val binder = LocalBinder()
    private var widgetUpdateReceiver: BroadcastReceiver? = null

    inner class LocalBinder : Binder() {
        fun getService(): MusicService = this@MusicService
    }

    override fun onCreate() {
        super.onCreate()
        registerWidgetUpdateReceiver()
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_TOGGLE_PAUSE -> togglePlayPause()
            ACTION_REWIND -> rewind()
            ACTION_SKIP -> skip()
            TOGGLE_FAVORITE -> toggleFavorite()
        }
        return START_STICKY
    }

    private fun registerWidgetUpdateReceiver() {
        widgetUpdateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    APP_WIDGET_UPDATE -> {
                        val widgetName = intent.getStringExtra(EXTRA_APP_WIDGET_NAME)
                        when (widgetName) {
                            AppWidgetMD3.NAME -> {
                                AppWidgetMD3.instance.performUpdate(this@MusicService, null)
                            }
                            AppWidgetCircle.NAME -> {
                                AppWidgetCircle.instance.performUpdate(this@MusicService, null)
                            }
                        }
                    }
                    PLAY_STATE_CHANGED -> {
                        AppWidgetMD3.instance.performUpdate(this@MusicService, null)
                        AppWidgetCircle.instance.performUpdate(this@MusicService, null)
                    }
                    FAVORITE_STATE_CHANGED -> {
                        AppWidgetCircle.instance.performUpdate(this@MusicService, null)
                    }
                    META_CHANGED -> {
                        AppWidgetMD3.instance.performUpdate(this@MusicService, null)
                        AppWidgetCircle.instance.performUpdate(this@MusicService, null)
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(APP_WIDGET_UPDATE)
            addAction(PLAY_STATE_CHANGED)
            addAction(FAVORITE_STATE_CHANGED)
            addAction(META_CHANGED)
        }
        LocalBroadcastManager.getInstance(this).registerReceiver(widgetUpdateReceiver!!, filter)
    }

    private fun togglePlayPause() {
        isPlaying = !isPlaying
        notifyPlayStateChange()
    }

    private fun rewind() {
        notifyMetaChange()
    }

    private fun skip() {
        notifyMetaChange()
    }

    private fun toggleFavorite() {
        isFavorite = !isFavorite
        notifyFavoriteStateChange()
    }

    private fun notifyPlayStateChange() {
        val intent = Intent(PLAY_STATE_CHANGED)
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }

    private fun notifyFavoriteStateChange() {
        val intent = Intent(FAVORITE_STATE_CHANGED)
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }

    private fun notifyMetaChange() {
        val intent = Intent(META_CHANGED)
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }

    fun getSongCoverUrl(song: Song): String {
        if (song.coverArt.isEmpty()) {
            return ""
        }

        val sp = getSharedPreferences("subsonic_config", Context.MODE_PRIVATE)
        val baseUrl = sp.getString("base_url", "http://192.168.2.6:4533") ?: ""
        val username = sp.getString("username", "otoya") ?: ""
        val password = sp.getString("password", "486952") ?: ""

        return "$baseUrl/rest/getCoverArt.view?id=${song.coverArt}&u=$username&p=$password&v=1.16.1&c=MineMusic&f=json"
    }

    override fun onDestroy() {
        super.onDestroy()
        widgetUpdateReceiver?.let {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(it)
        }
    }
}