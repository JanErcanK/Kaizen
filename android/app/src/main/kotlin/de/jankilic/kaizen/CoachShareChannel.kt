package de.jankilic.kaizen

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors
import kotlin.math.ceil
import kotlin.math.min

/** Receives temporary URI grants; no broad photo/storage permission is needed. */
class CoachShareChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "de.jankilic.kaizen/coach_share")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val prefs = activity.getSharedPreferences("coach_share_inbox", 0)
    private val inbox = File(activity.filesDir, "coach_inbox").apply { mkdirs() }
    @Volatile private var closed = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pending" -> result.success(readQueue().toString())
                "acknowledge" -> {
                    val id = call.argument<String>("id") ?: ""
                    worker.execute {
                        val queue = readQueue()
                        val next = JSONArray()
                        for (i in 0 until queue.length()) {
                            val item = queue.getJSONObject(i)
                            if (item.optString("id") != id) next.put(item)
                            else {
                                val files = item.optJSONArray("files") ?: JSONArray()
                                for (j in 0 until files.length()) {
                                    val file = File(files.getJSONObject(j).getString("path"))
                                    if (file.canonicalFile.parentFile == inbox.canonicalFile) file.delete()
                                }
                            }
                        }
                        prefs.edit().putString("queue", next.toString()).commit()
                        main.post { result.success(null) }
                    }
                }
                "videoFrames" -> {
                    val path = call.argument<String>("path") ?: ""
                    val maxFrames = (call.argument<Int>("maxFrames") ?: 48).coerceIn(1, 48)
                    worker.execute {
                        try {
                            val frames = extractFrames(File(path), maxFrames)
                            main.post { result.success(frames) }
                        } catch (e: Exception) {
                            val code = if (e.message == "VIDEO_TOO_LONG") "VIDEO_TOO_LONG" else "VIDEO_UNREADABLE"
                            main.post { result.error(code, "Could not read this video", null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun readQueue(): JSONArray = try {
        JSONArray(prefs.getString("queue", "[]"))
    } catch (_: Exception) { JSONArray() }

    @Suppress("DEPRECATION")
    fun receive(intent: Intent) {
        if (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE) return
        // An intent reused by Android after rotation/recreation retains its ID.
        if (intent.hasExtra("kaizenShareHandled")) return
        intent.putExtra("kaizenShareHandled", true)
        val id = UUID.randomUUID().toString()
        val clip = intent.clipData
        val text = buildList {
            intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()?.let { add(it) }
            if (clip != null) {
                for (i in 0 until clip.itemCount) {
                    val entry = clip.getItemAt(i)
                    entry.text?.toString()?.let { add(it) }
                    entry.uri?.takeIf { it.scheme == "https" || it.scheme == "http" }
                        ?.toString()?.let { add(it) }
                }
            }
            intent.data?.takeIf { it.scheme == "https" || it.scheme == "http" }
                ?.toString()?.let { add(it) }
        }.distinct().joinToString("\n").take(8000)
        val mime = intent.type ?: ""
        val extraUris = if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.toList() ?: emptyList()
        } else listOfNotNull(intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))
        val uris = if (extraUris.isNotEmpty()) extraUris else {
            // A text share may carry a link or a thumbnail in ClipData. Neither
            // is a video attachment. EXTRA_STREAM remains authoritative.
            if (clip == null || mime.startsWith("text/")) emptyList() else
                (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
                    .filter { it.scheme == "content" }
        }
        worker.execute {
            val item = JSONObject().put("id", id).put("text", text).put("mime", mime)
            val files = JSONArray()
            try {
                require(uris.size <= 8 && !(mime.startsWith("video/") && uris.size > 1))
                for ((index, uri) in uris.withIndex()) {
                    require(uri.scheme == "content")
                    val actualType = activity.contentResolver.getType(uri) ?: mime
                    require(actualType.startsWith("video/") || actualType.startsWith("image/"))
                    val max = if (actualType.startsWith("video/")) 128L * 1024 * 1024 else 25L * 1024 * 1024
                    val file = File(inbox, "${id}_$index")
                    // Add before copying so failures also clean up partial files.
                    files.put(JSONObject().put("path", file.path).put("mime", actualType))
                    activity.contentResolver.openInputStream(uri).use { input ->
                        requireNotNull(input)
                        file.outputStream().use { output ->
                            val buffer = ByteArray(64 * 1024)
                            var total = 0L
                            while (true) {
                                val size = input.read(buffer)
                                if (size < 0) break
                                total += size
                                require(total <= max)
                                output.write(buffer, 0, size)
                            }
                        }
                    }
                }
                item.put("files", files)
            } catch (_: Exception) {
                for (i in 0 until files.length()) File(files.getJSONObject(i).getString("path")).delete()
                item.put("files", JSONArray()).put("error", "SHARE_UNREADABLE")
            }
            val queue = readQueue()
            queue.put(item)
            prefs.edit().putString("queue", queue.toString()).commit()
            main.post { if (!closed) channel.invokeMethod("changed", null) }
        }
    }

    private fun extractFrames(file: File, maxFrames: Int): Map<String, Any> {
        val canonical = file.canonicalFile
        val inInbox = canonical.parentFile == inbox.canonicalFile
        val inCache = canonical.path.startsWith(activity.cacheDir.canonicalPath + File.separator)
        require((inInbox || inCache) && canonical.isFile && canonical.length() <= 128L * 1024 * 1024)
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(canonical.path)
            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0
            require(duration > 0)
            if (duration > 180_000) throw IllegalArgumentException("VIDEO_TOO_LONG")
            val count = min(maxFrames, ceil(duration / 1000.0).toInt().coerceAtLeast(3))
            val frames = mutableListOf<Map<String, Any>>()
            for (i in 0 until count) {
                val timeMs = if (count == 1) 0L else i * (duration - 1) / (count - 1)
                val bitmap = retriever.getScaledFrameAtTime(timeMs * 1000, MediaMetadataRetriever.OPTION_CLOSEST, 768, 768) ?: continue
                val bytes = ByteArrayOutputStream()
                try { bitmap.compress(Bitmap.CompressFormat.JPEG, 75, bytes) } finally { bitmap.recycle() }
                frames.add(mapOf("bytes" to bytes.toByteArray(), "seconds" to timeMs / 1000.0))
            }
            require(frames.isNotEmpty())
            return mapOf("durationSeconds" to duration / 1000.0, "frames" to frames)
        } finally { retriever.release() }
    }

    fun close() {
        closed = true
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }
}
