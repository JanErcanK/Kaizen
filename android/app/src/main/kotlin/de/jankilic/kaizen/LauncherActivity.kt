package de.jankilic.kaizen

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle

/** Keep the Flutter task independent of the rank alias Android may disable. */
class LauncherActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val main = Intent.makeMainActivity(ComponentName(this, MainActivity::class.java))
        main.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
        startActivity(main)
        finish()
    }
}
