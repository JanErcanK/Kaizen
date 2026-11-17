package de.jankilic.kaizen

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs

class MainActivity : FlutterFragmentActivity() {
    private var healthDashboardChannel: HealthDashboardChannel? = null
    private var coachShareChannel: CoachShareChannel? = null
    private var launcherIconChannel: LauncherIconChannel? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        // Motorola razr 60 ultra (leap), Android 16 / Adreno 0800.46:
        // captured Kaizen SIGSEGVs in vulkan.adreno.so::vkBeginCommandBuffer
        // and vkCmdDraw on Flutter's raster thread. Use Skia/OpenGL on this
        // device until that driver path is verified again. Set the argument
        // before FlutterFragmentActivity creates/initializes its engine.
        if (Build.MANUFACTURER.equals("motorola", ignoreCase = true) &&
            Build.DEVICE == "leap"
        ) {
            intent.putExtra(FlutterShellArgs.ARG_KEY_TOGGLE_IMPELLER, false)
            Log.i("KaizenRenderer", "Using Skia/OpenGL for Motorola leap")
        }
        super.onCreate(savedInstanceState)
        coachShareChannel?.receive(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        coachShareChannel?.receive(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        coachShareChannel?.close()
        coachShareChannel = CoachShareChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        // FlutterFragment is attached asynchronously after onCreate on a cold
        // launch. Deliver the launch share when its channel actually exists.
        // receive() deduplicates the onCreate/configureFlutterEngine paths.
        coachShareChannel?.receive(intent)
        healthDashboardChannel?.close()
        healthDashboardChannel = HealthDashboardChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        launcherIconChannel?.close()
        launcherIconChannel = LauncherIconChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        coachShareChannel?.close()
        coachShareChannel = null
        healthDashboardChannel?.close()
        healthDashboardChannel = null
        launcherIconChannel?.close()
        launcherIconChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
