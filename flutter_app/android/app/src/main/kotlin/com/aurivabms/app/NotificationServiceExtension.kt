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
import androidx.annotation.Keep
import androidx.core.app.NotificationCompat
import com.onesignal.notifications.INotificationReceivedEvent
import com.onesignal.notifications.INotificationServiceExtension
import com.aurivabms.app.R

@Keep
class NotificationServiceExtension : INotificationServiceExtension {
    override fun onNotificationReceived(event: INotificationReceivedEvent) {
        val context = event.context
        val notification = event.notification

        // We prevent the default OneSignal notification display
        event.preventDefault()

        // Create our Custom RemoteViews Layout
        val customView = RemoteViews(context.packageName, R.layout.custom_notification)
        customView.setTextViewText(R.id.custom_notif_title, notification.title ?: "Auriva BMS")
        customView.setTextViewText(R.id.custom_notif_message, notification.body ?: "")
        
        // Make the logo rounded
        val originalBitmap = BitmapFactory.decodeResource(context.resources, R.mipmap.launcher_icon)
        if (originalBitmap != null) {
            val roundedBitmap = getRoundedCornerBitmap(originalBitmap, 32) // Rounded radius ~8dp
            customView.setImageViewBitmap(R.id.custom_notif_icon, roundedBitmap)
        }
        
        // Progress can be updated dynamically if additionalData is provided from backend
        // e.g. customView.setProgressBar(R.id.custom_notif_progress, 100, 50, false)

        val channelId = "onesignal_custom_channel"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "Custom Notifications"
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH)
            notificationManager.createNotificationChannel(channel)
        }

        // Create Intent to launch app when custom notification is clicked
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(customView)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        notificationManager.notify(notification.notificationId.hashCode(), builder.build())
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
