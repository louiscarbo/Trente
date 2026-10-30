package app.trente.widgets

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column as ComposeColumn
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text as ComposeText
import androidx.compose.ui.unit.dp
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.action.actionStartActivity as actionStartActivityIntent
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.appwidget.updateAll
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.sp
import app.trente.AppContainer
import app.trente.MainActivity
import app.trente.appContainer
import app.trente.core.model.BudgetCategory
import app.trente.core.model.BudgetFigures
import app.trente.core.model.BudgetScope
import app.trente.core.model.Month
import app.trente.core.model.TrenteCalendar
import app.trente.core.services.DeepLink
import app.trente.core.services.MonthService
import app.trente.core.support.DateText
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import app.trente.ui.theme.TrenteTheme
import java.time.Instant
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** What a widget shows for the current month, like the iOS `WidgetMonth`. */
data class WidgetMonth(
    val id: java.util.UUID,
    val name: String,
    val currencyCode: String,
    val overall: BudgetFigures,
    val byCategory: Map<BudgetCategory, BudgetFigures>,
    val latestTransactions: List<WidgetTransaction>
) {
    fun figures(category: BudgetCategory): BudgetFigures = byCategory[category] ?: BudgetFigures.zero

    fun display(amount: Double): String = MoneyFormat.budget(amount, currencyCode)

    companion object {
        /** Reads the latest month on the main thread, counting due automatic transactions as recorded. */
        suspend fun current(container: AppContainer, now: Instant = Instant.now()): WidgetMonth? = withContext(Dispatchers.Main) {
            val store = container.loadStore()
            val month = MonthService.latestMonth(store) ?: return@withContext null
            val automaticRules = if (container.trentePlus.isSubscribed.value) store.rules.filter { it.autoConfirm } else emptyList()
            val due = automaticRules.flatMap { it.dueAutomaticOccurrences(month, now) }
            from(month, due)
        }

        fun from(month: Month, automaticOccurrences: List<app.trente.core.model.RecurringTransactionOccurrence>): WidgetMonth {
            val recorded = month.transactionGroups.map { it.addedDate to WidgetTransaction(it.title, it.entries.map { entry -> entry.category }, it.totalAmount) }
            val automatic = automaticOccurrences.map { occurrence ->
                occurrence.date to WidgetTransaction(
                    occurrence.rule.title,
                    BudgetCategory.entries.filter { occurrence.amountCents(BudgetScope.Category(it)) != 0 },
                    occurrence.amountCents / 100.0
                )
            }
            return WidgetMonth(
                id = month.id,
                name = month.name,
                currencyCode = month.currency.isoCode,
                overall = month.figures(BudgetScope.All, automaticOccurrences),
                byCategory = BudgetCategory.entries.associateWith { month.figures(BudgetScope.Category(it), automaticOccurrences) },
                latestTransactions = (recorded + automatic).sortedByDescending { it.first }.take(3).map { it.second }
            )
        }
    }
}

data class WidgetTransaction(val title: String, val categories: List<BudgetCategory>, val amount: Double)

/** Asks every widget to redraw, debounced, after the store changed. */
class WidgetRefresher(private val context: Context, private val scope: CoroutineScope) {
    private var job: Job? = null

    fun refresh() {
        job?.cancel()
        job = scope.launch {
            delay(1000)
            try {
                MonthRecapWidget().updateAll(context)
                CategoryRemainingWidget().updateAll(context)
            } catch (exception: Exception) {
                // No widget placed yet.
            }
        }
    }
}

private fun openApp(context: Context, link: DeepLink) =
    actionStartActivityIntent(Intent(context, MainActivity::class.java).apply { data = Uri.parse(link.url) })

private val green = ColorProvider(androidx.compose.ui.graphics.Color(0xFF34C759))
private val red = ColorProvider(androidx.compose.ui.graphics.Color(0xFFFF3B30))

/** "Month Recap": what's left this month, spending and the latest transactions on larger sizes. */
class MonthRecapWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Responsive(setOf(SMALL, MEDIUM, LARGE))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val month = WidgetMonth.current(context.appContainer)
        provideContent {
            GlanceTheme {
                val size = LocalSize.current
                MonthRecapContent(month, isMedium = size.width >= MEDIUM.width, isLarge = size.height >= LARGE.height)
            }
        }
    }

    companion object {
        val SMALL = DpSize(110.dp, 110.dp)
        val MEDIUM = DpSize(250.dp, 110.dp)
        val LARGE = DpSize(250.dp, 250.dp)
    }
}

@androidx.compose.runtime.Composable
private fun MonthRecapContent(month: WidgetMonth?, isMedium: Boolean, isLarge: Boolean) {
    val context = LocalContext.current
    val onSurface = GlanceTheme.colors.onSurface
    val secondary = GlanceTheme.colors.onSurfaceVariant
    Box(
        GlanceModifier.fillMaxSize().background(GlanceTheme.colors.widgetBackground).cornerRadius(24.dp).padding(16.dp)
            .let { if (month != null) it.clickable(openApp(context, DeepLink.Month(month.id))) else it.clickable(actionStartActivity<MainActivity>()) }
    ) {
        if (month == null) {
            Text(
                localized("Start tracking your budget with Trente by opening the app!"),
                style = TextStyle(color = secondary, fontSize = 13.sp),
                modifier = GlanceModifier.fillMaxSize()
            )
            return@Box
        }
        Column(GlanceModifier.fillMaxSize(), verticalAlignment = Alignment.Top) {
            Row(GlanceModifier.fillMaxWidth()) {
                Text(month.name, style = TextStyle(color = onSurface, fontSize = 15.sp, fontWeight = FontWeight.Bold))
                if (isMedium) {
                    Spacer(GlanceModifier.defaultWeight())
                    Text("Trente", style = TextStyle(color = secondary, fontSize = 13.sp))
                }
            }
            Spacer(GlanceModifier.height(8.dp))
            Row(GlanceModifier.fillMaxWidth()) {
                Column {
                    Text(localized("Remaining"), style = TextStyle(color = onSurface, fontSize = 13.sp))
                    Text(
                        month.display(month.overall.remaining),
                        style = TextStyle(color = if (month.overall.isOverspent) red else green, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                    )
                }
                Spacer(GlanceModifier.defaultWeight())
                if (isMedium) {
                    Column(horizontalAlignment = Alignment.End) {
                        Text(localized("Spent"), style = TextStyle(color = onSurface, fontSize = 13.sp))
                        Text(month.display(-month.overall.spent), style = TextStyle(color = red, fontSize = 22.sp, fontWeight = FontWeight.Bold))
                    }
                }
            }
            Spacer(GlanceModifier.defaultWeight())
            Row(GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                val now = TrenteCalendar.current.localDate(Instant.now())
                Text(DateText.dayMonthWide(now), style = TextStyle(color = secondary, fontSize = 12.sp))
                Spacer(GlanceModifier.defaultWeight())
                if (isMedium) {
                    Box(
                        GlanceModifier.background(onSurface).cornerRadius(20.dp).padding(horizontal = 12.dp, vertical = 6.dp)
                            .clickable(openApp(context, DeepLink.NewTransaction(month.id)))
                    ) {
                        Text("+ " + localized("New Transaction"), style = TextStyle(color = GlanceTheme.colors.surface, fontSize = 13.sp, fontWeight = FontWeight.Bold))
                    }
                }
            }
            if (isLarge) {
                Spacer(GlanceModifier.height(8.dp))
                if (month.latestTransactions.isEmpty()) {
                    Text(localized("Add your first transactions by tapping 'New Transaction'."), style = TextStyle(color = secondary, fontSize = 13.sp))
                } else {
                    month.latestTransactions.forEach { transaction ->
                        Row(GlanceModifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text(transaction.title, style = TextStyle(color = onSurface, fontSize = 14.sp, fontWeight = FontWeight.Medium))
                            Spacer(GlanceModifier.defaultWeight())
                            Text(MoneyFormat.amount(transaction.amount, month.currencyCode), style = TextStyle(color = onSurface, fontSize = 14.sp))
                        }
                    }
                }
            }
        }
    }
}

class MonthRecapWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MonthRecapWidget()
}

/** "Category Recap": what's left in one category, or in all three on the wide size. */
class CategoryRemainingWidget : GlanceAppWidget() {
    override val stateDefinition = PreferencesGlanceStateDefinition
    override val sizeMode = SizeMode.Responsive(setOf(MonthRecapWidget.SMALL, MonthRecapWidget.MEDIUM))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val month = WidgetMonth.current(context.appContainer)
        provideContent {
            GlanceTheme {
                val preferences = currentState<androidx.datastore.preferences.core.Preferences>()
                val category = preferences[CATEGORY_KEY]?.let(BudgetCategory::fromRawValue) ?: BudgetCategory.NEEDS
                val isMedium = LocalSize.current.width >= MonthRecapWidget.MEDIUM.width
                CategoryRemainingContent(month, category, isMedium)
            }
        }
    }

    companion object {
        val CATEGORY_KEY = stringPreferencesKey("category")
    }
}

@androidx.compose.runtime.Composable
private fun CategoryRemainingContent(month: WidgetMonth?, category: BudgetCategory, isMedium: Boolean) {
    val context = LocalContext.current
    val onSurface = GlanceTheme.colors.onSurface
    val secondary = GlanceTheme.colors.onSurfaceVariant
    Box(
        GlanceModifier.fillMaxSize().background(GlanceTheme.colors.widgetBackground).cornerRadius(24.dp).padding(12.dp)
            .clickable(if (month != null) openApp(context, DeepLink.Month(month.id)) else actionStartActivity<MainActivity>()),
        contentAlignment = Alignment.Center
    ) {
        if (month == null) {
            Text(localized("No month yet"), style = TextStyle(color = secondary, fontSize = 15.sp, fontWeight = FontWeight.Bold))
            return@Box
        }
        val categories = if (isMedium) BudgetCategory.entries else listOf(category)
        Row(GlanceModifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalAlignment = Alignment.CenterVertically) {
            categories.forEach { item ->
                val figures = month.figures(item)
                Column(GlanceModifier.defaultWeight(), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(item.shortName, style = TextStyle(color = secondary, fontSize = 13.sp, fontWeight = FontWeight.Bold))
                    Text(
                        month.display(figures.remaining),
                        style = TextStyle(color = if (figures.isOverspent) red else onSurface, fontSize = if (isMedium) 18.sp else 24.sp, fontWeight = FontWeight.Bold)
                    )
                    Text("/ " + month.display(figures.income), style = TextStyle(color = secondary, fontSize = 11.sp))
                }
            }
        }
    }
}

class CategoryRemainingWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CategoryRemainingWidget()
}

/** Picks the category of a "Category Recap" widget when it is added. */
class CategoryWidgetConfigureActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val appWidgetId = intent?.extras?.getInt(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID
        setResult(RESULT_CANCELED)
        if (appWidgetId == android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        setContent {
            TrenteTheme {
                ComposeColumn(
                    modifier = androidx.compose.ui.Modifier.fillMaxSize().padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp, androidx.compose.ui.Alignment.CenterVertically)
                ) {
                    ComposeText(localized("Select a category for the widget."), style = androidx.compose.material3.MaterialTheme.typography.titleMedium)
                    BudgetCategory.entries.forEach { category ->
                        Button(onClick = { select(appWidgetId, category) }, modifier = androidx.compose.ui.Modifier.fillMaxWidth()) {
                            ComposeText(category.displayName)
                        }
                    }
                }
            }
        }
    }

    private fun select(appWidgetId: Int, category: BudgetCategory) {
        val context = this
        kotlinx.coroutines.MainScope().launch {
            val glanceId = GlanceAppWidgetManager(context).getGlanceIdBy(appWidgetId)
            updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { preferences ->
                preferences.toMutablePreferences().apply { this[CategoryRemainingWidget.CATEGORY_KEY] = category.rawValue }
            }
            CategoryRemainingWidget().update(context, glanceId)
            setResult(RESULT_OK, Intent().putExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId))
            finish()
        }
    }
}
