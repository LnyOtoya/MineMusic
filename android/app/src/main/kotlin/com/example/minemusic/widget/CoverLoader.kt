package com.example.minemusic.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.AppWidgetTarget
import com.bumptech.glide.request.transition.Transition
import com.example.minemusic.R

/**
 * 小部件封面加载工具
 * @param context 上下文
 * @param appWidgetId 小部件ID
 * @param remoteViews 小部件布局
 */
class CoverLoader(
    private val context: Context,
    private val appWidgetId: Int,
    private val remoteViews: RemoteViews
) {
    // Glide 适配小部件的 Target
    private val appWidgetTarget = object : AppWidgetTarget(context, R.id.iv_album_art, remoteViews, appWidgetId) {
        override fun onResourceReady(resource: android.graphics.Bitmap, transition: Transition<in android.graphics.Bitmap>?) {
            super.onResourceReady(resource, transition)
            // 加载完成后刷新小部件
            AppWidgetManager.getInstance(context).updateAppWidget(appWidgetId, remoteViews)
        }
    }

    /**
     * 加载封面图片
     * @param coverUrl 封面URL（Subsonic的coverArt地址）
     */
    fun loadCover(coverUrl: String?) {
        if (coverUrl.isNullOrEmpty()) {
            // 无封面时显示默认图
            remoteViews.setImageViewResource(R.id.iv_album_art, R.mipmap.launcher_icon)
            return
        }

        // 拼接完整的Subsonic封面URL（需带上认证参数）
        val fullCoverUrl = buildFullCoverUrl(coverUrl)

        // Glide 加载网络图片到小部件 ImageView
        Glide.with(context.applicationContext)
            .asBitmap()
            .load(fullCoverUrl)
            .error(R.mipmap.launcher_icon) // 加载失败显示默认图
            .into(appWidgetTarget)
    }

    /**
     * 拼接Subsonic封面的完整URL（带认证参数）
     * 你的Subsonic API需包含u=用户名&p=密码&v=1.16.1&c=MineMusic等参数
     */
    private fun buildFullCoverUrl(coverId: String): String {
        // 从SharedPreferences读取Subsonic配置（你需要提前保存）
        val sp = context.getSharedPreferences("subsonic_config", Context.MODE_PRIVATE)
        val baseUrl = sp.getString("base_url", "http://192.168.2.6:4533") ?: ""
        val username = sp.getString("username", "otoya") ?: ""
        val password = sp.getString("password", "486952") ?: ""

        // Subsonic coverArt API格式：{baseUrl}/rest/getCoverArt.view?id={coverId}&u={user}&p={pass}&v=1.16.1&c=MineMusic&f=json
        return "$baseUrl/rest/getCoverArt.view?id=$coverId&u=$username&p=$password&v=1.16.1&c=MineMusic&f=json"
    }
}