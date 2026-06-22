package com.example.expense_inbox

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import android.widget.Toast

class NotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {

        // Only listen to Google Messages notifications
        if (sbn.packageName != "com.google.android.apps.messaging") {
            return
        }

        val extras = sbn.notification.extras

        val title = extras.getString("android.title")
        val text = extras.getCharSequence("android.text")?.toString()

        // Ignore empty notifications
        if (title.isNullOrBlank() || text.isNullOrBlank()) {
            return
        }

        val lowerText = text.lowercase()

        // Ignore non-financial messages
        if (
            !lowerText.contains("rs") &&
            !lowerText.contains("₹") &&
            !lowerText.contains("credited") &&
            !lowerText.contains("debited") &&
            !lowerText.contains("upi") &&
            !lowerText.contains("spent")
        ) {
            return
        }

        ExpenseStorage.saveNotification(
            applicationContext,
            sbn.packageName,
            title,
            text
        )

        Log.d("ExpenseInbox", "BANK SMS SAVED")
        Log.d("ExpenseInbox", "Title: $title")
        Log.d("ExpenseInbox", "Text: $text")

        Toast.makeText(
            applicationContext,
            "Transaction Captured",
            Toast.LENGTH_SHORT
        ).show()
    }
}