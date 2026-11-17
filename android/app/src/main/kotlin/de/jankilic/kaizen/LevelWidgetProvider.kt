package de.jankilic.kaizen

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Bundle
import android.util.Base64
import android.widget.RemoteViews

class LevelWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        manager.updateAppWidget(ids, views(context))
    }

    companion object {
        private const val STORE = "launcher_level_widget"

        fun updateBadge(context: Context, rank: String, png: ByteArray) {
            // A launcher can ask for a new RemoteViews after reboot, before
            // Flutter has started. Persist the image and its description together.
            context.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit()
                .putString("description", "Kaizen · $rank")
                .putString("image", Base64.encodeToString(png, Base64.NO_WRAP))
                .apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, LevelWidgetProvider::class.java))
            if (ids.isNotEmpty()) manager.updateAppWidget(ids, views(context))
        }

        fun pin(context: Context): Boolean {
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            val preview = Bundle().apply {
                putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, views(context))
            }
            return manager.requestPinAppWidget(ComponentName(context, LevelWidgetProvider::class.java), preview, null)
        }

        private fun views(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            val view = RemoteViews(context.packageName, R.layout.level_widget)
            prefs.getString("image", null)?.let { encoded ->
                val png = Base64.decode(encoded, Base64.DEFAULT)
                val bitmap = BitmapFactory.decodeByteArray(png, 0, png.size)
                if (bitmap != null) view.setImageViewBitmap(R.id.level_badge, bitmap)
            }
            view.setContentDescription(R.id.open_level_widget,
                prefs.getString("description", "Kaizen · Rookie"))
            val launch = Intent.makeMainActivity(ComponentName(context, MainActivity::class.java))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
            val open = PendingIntent.getActivity(context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            view.setOnClickPendingIntent(R.id.open_level_widget, open)
            return view
        }
    }
}
