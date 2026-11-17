package de.jankilic.kaizen

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class LauncherIconChannel(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "de.jankilic.kaizen/launcher_icon")

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "setIcon" && call.method != "pinLevelIcon") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val alias = requireNotNull(call.argument<String>("alias"))
                require(alias.matches(Regex("LauncherLevel[0-9]+(En)?")))
                val rank = requireNotNull(call.argument<String>("rank"))
                val png = requireNotNull(call.argument<ByteArray>("badge"))
                val component = ComponentName(context, "${context.packageName}.$alias")
                selectLauncher(component)
                LevelWidgetProvider.updateBadge(context, rank, png)
                result.success(if (call.method == "pinLevelIcon") LevelWidgetProvider.pin(context) else null)
            } catch (error: Exception) {
                result.error("LAUNCHER_ICON_FAILED", error.message, null)
            }
        }
    }

    fun close() = channel.setMethodCallHandler(null)

    private fun selectLauncher(desired: ComponentName) {
        val manager = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            .setPackage(context.packageName)
        // This also finds an alias enabled by an older version of the app.
        val active = manager.queryIntentActivities(intent, 0)
            .map { it.activityInfo }
            .filter { it.targetActivity == LauncherActivity::class.java.name }
            .map { ComponentName(it.packageName, it.name) }
        val changes = buildList {
            if (desired !in active) add(desired to PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
            for (other in active) {
                if (other != desired) add(other to PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
            }
        }
        if (changes.isEmpty()) return
        val flags = PackageManager.DONT_KILL_APP
        if (Build.VERSION.SDK_INT >= 33) {
            manager.setComponentEnabledSettings(changes.map { (component, state) ->
                PackageManager.ComponentEnabledSetting(component, state, flags)
            })
        } else {
            // Enable first so an interrupted switch always leaves a launchable entry.
            for ((component, state) in changes) manager.setComponentEnabledSetting(component, state, flags)
        }
    }
}
