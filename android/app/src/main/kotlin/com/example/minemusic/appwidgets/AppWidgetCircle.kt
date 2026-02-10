/*
 * Copyright (c) 2020 Hemanth Savarla.
 *
 * Licensed under the GNU General Public License v3
 *
 * This is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 */
package com.example.minemusic.appwidgets

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.widget.RemoteViews
import com.example.minemusic.R
import com.example.minemusic.MainActivity
import com.example.minemusic.MusicPlayerWidget
import com.example.minemusic.MusicWidgetReceiver
import com.example.minemusic.appwidgets.base.BaseAppWidget
import com.example.minemusic.model.Song
import com.example.minemusic.service.MusicService
import com.bumptech.glide.Glide
import com.bumptech.glide.request.RequestOptions
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.target.Target
import com.bumptech.glide.request.transition.Transition

class AppWidgetCircle : BaseAppWidget() {
    private var target: Target<Bitmap>? = null

    override fun defaultAppWidget(context: Context, appWidgetIds: IntArray) {
        val appWidgetView = RemoteViews(context.packageName, R.layout.app_widget_circle)

        appWidgetView.setImageViewResource(R.id.image, R.mipmap.launcher_icon)
        appWidgetView.setImageViewResource(R.id.button_toggle_play_pause, R.drawable.ic_play_arrow)
        appWidgetView.setImageViewResource(R.id.button_toggle_skip, R.drawable.ic_skip_next)

        linkButtons(context, appWidgetView)
        pushUpdate(context, appWidgetIds, appWidgetView)
    }

    override fun performUpdate(service: MusicService, appWidgetIds: IntArray?) {
        val appWidgetView = RemoteViews(service.packageName, R.layout.app_widget_circle)

        val sp = service.getSharedPreferences("play_state", Context.MODE_PRIVATE)
        val isPlaying = sp.getBoolean("is_playing", false)
        val songTitle = sp.getString("current_song_title", "") ?: ""
        val artist = sp.getString("current_artist", "") ?: ""
        val coverId = sp.getString("current_cover_id", "") ?: ""

        val playPauseRes =
            if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play_arrow
        appWidgetView.setImageViewResource(R.id.button_toggle_play_pause, playPauseRes)

        linkButtons(service, appWidgetView)

        if (imageSize == 0) {
            val displayMetrics = service.resources.displayMetrics
            imageSize = displayMetrics.widthPixels.coerceAtMost(displayMetrics.heightPixels)
        }

        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        handler.post {
            if (target != null) {
                Glide.with(service).clear(target)
            }
            
            val coverUrl = service.getSongCoverUrl(Song(coverArt = coverId, title = songTitle, artistName = artist))
            if (coverUrl.isEmpty()) {
                appWidgetView.setImageViewResource(R.id.image, R.mipmap.launcher_icon)
                pushUpdate(service, appWidgetIds, appWidgetView)
                return@post
            }
            
            target = Glide.with(service)
                .asBitmap()
                .load(coverUrl)
                .apply(RequestOptions.circleCropTransform())
                .error(R.mipmap.launcher_icon)
                .into(object : CustomTarget<Bitmap>(imageSize, imageSize) {
                    override fun onResourceReady(
                        resource: Bitmap,
                        transition: Transition<in Bitmap>?,
                    ) {
                        update(resource)
                    }

                    override fun onLoadFailed(errorDrawable: Drawable?) {
                        update(null)
                    }

                    private fun update(bitmap: Bitmap?) {
                        if (bitmap != null) {
                            appWidgetView.setImageViewBitmap(R.id.image, bitmap)
                        } else {
                            appWidgetView.setImageViewResource(R.id.image, R.mipmap.launcher_icon)
                        }
                        pushUpdate(service, appWidgetIds, appWidgetView)
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {}
                })
        }
    }

    private fun linkButtons(context: Context, views: RemoteViews) {
        val mainActivityIntent = Intent(context, MainActivity::class.java)

        mainActivityIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        var pendingIntent =
            PendingIntent.getActivity(
                context, 0, mainActivityIntent, PendingIntent.FLAG_IMMUTABLE
            )
        views.setOnClickPendingIntent(R.id.image, pendingIntent)

        val playPauseIntent = Intent(context, MusicWidgetReceiver::class.java).apply {
            this.action = MusicPlayerWidget.ACTION_PLAY_PAUSE
        }
        val playPausePendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            playPauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.button_toggle_play_pause, playPausePendingIntent)

        val nextIntent = Intent(context, MusicWidgetReceiver::class.java).apply {
            this.action = MusicPlayerWidget.ACTION_NEXT
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.button_toggle_skip, nextPendingIntent)
    }

    companion object {
        const val NAME = "app_widget_circle"

        private var mInstance: AppWidgetCircle? = null
        private var imageSize = 0

        val instance: AppWidgetCircle
            @Synchronized get() {
                if (mInstance == null) {
                    mInstance = AppWidgetCircle()
                }
                return mInstance!!
            }
    }
}