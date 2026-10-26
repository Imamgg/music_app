package com.auno.app.auno

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (!flutterEngine.plugins.has(AudioEffectsPlugin::class.java)) {
            flutterEngine.plugins.add(AudioEffectsPlugin())
        }
    }
}

class AudioEffectsPlugin : io.flutter.embedding.engine.plugins.FlutterPlugin {
    private var equalizer: Equalizer? = null
    private var bass: BassBoost? = null
    private var session: Int? = null

    private var channel: MethodChannel? = null
    override fun onAttachedToEngine(binding: io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "auno/audio_effects")
        channel!!.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "attach" -> {
                        val id = call.argument<Int>("session")
                        if (id != session || (equalizer == null && bass == null)) {
                            releaseEffects()
                            if (id != null && id > 0) {
                                session = id
                                equalizer = try { Equalizer(0, id) } catch (_: Exception) { null }
                                bass = try { BassBoost(0, id) } catch (_: Exception) { null }
                            }
                        }
                        val eq = equalizer
                        result.success(mapOf(
                            "frequencies" to (eq?.let { e -> (0 until e.numberOfBands.toInt()).map { e.getCenterFreq(it.toShort()) / 1000.0 } } ?: emptyList<Double>()),
                            "min" to (eq?.bandLevelRange?.get(0)?.toDouble()?.div(100) ?: -15.0),
                            "max" to (eq?.bandLevelRange?.get(1)?.toDouble()?.div(100) ?: 15.0),
                            "bassSupported" to (bass?.strengthSupported == true)
                        ))
                    }
                    "apply" -> {
                        if (call.argument<Int>("session") != session) { result.success(false); return@setMethodCallHandler }
                        val enabled = call.argument<Boolean>("enabled") == true
                        equalizer?.let { eq ->
                            val gains = call.argument<List<Number>>("gains") ?: emptyList()
                            gains.take(eq.numberOfBands.toInt()).forEachIndexed { index, gain ->
                                val level = (gain.toDouble() * 100).toInt().coerceIn(eq.bandLevelRange[0].toInt(), eq.bandLevelRange[1].toInt())
                                eq.setBandLevel(index.toShort(), level.toShort())
                            }
                            eq.enabled = enabled
                        }
                        bass?.let { effect ->
                            val strength = (call.argument<Number>("bass")?.toDouble() ?: 0.0).toInt().coerceIn(0, 1000)
                            if (effect.strengthSupported) effect.setStrength(strength.toShort())
                            effect.enabled = enabled && effect.strengthSupported && strength > 0
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("AUDIO_EFFECT", "Audio effects unavailable", null)
            }
        }
    }

    private fun releaseEffects() {
        equalizer?.release()
        bass?.release()
        equalizer = null
        bass = null
        session = null
    }

    override fun onDetachedFromEngine(binding: io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        releaseEffects()
    }
}
