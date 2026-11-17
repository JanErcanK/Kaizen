package de.jankilic.kaizen

import android.app.Activity
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.util.Locale

/** Accessible from Health Connect's permission rationale / privacy entry. */
class HealthPrivacyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val german = Locale.getDefault().language == "de"
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val inset = (24 * resources.displayMetrics.density).toInt()
            setPadding(inset, inset, inset, inset)
        }
        val title = if (german) "Gesundheitsdaten in Kaizen" else "Health data in Kaizen"
        content.addView(TextView(this).apply { text = title; textSize = 24f })
        content.addView(TextView(this).apply {
            textSize = 16f
            text = if (german) "\nKaizen liest nur die von dir freigegebenen Bereiche: Schlaf, Schritte, Aktivitätskalorien, Trainings, Ruhepuls, Herzfrequenzvariabilität und Gewicht.\n\nDamit zeigt dein Profil persönliche Verläufe der letzten 28 Tage. Die Daten werden beim Öffnen des Profils oder auf deinen Wunsch aktualisiert.\n\nDie importierten Verläufe werden lokal gespeichert und nicht automatisch an KI-Dienste oder Freunde gesendet. Kaizen schreibt keine Gesundheitsdaten zurück und verändert keine Originaldaten.\n\nDu kannst einzelne Freigaben jederzeit in Health Connect → App-Berechtigungen → Kaizen widerrufen. Im Profil unter Deine Gesundheit → Verbindung & Datenschutz kannst du den Import stoppen und die lokalen Verläufe löschen. Die Originaldaten bleiben erhalten."
            else "\nKaizen reads only the categories you allow: sleep, steps, active calories, workouts, resting heart rate, heart rate variability and weight.\n\nYour profile uses them to show personal trends for the last 28 days. Data refreshes when you open your profile or request an update.\n\nImported trends are stored locally and are not automatically sent to AI services or friends. Kaizen does not write health data or modify the originals.\n\nRevoke individual permissions in Health Connect → App permissions → Kaizen. In your profile, open Your health → Connection & privacy to stop importing and clear local trends. Original data remains intact."
        })
        content.addView(Button(this).apply { text = if (german) "Zurück" else "Back"; setOnClickListener { finish() } })
        setContentView(ScrollView(this).apply { addView(content) })
    }
}
