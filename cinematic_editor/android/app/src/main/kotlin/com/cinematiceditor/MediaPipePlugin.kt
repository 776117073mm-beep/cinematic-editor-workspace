package com.cinematiceditor

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.imagesegmenter.ImageSegmenter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream

class MediaPipePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel : EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var imageSegmenter: ImageSegmenter? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    companion object { private const val TAG = "MediaPipePlugin" }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = binding
        methodChannel = MethodChannel(binding.binaryMessenger, "com.cinematiceditor/mediapipe")
        methodChannel.setMethodCallHandler(this)
        eventChannel  = EventChannel(binding.binaryMessenger, "com.cinematiceditor/mediapipe_progress")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(a: Any?, sink: EventChannel.EventSink) { eventSink = sink }
            override fun onCancel(a: Any?) { eventSink = null }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initializeSegmentation" -> initSeg(call, result)
            "segmentFrame"           -> segFrame(call, result)
            "startVideoSegmentation" -> startVideoSeg(call, result)
            "dispose"                -> { imageSegmenter?.close(); imageSegmenter = null; result.success(null) }
            else                     -> result.notImplemented()
        }
    }

    private fun initSeg(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                val baseOpts = BaseOptions.builder().setModelAssetPath("selfie_segmentation.tflite")
                try { baseOpts.setDelegate(com.google.mediapipe.tasks.core.Delegate.GPU) }
                catch (e: Exception) { Log.w(TAG, "GPU unavailable, using CPU") }

                val opts = ImageSegmenter.ImageSegmenterOptions.builder()
                    .setBaseOptions(baseOpts.build())
                    .setRunningMode(RunningMode.IMAGE)
                    .setOutputConfidenceMasks(true)
                    .build()

                imageSegmenter = ImageSegmenter.createFromOptions(
                    pluginBinding!!.applicationContext, opts
                )
                withContext(Dispatchers.Main) { result.success(true) }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { result.error("INIT_ERROR", e.message, null) }
            }
        }
    }

    private fun segFrame(call: MethodCall, result: MethodChannel.Result) {
        val seg = imageSegmenter ?: run {
            result.error("NOT_INIT", "Call initializeSegmentation first", null); return
        }
        scope.launch {
            try {
                val bytes  = call.argument<ByteArray>("frame")!!
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                val mpImg  = BitmapImageBuilder(bitmap).build()
                val segRes = seg.segment(mpImg)
                val masks  = segRes.confidenceMasks().orElse(null)
                if (masks.isNullOrEmpty()) {
                    withContext(Dispatchers.Main) { result.error("NO_MASK","No mask",null) }; return@launch
                }
                val maskBuf = masks[0].asFloat32Buffer()
                val w = bitmap.width; val h = bitmap.height
                val pixels = IntArray(w * h)
                bitmap.getPixels(pixels, 0, w, 0, 0, w, h)
                maskBuf.rewind()
                val maskArr = FloatArray(maskBuf.remaining()); maskBuf.get(maskArr)
                for (i in pixels.indices) {
                    val mv = if (i < maskArr.size) maskArr[i] else 0f
                    val alpha = when {
                        mv > 0.9f -> 255
                        mv > 0.5f -> ((mv - 0.5f) * 510).toInt().coerceIn(0, 255)
                        else      -> 0
                    }
                    pixels[i] = (alpha shl 24) or (pixels[i] and 0x00FFFFFF)
                }
                val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                out.setPixels(pixels, 0, w, 0, 0, w, h)
                val bos = ByteArrayOutputStream()
                out.compress(Bitmap.CompressFormat.PNG, 90, bos)
                bitmap.recycle(); out.recycle()
                withContext(Dispatchers.Main) { result.success(mapOf("processed_frame" to bos.toByteArray())) }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { result.error("SEG_ERROR", e.message, null) }
            }
        }
    }

    private fun startVideoSeg(call: MethodCall, result: MethodChannel.Result) {
        val inputPath  = call.argument<String>("input_path")!!
        val outputPath = call.argument<String>("output_path")!!
        scope.launch {
            try {
                // [PLACEHOLDER] تنفيذ معالجة الفيديو إطاراً بإطار هنا
                // لكل إطار: segFrame ثم حفظه وتجميع الفيديو
                withContext(Dispatchers.Main) {
                    eventSink?.success(mapOf("progress" to 1.0, "frames_processed" to 0, "total_frames" to 0))
                    result.success(true)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { result.error("VIDEO_SEG_ERROR", e.message, null) }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        scope.cancel()
        imageSegmenter?.close()
    }
}
