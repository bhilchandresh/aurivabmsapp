package com.aurivabms.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.widget.RemoteViews
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.aurivabms.app/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showCustomNotification") {
                val title = call.argument<String>("title") ?: "AurivaBMS"
                val body = call.argument<String>("body") ?: ""
                val chipText = call.argument<String>("chipText")
                val illustrationPath = call.argument<String>("illustrationPath")
                val id = call.argument<Int>("id") ?: System.currentTimeMillis().toInt()
                
                showCustomNotification(title, body, chipText, illustrationPath, id)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.aurivabms.app/communications").setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSMS" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")
                    if (phone != null && message != null) {
                        try {
                            val smsManager = android.telephony.SmsManager.getDefault()
                            smsManager.sendTextMessage(phone, null, message, null, null)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Phone or message is null", null)
                    }
                }
                "makeCall" -> {
                    val phone = call.argument<String>("phone")
                    if (phone != null) {
                        try {
                            val intent = android.content.Intent(android.content.Intent.ACTION_CALL)
                            intent.data = android.net.Uri.parse("tel:$phone")
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CALL_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Phone is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showCustomNotification(title: String, body: String, chipText: String?, illustrationPath: String?, notificationId: Int) {
        val customView = RemoteViews(packageName, R.layout.custom_notification)
        customView.setTextViewText(R.id.custom_notif_title, title)
        customView.setTextViewText(R.id.custom_notif_message, body)
        
        if (chipText != null && chipText.isNotEmpty()) {
            customView.setViewVisibility(R.id.custom_notif_chip, android.view.View.VISIBLE)
            customView.setTextViewText(R.id.custom_notif_chip_text, chipText)
        } else {
            customView.setViewVisibility(R.id.custom_notif_chip, android.view.View.GONE)
        }
        
        if (illustrationPath != null && illustrationPath.isNotEmpty()) {
            val bitmap = BitmapFactory.decodeFile(illustrationPath)
            if (bitmap != null) {
                customView.setViewVisibility(R.id.custom_notif_illustration, android.view.View.VISIBLE)
                customView.setImageViewBitmap(R.id.custom_notif_illustration, bitmap)
            } else {
                customView.setViewVisibility(R.id.custom_notif_illustration, android.view.View.GONE)
            }
        } else {
            customView.setViewVisibility(R.id.custom_notif_illustration, android.view.View.GONE)
        }
        
        val originalBitmap = BitmapFactory.decodeResource(resources, R.mipmap.launcher_icon)
        if (originalBitmap != null) {
            val roundedBitmap = getRoundedCornerBitmap(originalBitmap, 32)
            customView.setImageViewBitmap(R.id.custom_notif_icon, roundedBitmap)
        }
        
        val channelId = "onesignal_custom_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "Custom Notifications"
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH)
            notificationManager.createNotificationChannel(channel)
        }

        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(customView)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        notificationManager.notify(notificationId, builder.build())
    }

    private fun getRoundedCornerBitmap(bitmap: Bitmap, pixels: Int): Bitmap {
        val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val color = -0xbdbdbe
        val paint = Paint()
        val rect = Rect(0, 0, bitmap.width, bitmap.height)
        val rectF = RectF(rect)
        val roundPx = pixels.toFloat()

        paint.isAntiAlias = true
        canvas.drawARGB(0, 0, 0, 0)
        paint.color = color
        canvas.drawRoundRect(rectF, roundPx, roundPx, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(bitmap, rect, rect, paint)
        return output
    }
}
