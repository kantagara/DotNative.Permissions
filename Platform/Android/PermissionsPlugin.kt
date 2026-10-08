package com.dotnative.plugins

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build

class PermissionsPlugin(private val activity: Activity) {
    private data class Request(val permission: String, val reply: PluginReply)
    private val pending = mutableMapOf<Int, Request>()
    private val asked = mutableSetOf<String>()
    private var nextCode = 50000
    private val permissionListener: (Int, Array<String>, IntArray) -> Boolean = { code, permissions, grants ->
        val request = pending.remove(code)
        if (request == null) false else {
            val granted = grants.firstOrNull() == PackageManager.PERMISSION_GRANTED
            val permanent = !granted && asked.contains(request.permission) &&
                !activity.shouldShowRequestPermissionRationale(request.permission)
            request.reply.success(if (granted) "granted" else if (permanent) "permanentlyDenied" else "denied")
            true
        }
    }

    init {
        NativeChannels.permissionResultListeners.add(permissionListener)
        val channel = NativeChannels.channel(PermissionsChannel)
        channel.onDetach = {
            NativeChannels.permissionResultListeners.remove(permissionListener)
            pending.values.forEach { it.reply.cancel() }
            pending.clear()
        }
        channel.handle("check") { args, reply -> status(kind(args), reply) }
        channel.handle("request") { args, reply -> request(kind(args), reply) }
    }

    private fun kind(args: Any?): String {
        val value = (args as? Map<*, *>)?.get("permission") as? String ?: error("Expected permission name")
        require(value in setOf("camera", "microphone", "location", "notifications")) { "Unsupported permission" }
        return value
    }

    private fun manifestPermission(kind: String): String = when (kind) {
        "camera" -> Manifest.permission.CAMERA
        "microphone" -> Manifest.permission.RECORD_AUDIO
        "location" -> Manifest.permission.ACCESS_FINE_LOCATION
        "notifications" -> if (Build.VERSION.SDK_INT >= 33) "android.permission.POST_NOTIFICATIONS" else ""
        else -> error("Unsupported permission")
    }

    private fun status(kind: String, reply: PluginReply) {
        val permission = manifestPermission(kind)
        if (permission.isEmpty() || Build.VERSION.SDK_INT < 23) { reply.success("granted"); return }
        if (activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            reply.success("granted")
        } else {
            val permanent = asked.contains(permission) && !activity.shouldShowRequestPermissionRationale(permission)
            reply.success(if (permanent) "permanentlyDenied" else "denied")
        }
    }

    private fun request(kind: String, reply: PluginReply) {
        val permission = manifestPermission(kind)
        if (permission.isEmpty() || Build.VERSION.SDK_INT < 23) { reply.success("granted"); return }
        if (activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            reply.success("granted")
            return
        }
        if (nextCode > 65535) {
            reply.failure("busy", "Permission request identifiers are exhausted")
            return
        }
        val code = nextCode++
        pending[code] = Request(permission, reply)
        asked.add(permission)
        reply.onCancel = { pending.remove(code) }
        try { activity.requestPermissions(arrayOf(permission), code) }
        catch (error: Exception) {
            pending.remove(code)
            reply.failure("permission_unavailable", error.message ?: "Could not request permission")
        }
    }
}
