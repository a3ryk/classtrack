package com.attendly

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.content.Intent
import android.net.Uri
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import android.view.animation.PathInterpolator
import androidx.core.content.FileProvider
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.attendly/package_installer"
    private val SPLASH_CHANNEL = "com.attendly/splash"
    private var isAppReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)

        // Enable edge-to-edge system bars and transparent status/nav bars
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        // Extend into display cutout area (punch-hole / notch) without letterboxing
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }

        val startTime = System.currentTimeMillis()
        splashScreen.setKeepOnScreenCondition {
            val elapsed = System.currentTimeMillis() - startTime
            !isAppReady && (elapsed < 5000)
        }

        splashScreen.setOnExitAnimationListener { splashScreenViewProvider ->
            val splashView = splashScreenViewProvider.view
            val iconView = splashScreenViewProvider.iconView

            // Hardware-accelerated smooth zoom + fade out on Android compositor layer
            val scaleX = ObjectAnimator.ofFloat(iconView, View.SCALE_X, 1.0f, 1.25f)
            val scaleY = ObjectAnimator.ofFloat(iconView, View.SCALE_Y, 1.0f, 1.25f)
            val alpha = ObjectAnimator.ofFloat(splashView, View.ALPHA, 1.0f, 0.0f)

            AnimatorSet().apply {
                duration = 320L
                interpolator = PathInterpolator(0.2f, 0.0f, 0.0f, 1.0f)
                playTogether(scaleX, scaleY, alpha)
                addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        splashScreenViewProvider.remove()
                    }
                })
                start()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPLASH_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "dismissSplash") {
                isAppReady = true
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val success = installApk(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_PATH", "File path was null", null)
                    }
                }
                "getSupportedAbis" -> {
                    val abis = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        Build.SUPPORTED_ABIS.toList()
                    } else {
                        listOf(Build.CPU_ABI, Build.CPU_ABI2).filterNotNull()
                    }
                    result.success(abis)
                }
                "canRequestPackageInstalls" -> {
                    val canInstall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(canInstall)
                }
                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = Uri.parse("package:${applicationContext.packageName}")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false

            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileProvider",
                    file
                )
            } else {
                Uri.fromFile(file)
            }

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
