package com.example.expense_inbox

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object ExpenseStorage {

    private const val FILE_NAME = "expense_notifications.json"

    private fun extractAmount(message: String?): Double {
        if (message == null) return 0.0

        // Matches:
        // Rs.500
        // Rs 500
        // INR 500
        // ₹500
        val regex = Regex("""(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d+)?)""")

        val match = regex.find(message)

        return match?.groupValues
            ?.get(1)
            ?.replace(",", "")
            ?.toDoubleOrNull()
            ?: 0.0
    }

    fun saveNotification(
        context: Context,
        packageName: String,
        sender: String?,
        message: String?
    ) {

        val file = File(context.filesDir, FILE_NAME)

        val jsonArray =
            if (file.exists()) {
                JSONArray(file.readText())
            } else {
                JSONArray()
            }

        val item = JSONObject().apply {
            put("id", System.currentTimeMillis())
            put("packageName", packageName)
            put("sender", sender ?: "")
            put("message", message ?: "")
            put("timestamp", System.currentTimeMillis())

            // New fields
            put("amount", extractAmount(message))
            put("reviewed", false)
            put("type", "")
            put("category", "")
        }

        jsonArray.put(item)

        file.writeText(jsonArray.toString())
    }
}