package com.fasobiblio.app

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.fasobiblio.app/downloads"
    private val requestWrite = 4971
    private var pendingExport: Triple<String, String, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method != "saveToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            val name = call.argument<String>("name")
            if (path.isNullOrBlank() || name.isNullOrBlank() || !File(path).isFile) {
                result.error("INVALID_FILE", "Le fichier à exporter est introuvable.", null)
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q && checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                pendingExport = Triple(path, name, result)
                requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), requestWrite)
            } else {
                saveToDownloads(path, name, result)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != requestWrite) return
        val export = pendingExport ?: return
        pendingExport = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            saveToDownloads(export.first, export.second, export.third)
        } else {
            export.third.error("PERMISSION_DENIED", "Autorisez l’accès aux fichiers pour enregistrer le PDF.", null)
        }
    }

    private fun saveToDownloads(sourcePath: String, displayName: String, result: MethodChannel.Result) {
        Thread {
            try {
                val source = File(sourcePath)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val values = ContentValues().apply {
                        put(MediaStore.Downloads.DISPLAY_NAME, displayName)
                        put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                        put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Fasobiblio")
                        put(MediaStore.Downloads.IS_PENDING, 1)
                    }
                    val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                        ?: throw IllegalStateException("Impossible de créer le fichier dans Téléchargements.")
                    try {
                        contentResolver.openOutputStream(uri)?.use { output ->
                            FileInputStream(source).use { input -> input.copyTo(output) }
                        } ?: throw IllegalStateException("Impossible d’écrire le fichier.")
                        values.clear()
                        values.put(MediaStore.Downloads.IS_PENDING, 0)
                        contentResolver.update(uri, values, null, null)
                    } catch (error: Throwable) {
                        contentResolver.delete(uri, null, null)
                        throw error
                    }
                } else {
                    val folder = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Fasobiblio")
                    if (!folder.exists() && !folder.mkdirs()) throw IllegalStateException("Impossible de créer le dossier Fasobiblio.")
                    var target = File(folder, displayName)
                    if (target.exists()) target = File(folder, "${System.currentTimeMillis()}-$displayName")
                    FileInputStream(source).use { input -> FileOutputStream(target).use { output -> input.copyTo(output) } }
                    MediaScannerConnection.scanFile(this, arrayOf(target.absolutePath), arrayOf("application/pdf"), null)
                }
                runOnUiThread { result.success("Download/Fasobiblio/$displayName") }
            } catch (error: Throwable) {
                runOnUiThread { result.error("EXPORT_FAILED", error.message ?: "Échec de l’enregistrement.", null) }
            }
        }.start()
    }
}
