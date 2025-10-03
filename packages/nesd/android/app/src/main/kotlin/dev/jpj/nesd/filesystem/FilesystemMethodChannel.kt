package dev.jpj.nesd.filesystem

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import androidx.core.net.toUri
import dev.jpj.nesd.MainActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class FilesystemMethodChannel(
  binaryMessenger: BinaryMessenger,
  contentResolver: ContentResolver,
  private val mainActivity: MainActivity,
) : MethodCallHandler {
  companion object {
    private const val CHANNEL = "nesd.jpj.dev/filesystem"
    private const val REQUEST_CODE_CHOOSE_DIRECTORY = 1
  }

  init {
    MethodChannel(binaryMessenger, CHANNEL).setMethodCallHandler(this)
  }

  private val filesystem = FilesystemService(contentResolver)

  private var directoryResult: MethodChannel.Result? = null

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val arguments = call.arguments<Map<String, String>>() ?: mapOf()

    when (call.method) {
      "exists" -> {
        exists(arguments, result)
      }

      "isFile" -> {
        isFile(arguments, result)
      }

      "isDirectory" -> {
        isDirectory(arguments, result)
      }

      "hasPermission" -> {
        hasPermission(arguments, result)
      }

      "read" -> {
        read(arguments, result)
      }

      "chooseDirectory" -> {
        chooseDirectory(arguments, result)
      }

      "list" -> {
        list(arguments, result)
      }

      "parent" -> {
        parent(arguments, result)
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  fun onActivityResult(requestCode: Int, resultCode: Int, resultData: Intent?) {
    if (directoryResult == null) {
      return
    }

    when (requestCode) {
      REQUEST_CODE_CHOOSE_DIRECTORY -> {
        handleChooseDirectoryResult(resultCode, resultData)
      }
    }
  }

  private fun exists(
    arguments: Map<String, String>, result: MethodChannel.Result
  ) {
    expectPath(arguments, result) { uri -> filesystem.exists(uri) }
  }

  private fun isFile(
    arguments: Map<String, String>, result: MethodChannel.Result
  ) {
    expectPath(arguments, result) { uri -> filesystem.isFile(uri) }
  }

  private fun isDirectory(
    arguments: Map<String, String>, result: MethodChannel.Result
  ) {
    expectPath(arguments, result) { uri -> filesystem.isDirectory(uri) }
  }

  private fun hasPermission(
    arguments: Map<String, String>, result: MethodChannel.Result
  ) {
    expectPath(arguments, result) { uri -> filesystem.hasPermission(uri) }
  }

  private fun read(
    arguments: Map<String, String>, result: MethodChannel.Result
  ) {
    expectPath(arguments, result) { uri -> filesystem.read(uri) }
  }

  private fun chooseDirectory(
    arguments: Map<String, String>, result: MethodChannel.Result
  ) {
    if (directoryResult != null) {
      return
    }

    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
      addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val initialDirectory = arguments["initialDirectory"]

        putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialDirectory)
      }
    }

    this.directoryResult = result

    mainActivity.startActivityForResult(intent, REQUEST_CODE_CHOOSE_DIRECTORY)
  }

  private fun list(
    arguments: Map<String, String>, result: MethodChannel.Result
  ) {
    expectPath(arguments, result) { uri -> filesystem.list(mainActivity, uri) }
  }

  private fun parent(
    arguments: Map<String, String>, result: MethodChannel.Result
  ) {
    expectPath(arguments, result) { uri -> filesystem.parent(mainActivity, uri) }
  }

  private fun handleChooseDirectoryResult(resultCode: Int, resultData: Intent?) {
    if (directoryResult == null) {
      return
    }

    when (resultCode) {
      Activity.RESULT_OK -> resultData?.data?.also { uri ->
        filesystem.persistPermission(uri)

        val path = uri.toString()
        val name = filesystem.getDisplayName(mainActivity, uri)

        directoryResult?.success(
          mapOf(
            "path" to path,
            "name" to name,
          )
        )
      }

      Activity.RESULT_CANCELED -> {
        directoryResult?.success(null)
      }

      else -> {
        directoryResult?.error(
          "internal_error",
          "Activity finished with result code $resultCode",
          null,
        )
      }
    }

    directoryResult = null
  }

  private fun expectPath(
    arguments: Map<String, String>,
    result: MethodChannel.Result,
    callback: (uri: Uri) -> Any,
  ) {
    val path = arguments["path"]

    if (path == null) {
      result.error("missing_argument", "Missing argument path", null)

      return
    }

    val uri = path.toUri()

    try {
      val value = callback(uri)
      result.success(value)
    } catch (e: Exception) {
      result.error("internal_error", "Internal error: ${e.message}", null)
    }
  }
}