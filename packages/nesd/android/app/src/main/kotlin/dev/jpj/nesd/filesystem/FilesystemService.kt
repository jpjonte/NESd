package dev.jpj.nesd.filesystem

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.core.provider.DocumentsContractCompat

class FilesystemService(private val contentResolver: ContentResolver) {
  fun exists(uri: Uri): Boolean {
    var cursor: Cursor? = null

    try {
      cursor = contentResolver.query(
        uri,
        arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
        null,
        null,
        null,
      )

      if (cursor == null) {
        throw IllegalStateException("Cursor is null")
      }

      return cursor.count > 0
    } finally {
      cursor?.close()
    }
  }

  fun isFile(uri: Uri): Boolean {
    return getDocumentProperty(
      uri,
      DocumentsContract.Document.COLUMN_MIME_TYPE
    ) != DocumentsContract.Document.MIME_TYPE_DIR
  }

  fun isDirectory(uri: Uri): Boolean {
    val directoryUri = DocumentsContract.buildDocumentUriUsingTree(
      uri, DocumentsContract.getTreeDocumentId(uri)
    )

    return getDocumentProperty(
      directoryUri,
      DocumentsContract.Document.COLUMN_MIME_TYPE
    ) == DocumentsContract.Document.MIME_TYPE_DIR
  }

  fun hasPermission(uri: Uri): Boolean {
    val permissions = contentResolver.persistedUriPermissions

    return permissions.any { permission ->
      permission.uri == uri && permission.isReadPermission
    }
  }

  fun read(uri: Uri): ByteArray {
    val inputStream = uri.let { contentResolver.openInputStream(it) }

    if (inputStream == null) {
      throw Exception("File not openable")
    }

    return inputStream.readBytes()
  }

  fun list(context: Context, uri: Uri): List<Map<String, *>> {
    var cursor: Cursor? = null

    val parentId =
      if (DocumentsContract.isDocumentUri(context, uri)) DocumentsContract.getDocumentId(uri)
      else DocumentsContract.getTreeDocumentId(uri)
    val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
      uri,
      parentId,
    )

    try {
      cursor = contentResolver.query(
        childrenUri,
        arrayOf(
          DocumentsContract.Document.COLUMN_DOCUMENT_ID,
          DocumentsContract.Document.COLUMN_MIME_TYPE,
        ),
        null,
        null,
        null,
      )

      if (cursor == null) {
        throw IllegalStateException("Cursor is null")
      }

      val files = mutableListOf<Map<String, String>>()

      while (cursor.moveToNext()) {
        val id = cursor.getString(0)
        val mimeType = cursor.getString(1)
        val childUri = DocumentsContract.buildDocumentUriUsingTree(uri, id)

        files.add(
          mapOf(
            "path" to childUri.toString(),
            "type" to if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) "directory"
            else "file",
            "name" to id,
          )
        )
      }

      return files
    } finally {
      cursor?.close()
    }
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  fun savePicture(name: String, directory: String, bytes: ByteArray): String {
    val collection =
      MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

    val values = ContentValues().apply {
      put(MediaStore.Images.Media.DISPLAY_NAME, name)
      put(MediaStore.Images.Media.MIME_TYPE, "image/png")
      put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$directory")
      put(MediaStore.Images.Media.IS_PENDING, 1)
    }

    val uri = contentResolver.insert(collection, values)
      ?: throw IllegalStateException("MediaStore insert failed")

    try {
      val outputStream = contentResolver.openOutputStream(uri)
        ?: throw IllegalStateException("Cannot open $uri for writing")

      outputStream.use { it.write(bytes) }
    } catch (e: Exception) {
      contentResolver.delete(uri, null, null)

      throw e
    }

    values.clear()
    values.put(MediaStore.Images.Media.IS_PENDING, 0)
    contentResolver.update(uri, values, null, null)

    return getDisplayName(uri) ?: name
  }

  private fun getDisplayName(uri: Uri): String? {
    contentResolver.query(uri, arrayOf(MediaStore.Images.Media.DISPLAY_NAME), null, null, null)
      .use { cursor ->
        if (cursor == null || !cursor.moveToFirst()) {
          return null
        }

        return cursor.getString(0)
      }
  }

  fun persistPermission(uri: Uri) {
    contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
  }

  fun getDisplayName(context: Context, uri: Uri): String? {
    if (DocumentsContract.isDocumentUri(context, uri)) {
      return DocumentsContract.getDocumentId(uri)
    }

    return DocumentsContract.getTreeDocumentId(uri)
  }

  fun parent(context: Context, uri: Uri): Map<String, String> {
    val documentId =
      if (DocumentsContract.isDocumentUri(context, uri)) DocumentsContract.getDocumentId(uri)
      else DocumentsContract.getTreeDocumentId(uri)

    val treeId = if (DocumentsContractCompat.isTreeUri(uri))
      DocumentsContract.getTreeDocumentId(uri)
    else
      ""

    val parentId = if (documentId.length > treeId.length)
      documentId.substringBeforeLast("/")
    else
      documentId

    val parentUri = DocumentsContract.buildDocumentUriUsingTree(uri, parentId)

    val path = parentUri.toString()

    val name = getDisplayName(context, parentUri) ?: path

    return mapOf(
      "path" to path,
      "type" to "directory",
      "name" to name,
    )
  }

  private fun getDocumentProperty(uri: Uri, property: String): String? {
    var cursor: Cursor? = null

    try {
      cursor = contentResolver.query(
        uri, arrayOf(property), null, null, null
      )

      if (cursor == null) {
        throw IllegalStateException("Cursor is null")
      }

      if (cursor.moveToNext()) {
        return cursor.getString(0)
      }

      return null
    } finally {
      cursor?.close()
    }
  }
}