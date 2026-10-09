package com.example.apk_bcv

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class AppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val dolar = widgetData.getString("widget_dolar", "---")
                val euro = widgetData.getString("widget_euro", "---")
                val usdt = widgetData.getString("widget_usdt", "---")
                val fecha = widgetData.getString("widget_fecha", "--/--/----")

                setTextViewText(R.id.widget_dolar, dolar)
                setTextViewText(R.id.widget_euro, euro)
                setTextViewText(R.id.widget_usdt, usdt)
                setTextViewText(R.id.widget_fecha, "Actualización: $fecha")

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}