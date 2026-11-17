package de.jankilic.kaizen

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** The health plugin's workout reader additionally requires distance, total
 * calories and steps. This narrow reader only needs READ_EXERCISE. */
class HealthDashboardChannel(context: Context, messenger: BinaryMessenger) {
    private val appContext = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val channel = MethodChannel(messenger, "de.jankilic.kaizen/health_dashboard")

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "readWorkouts") {
                result.notImplemented()
            } else {
                val start = call.argument<Number>("start")?.toLong()
                val end = call.argument<Number>("end")?.toLong()
                if (start == null || end == null || start >= end) {
                    result.error("INVALID_RANGE", "Invalid date range", null)
                } else scope.launch {
                    try {
                        val client = HealthConnectClient.getOrCreate(appContext)
                        val records = mutableListOf<Map<String, Any>>()
                        var token: String? = null
                        do {
                            val page = client.readRecords(ReadRecordsRequest(
                                recordType = ExerciseSessionRecord::class,
                                timeRangeFilter = TimeRangeFilter.between(Instant.ofEpochMilli(start), Instant.ofEpochMilli(end)),
                                pageToken = token,
                            ))
                            for (record in page.records) {
                                val origin = record.metadata.dataOrigin.packageName
                                val source = try {
                                    val info = appContext.packageManager.getApplicationInfo(origin, 0)
                                    appContext.packageManager.getApplicationLabel(info).toString()
                                } catch (_: Exception) { origin }
                                records.add(mapOf(
                                    "id" to record.metadata.id,
                                    "sourceId" to origin,
                                    "source" to source,
                                    "start" to record.startTime.toEpochMilli(),
                                    "end" to record.endTime.toEpochMilli(),
                                ))
                            }
                            token = page.pageToken
                        } while (token != null)
                        result.success(records)
                    } catch (_: SecurityException) {
                        result.error("PERMISSION_DENIED", "Workout access is not granted", null)
                    } catch (_: Exception) {
                        result.error("HEALTH_READ_FAILED", "Workouts could not be read", null)
                    }
                }
            }
        }
    }

    fun close() { channel.setMethodCallHandler(null); scope.cancel() }
}
