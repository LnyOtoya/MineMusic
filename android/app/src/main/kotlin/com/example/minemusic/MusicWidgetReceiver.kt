package com.example.minemusic

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.view.KeyEvent

class MusicWidgetReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        
        // 直接发送广播到MediaButtonReceiver
        val mediaButtonIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            // 指定目标组件为MediaButtonReceiver
            setClassName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            
            // 发送ACTION_DOWN事件
            when (action) {
                MusicPlayerWidget.ACTION_PLAY_PAUSE -> {
                    putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE))
                }
                MusicPlayerWidget.ACTION_PREVIOUS -> {
                    putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PREVIOUS))
                }
                MusicPlayerWidget.ACTION_NEXT -> {
                    putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_NEXT))
                }
            }
        }
        
        // 发送广播
        context.sendBroadcast(mediaButtonIntent)
        
        // 发送ACTION_UP事件，模拟完整的按键事件
        val mediaButtonUpIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClassName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            
            when (action) {
                MusicPlayerWidget.ACTION_PLAY_PAUSE -> {
                    putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE))
                }
                MusicPlayerWidget.ACTION_PREVIOUS -> {
                    putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PREVIOUS))
                }
                MusicPlayerWidget.ACTION_NEXT -> {
                    putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_NEXT))
                }
            }
        }
        
        // 发送UP事件广播
        context.sendBroadcast(mediaButtonUpIntent)
    }
}