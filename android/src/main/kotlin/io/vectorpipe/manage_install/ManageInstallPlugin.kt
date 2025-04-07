package io.vectorpipe.manage_install

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.File
import java.lang.ref.WeakReference

/** ManageInstallPlugin */
class ManageInstallPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel

    private var channelResult: MethodChannel.Result? = null
    private var context: Context? = null
    private var activityReference = WeakReference<Activity>(null)
    private val activity
        get() = activityReference.get()

    private val REQUEST_CODE_PERMISSION_OR_INSTALL = 1024

    private var apkFilePath = ""
    private var hasPermission = false

    /////////////////////
    /// FlutterPlugin ///
    /////////////////////
    /**
     * Called when the plugin is attached to the Flutter engine
     * @param flutterPluginBinding Binding containing context and messenger
     */
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "manage_install")
        channel.setMethodCallHandler(this)
    }

    /**
     * Handles method calls from Flutter
     * @param call Contains the method called and its arguments
     * @param result Callback to send the result back to Flutter
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        channelResult = result
        if (call.method == "installApk") {
            val filePath = call.argument<String>("filePath")
            val appId = call.argument<String>("appId")
            Log.i("ManageInstall", "onMethodCall('installApk', '$appId', '$filePath')")
            installApk(filePath, appId)
        } else {
            result.notImplemented()
        }
    }

    /**
     * Called when the plugin is detached from the Flutter engine
     * @param binding Binding containing context
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = null
        channel.setMethodCallHandler(null)
        channelResult = null
    }

    /////////////////////
    /// ActivityAware ///
    /////////////////////

    /**
     * Called when the plugin is attached to an Activity Sets up the activity reference and result
     * listener
     * @param binding Provides access to the Activity and lifecycle methods
     */
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityReference = WeakReference(binding.activity)
        binding.addActivityResultListener { requestCode, resultCode, data ->
            return@addActivityResultListener handleActivityResult(requestCode, resultCode, data)
        }
    }

    /**
     * Called when configuration changes occur and plugin is detached from Activity Clears the
     * activity reference to prevent memory leaks
     */
    override fun onDetachedFromActivityForConfigChanges() {
        activityReference.clear()
    }

    /**
     * Called after configuration changes when plugin is reattached to Activity Resets the activity
     * reference and result listener
     * @param binding New ActivityPluginBinding after configuration change
     */
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityReference = WeakReference(binding.activity)
        binding.addActivityResultListener { requestCode, resultCode, data ->
            return@addActivityResultListener handleActivityResult(requestCode, resultCode, data)
        }
    }

    /**
     * Called when plugin is detached from Activity Clears the activity reference to prevent memory
     * leaks
     */
    override fun onDetachedFromActivity() {
        activityReference.clear()
    }

    //////////////////////
    /// plugin methods ///
    //////////////////////

    /**
     * Initiates the APK installation process
     * @param filePath Path to the APK file to install
     * @param packageName Application package name
     */
    private fun installApk(filePath: String?, packageName: String?) {
        if (filePath.isNullOrEmpty()) {
            channelResult?.success(
                SaveResultModel(
                    false,
                    "[ManageInstall] 'installApk' called with empty argument 'filePath'."
                )
                    .toHashMap()
            )
            return
        }

        apkFilePath = filePath
        val pName =
            if (packageName.isNullOrEmpty()) {
                context?.packageName
            } else {
                packageName
            }

        if (pName.isNullOrEmpty()) {
            channelResult?.success(
                SaveResultModel(
                    false,
                    "[ManageInstall] 'installApk' called with empty argument 'packageName'."
                )
                    .toHashMap()
            )
            return
        }
        if (hasInstallPermission()) {
            hasPermission = true
            // begin install
            val intent = getInstallAppIntent(context, pName, filePath)
            if (intent == null) {
                channelResult?.success(
                    SaveResultModel(
                        false,
                        "[ManageInstall] APK installation could not be initialized. 'intent' with null value."
                    )
                        .toHashMap()
                )
                return
            }

            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            intent.putExtra(Intent.EXTRA_RETURN_RESULT, true)
            activity?.startActivityForResult(intent, REQUEST_CODE_PERMISSION_OR_INSTALL)
        } else {
            hasPermission = false
            requestInstallPermission(pName)
        }
    }

    /**
     * Creates the Intent for app installation
     * @param context Application context
     * @param packageName Package name
     * @param filePath APK file path
     * @return Configured Intent for installation or null if error
     */
    private fun getInstallAppIntent(
        context: Context?,
        packageName: String,
        filePath: String?
    ): Intent? {
        if (context == null) return null
        if (filePath.isNullOrEmpty()) return null

        var file = File(filePath)
        if (!file.exists()) return null

        Log.i("ManageInstall", "getInstallAppIntent:${Build.VERSION.SDK_INT}")

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.M) {
            val storePath =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    .absolutePath

            // DIRECTORY_DOWNLOADS
            val downloadsDir = File(storePath).apply { if (!exists()) mkdir() }

            // DIRECTORY_DOWNLOADS / packageName
            val downloadsAppDir = File(downloadsDir, packageName).apply { if (!exists()) mkdir() }

            Log.i("ManageInstall", "getInstallAppIntent:$storePath")
            val destFile = File(downloadsAppDir, file.name)
            file.copyTo(destFile, overwrite = true)
            file = destFile
        }

        val uri: Uri =
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                Uri.fromFile(file)
            } else {
                InstallFileProvider.getUriForFile(context, file)
            }

        Log.i("ManageInstall", "getInstallAppIntent:$uri")
        val intent = Intent(Intent.ACTION_VIEW)
        val type = "application/vnd.android.package-archive"
        intent.setDataAndType(uri, type)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
            intent.flags = Intent.FLAG_GRANT_READ_URI_PERMISSION

        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)

        return intent
    }

    /**
     * Handles the result from installation activity
     * @param requestCode Request code
     * @param resultCode Activity result
     * @param data Intent with additional data
     * @return true if result was handled, false otherwise
     */
    private fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.i("ManageInstall", """
        handleActivityResult:
        requestCode: $requestCode
        resultCode: $resultCode
        data extras: ${data?.extras?.keySet()?.joinToString(", ") { "$it: ${data.extras?.get(it)}" }}
        data data: ${data?.data}
        data flags: ${data?.flags}
        data action: ${data?.action}
        data type: ${data?.type}
    """.trimIndent())
        if (requestCode == REQUEST_CODE_PERMISSION_OR_INSTALL) {
            if (resultCode == Activity.RESULT_OK) {
                if (hasPermission) {
                    channelResult?.success(SaveResultModel(true, "[ManageInstall] Installation complete!").toHashMap())
                } else {
                    installApk(apkFilePath, "")
                }
            } else {
                if (hasPermission) {
                    channelResult?.success(
                        SaveResultModel(false, "[ManageInstall] Installation failed or was cancelled by sistem.").toHashMap()
                    )
                } else {
                    channelResult?.success(
                        SaveResultModel(false, "[ManageInstall] Fail to request permissions.").toHashMap()
                    )
                }
            }
            return true
        }
        return false
    }

    /**
     * Checks if the app has permissions to install APKs
     * @return true if has permissions, false otherwise
     */
    private fun hasInstallPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context?.packageManager?.canRequestPackageInstalls() ?: false
        } else {
            return true
        }
    }

    /**
     * Requests permissions to install APKs
     * @param packageName Package name requiring permission
     */
    private fun requestInstallPermission(packageName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
            intent.data = Uri.parse("package:$packageName")
            activity?.startActivityForResult(intent, REQUEST_CODE_PERMISSION_OR_INSTALL)
        }
    }
}

/**
 * Model to handle operation results
 * @property isSuccess Indicates if the operation was successful
 * @property message Message which gives an status message about the operation
 */
class SaveResultModel(private var isSuccess: Boolean, private var message: String? = null) {
    /**
     * Converts the model to a HashMap
     * @return HashMap with results
     */
    fun toHashMap(): HashMap<String, Any?> {
        val hashMap = HashMap<String, Any?>()
        hashMap["isSuccess"] = isSuccess
        hashMap["message"] = message
        return hashMap
    }
}

/** Custom provider to handle installation files */
class InstallFileProvider : FileProvider() {
    companion object {
        /**
         * Retrieve the uri for a file stored into system
         * @param context Application context
         * @param file File for which uri is needed
         * @return Uri of the file
         */
        fun getUriForFile(context: Context, file: File): Uri {
            val authority = "${context.packageName}.installFileProvider.install"
            return getUriForFile(context, authority, file)
        }
    }
}
