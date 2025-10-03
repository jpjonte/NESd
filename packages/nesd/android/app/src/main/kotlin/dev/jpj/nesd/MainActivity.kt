package dev.jpj.nesd

import android.content.Intent
import dev.jpj.nesd.filesystem.FilesystemMethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private lateinit var filesystemMethodChannel: FilesystemMethodChannel

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    filesystemMethodChannel =
      FilesystemMethodChannel(flutterEngine.dartExecutor.binaryMessenger, contentResolver, this)
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, resultData: Intent?) {
    filesystemMethodChannel.onActivityResult(requestCode, resultCode, resultData)
  }
}
