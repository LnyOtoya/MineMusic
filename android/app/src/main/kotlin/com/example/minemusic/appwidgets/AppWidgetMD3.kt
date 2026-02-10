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
import android.view.View
import android.widget.RemoteViews
import com.example.minemusic.R
import com.example.minemusic.MainActivity
import com.example.minemusic.appwidgets.base.BaseAppWidget
import com.example.minemusic.service.MusicService
import com.example.minemusic.service.MusicService.Companion.ACTION_REWIND
import com.example.minemusic.service.MusicService.Companion.ACTION_SKIP
import com.example.minemusic.service.MusicService.Companion.ACTION_TOGGLE_PAUSE
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.target.Target
import com.bumptech.glide.request.transition.Transition

class AppWidgetMD3 : BaseAppWidget() {
    private var target: Target<Bitmap>? = null

    override fun defaultAppWidget(context: Context, appWidgetIds: IntArray) {
        val appWidgetView = RemoteViews(context.packageName, R.layout.app_widget_md3)

        appWidgetView.setViewVisibility(R.id.media_titles, View.INVISIBLE)
        appWidgetView.setImageViewResource(R.id.image, R.mipmap.launcher_icon)

        appWidgetView.setImageViewResource(R.id.button_next, R.mipmap.ic_launcher)
        appWidgetView.setImageViewResource(R.id.button_prev, R.mipmap.ic_launcher)
        appWidgetView.setImageViewResource(R.id.button_toggle_play_pause, R.mipmap.ic_launcher)

        linkButtons(context, appWidgetView)
        pushUpdate(context, appWidgetIds, appWidgetView)
    }

    override fun performUpdate(service: MusicService, appWidgetIds: IntArray?) {
        val appWidgetView = RemoteViews(service.packageName, R.layout.app_widget_md3)

        val isPlaying = MusicService.isPlaying
        val song = MusicService.currentSong

        if (song.title.isEmpty() && song.artistName.isEmpty()) {
            appWidgetView.setViewVisibility(R.id.media_titles, View.INVISIBLE)
        } else {
            appWidgetView.setViewVisibility(R.id.media_titles, View.VISIBLE)
            appWidgetView.setTextViewText(R.id.title, song.title)
            appWidgetView.setTextViewText(R.id.text, getSongArtistAndAlbum(song))
        }

        val playPauseRes =
            if (isPlaying) R.mipmap.ic_launcher else R.mipmap.ic_launcher
        appWidgetView.setImageViewResource(R.id.button_toggle_play_pause, playPauseRes)

        appWidgetView.setImageViewResource(R.id.button_next, R.mipmap.ic_launcher)
        appWidgetView.setImageViewResource(R.id.button_prev, R.mipmap.ic_launcher)

        linkButtons(service, appWidgetView)

        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        handler.post {
            if (target is CustomTarget<*>) {
                Glide.with(service).clear(target as CustomTarget<*>)
            }
            
            val coverUrl = service.getSongCoverUrl(song)
            if (coverUrl.isEmpty()) {
                appWidgetView.setImageViewResource(R.id.image, R.mipmap.launcher_icon)
                pushUpdate(service, appWidgetIds, appWidgetView)
                return@post
            }
            
            target = Glide.with(service)
                .asBitmap()
                .load(coverUrl)
                .centerCrop()
                .error(R.mipmap.launcher_icon)
                .into(object : CustomTarget<Bitmap>(200, 200) {
                    override fun onResourceReady(
                        resource: Bitmap,
                        transition: Transition<in Bitmap>?,
                    ) {
                        update(resource)
                    }

                    override fun onLoadFailed(errorDrawable: Drawable?) {
                        update(null)
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {}

                    private fun update(bitmap: Bitmap?) {
                        if (bitmap != null) {
                            appWidgetView.setImageViewBitmap(R.id.image, bitmap)
                        } else {
                            appWidgetView.setImageViewResource(R.id.image, R.mipmap.launcher_icon)
                        }
                        pushUpdate(service, appWidgetIds, appWidgetView)
                    }
                })
        }
    }

    private fun linkButtons(context: Context, views: RemoteViews) {
        val action = Intent(context, MainActivity::class.java)

        val serviceName = ComponentName(context, MusicService::class.java)

        action.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        var pendingIntent =
            PendingIntent.getActivity(
                context, 0, action, PendingIntent.FLAG_IMMUTABLE
            )
        views.setOnClickPendingIntent(R.id.image, pendingIntent)
        views.setOnClickPendingIntent(R.id.media_titles, pendingIntent)

        pendingIntent = buildPendingIntent(context, ACTION_REWIND, serviceName)
        views.setOnClickPendingIntent(R.id.button_prev, pendingIntent)

        pendingIntent = buildPendingIntent(context, ACTION_TOGGLE_PAUSE, serviceName)
        views.setOnClickPendingIntent(R.id.button_toggle_play_pause, pendingIntent)

        pendingIntent = buildPendingIntent(context, ACTION_SKIP, serviceName)
        views.setOnClickPendingIntent(R.id.button_next, pendingIntent)
    }

    companion object {
        const val NAME = "app_widget_md3"

        private var mInstance: AppWidgetMD3? = null

        val instance: AppWidgetMD3
            @Synchronized get() {
                if (mInstance == null) {
                    mInstance = AppWidgetMD3()
                }
                return mInstance!!
            }
    }
}