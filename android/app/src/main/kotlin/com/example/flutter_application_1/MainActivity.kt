package com.example.flutter_application_1

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		requestNotificationPermissionIfNeeded()
		ReminderScheduler.scheduleDailyReminder(applicationContext)
		applyEdgeToEdge()
	}

	override fun onWindowFocusChanged(hasFocus: Boolean) {
		super.onWindowFocusChanged(hasFocus)
		if (hasFocus) {
			applyEdgeToEdge()
		}
	}

	private fun applyEdgeToEdge() {
		WindowCompat.setDecorFitsSystemWindows(window, false)
		val controller = WindowInsetsControllerCompat(window, window.decorView)
		controller.systemBarsBehavior =
			WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
		controller.hide(WindowInsetsCompat.Type.systemBars())
	}

	private fun requestNotificationPermissionIfNeeded() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
			return
		}

		val hasPermission = ContextCompat.checkSelfPermission(
			this,
			Manifest.permission.POST_NOTIFICATIONS,
		) == PackageManager.PERMISSION_GRANTED

		if (!hasPermission) {
			ActivityCompat.requestPermissions(
				this,
				arrayOf(Manifest.permission.POST_NOTIFICATIONS),
				1001,
			)
		}
	}
}
