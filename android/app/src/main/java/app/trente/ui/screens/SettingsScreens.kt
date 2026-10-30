package app.trente.ui.screens

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PrivacyTip
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TableChart
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.trente.BuildConfig
import app.trente.R
import app.trente.core.model.BudgetCategory
import app.trente.core.model.CreditSection
import app.trente.core.model.DeveloperProfile
import app.trente.core.model.TrentePlusBenefit
import app.trente.core.presentation.OnboardingModel
import app.trente.core.services.TrentePlusDebugOverride
import app.trente.core.services.export.ExportMonthOption
import app.trente.core.services.export.ExportSelection
import app.trente.core.services.export.TransactionCSVFormat
import app.trente.core.services.notifications.NotificationPreferences
import app.trente.core.services.notifications.ReminderTime
import app.trente.core.support.AppInfo
import app.trente.core.support.ExternalLinks
import app.trente.core.support.FAQItem
import app.trente.core.support.FAQSection
import app.trente.core.support.Localization
import app.trente.core.support.NotificationPermissionStatus
import app.trente.core.support.SupportMail
import app.trente.core.support.localized
import app.trente.data.AndroidStrings
import app.trente.notifications.notificationSettingsIntent
import app.trente.ui.LocalAppContainer
import app.trente.ui.LocalShowPaywall
import app.trente.ui.Routes
import app.trente.ui.components.BottomBarBackground
import app.trente.ui.components.CloseStyle
import app.trente.ui.components.ExportButton
import app.trente.ui.components.ExternalLinkRow
import app.trente.ui.components.ProportionalBar
import app.trente.ui.components.RequiresTrentePlus
import app.trente.ui.components.RowDivider
import app.trente.ui.components.Sticker
import app.trente.ui.components.TrenteCard
import app.trente.ui.components.TrenteListBackground
import app.trente.ui.components.TrentePrimaryButton
import app.trente.ui.components.TrenteSecondaryButton
import app.trente.ui.components.TrenteToggle
import app.trente.ui.components.TrenteTopBar
import app.trente.ui.dataVersion
import app.trente.ui.isTrentePlusSubscribed
import app.trente.ui.rememberStore
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import app.trente.ui.theme.color
import java.util.UUID
import kotlinx.coroutines.launch

/** A plural from the generated resources, falling back to the key. */
fun pluralized(key: String, count: Int): String =
    (Localization.provider as? AndroidStrings)?.plural(key, count) ?: localized(key, count)

fun openUrl(context: Context, url: String) {
    try {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    } catch (exception: Exception) {
        // No browser.
    }
}

fun appInfo(context: Context): AppInfo = AppInfo(
    version = BuildConfig.VERSION_NAME,
    build = BuildConfig.VERSION_CODE.toString(),
    systemName = "Android",
    systemVersion = android.os.Build.VERSION.RELEASE ?: "?"
)

/** The alternate launcher icons, flipped through activity aliases. */
enum class AppIcon(val alias: String, val title: String, val preview: Int) {
    GREEN("Green", "Green", R.mipmap.ic_launcher_green),
    MINT("Mint", "Mint", R.mipmap.ic_launcher_mint),
    TEAL("Teal", "Teal", R.mipmap.ic_launcher_teal),
    BLUE("Blue", "Blue", R.mipmap.ic_launcher_blue),
    MIDNIGHT("Midnight", "Midnight", R.mipmap.ic_launcher_midnight),
    PURPLE("Purple", "Purple", R.mipmap.ic_launcher_purple),
    PINK("Pink", "Pink", R.mipmap.ic_launcher_pink),
    RED("Red", "Red", R.mipmap.ic_launcher_red),
    ORANGE("Orange", "Orange", R.mipmap.ic_launcher_orange),
    YELLOW("Yellow", "Yellow", R.mipmap.ic_launcher_yellow),
    GREY("Grey", "Gray", R.mipmap.ic_launcher_grey),
    BLACK("Black", "Black", R.mipmap.ic_launcher_black);

    fun component(context: Context) = ComponentName(context, "app.trente.icon.$alias")

    companion object {
        fun current(context: Context): AppIcon {
            val manager = context.packageManager
            return entries.firstOrNull { icon ->
                val state = manager.getComponentEnabledSetting(icon.component(context))
                state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED || (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && icon == GREEN)
            } ?: GREEN
        }

        fun apply(context: Context, icon: AppIcon) {
            val manager = context.packageManager
            entries.forEach { candidate ->
                manager.setComponentEnabledSetting(
                    candidate.component(context),
                    if (candidate == icon) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
        }
    }
}

@Composable
private fun SettingsRow(title: String, icon: androidx.compose.ui.graphics.vector.ImageVector, value: String? = null, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(22.dp))
        Spacer(Modifier.width(12.dp))
        Text(title, style = TrenteType.body, modifier = Modifier.weight(1f))
        if (value != null) Text(value, style = TrenteType.body, color = TrenteColors.secondaryText)
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = TrenteColors.secondaryText)
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text.uppercase(), style = TrenteType.footnote, color = TrenteColors.secondaryText, modifier = Modifier.padding(start = 16.dp, top = 8.dp))
}

@Composable
private fun Footer(text: String) {
    Text(text, style = TrenteType.footnote, color = TrenteColors.secondaryText, modifier = Modifier.padding(horizontal = 16.dp))
}

/** Settings: Trente+, app icon, notifications, data, help and about, like `SettingsView`. */
@Composable
fun SettingsScreen(onClose: () -> Unit, onOpen: (String) -> Unit, onReplayOnboarding: () -> Unit) {
    val context = LocalContext.current
    val container = LocalAppContainer.current
    val isSubscribed = isTrentePlusSubscribed()
    val showPaywall = LocalShowPaywall.current
    var permissionStatus by remember { mutableStateOf<NotificationPermissionStatus?>(null) }
    LaunchedEffect(Unit) { permissionStatus = container.notificationPermission.status() }
    var currentIcon by remember { mutableStateOf(AppIcon.current(context)) }

    Scaffold(topBar = { TrenteTopBar(title = localized("Settings"), onBack = onClose, closeStyle = CloseStyle.CLOSE) }) { padding ->
        LazyColumn(contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = padding.calculateTopPadding() + 8.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            item {
                TrenteListBackground {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                            Sticker(R.drawable.sticker_pig, modifier = Modifier.width(64.dp))
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text("Trente+", style = TrenteType.headline)
                                if (isSubscribed) {
                                    Text(localized("You have access to all Trente+ benefits. Thanks for subscribing!"), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                                } else {
                                    TrentePlusBenefit.all.forEach { benefit ->
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = TrenteColors.secondaryText, modifier = Modifier.size(16.dp))
                                            Spacer(Modifier.width(6.dp))
                                            Text(localized(benefit.title), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                                        }
                                    }
                                }
                            }
                        }
                        if (isSubscribed) {
                            TrenteSecondaryButton(text = localized("Manage Subscription"), onClick = { openUrl(context, ExternalLinks.manageSubscriptions) })
                        } else {
                            TrentePrimaryButton(text = localized("See Plans"), onClick = showPaywall)
                        }
                    }
                }
            }
            item { SectionTitle(localized("App Icon")) }
            item {
                TrenteListBackground {
                    RequiresTrentePlus(isSubscribed = isSubscribed, onShowPaywall = showPaywall) {
                        LazyRow(contentPadding = PaddingValues(12.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            items(AppIcon.entries.size) { index ->
                                val icon = AppIcon.entries[index]
                                val isSelected = icon == currentIcon
                                Column(
                                    Modifier.width(76.dp).clickable {
                                        AppIcon.apply(context, icon)
                                        currentIcon = icon
                                    },
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    verticalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Box {
                                        Image(painterResource(icon.preview), contentDescription = null, modifier = Modifier.size(60.dp).clip(RoundedCornerShape(14.dp)))
                                        if (isSelected) {
                                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.align(Alignment.BottomEnd).size(22.dp))
                                        }
                                    }
                                    Text(localized(icon.title), style = TrenteType.caption, color = if (isSelected) MaterialTheme.colorScheme.onSurface else TrenteColors.secondaryText)
                                }
                            }
                        }
                    }
                }
            }
            item {
                TrenteListBackground {
                    SettingsRow(
                        title = localized("Notifications"),
                        icon = Icons.Default.Notifications,
                        value = when (permissionStatus) {
                            null -> null
                            NotificationPermissionStatus.AUTHORIZED -> localized("On")
                            else -> localized("Off")
                        },
                        onClick = { onOpen(Routes.NOTIFICATIONS) }
                    )
                }
            }
            item { SectionTitle(localized("Your Data")) }
            item {
                TrenteListBackground {
                    SettingsRow(title = localized("Export Transactions"), icon = Icons.Default.TableChart, onClick = { onOpen(Routes.EXPORT) })
                }
            }
            item { Footer(localized("Your months and transactions stay on this device. Trente has no account and no server. You can export them as a spreadsheet anytime.")) }
            item { SectionTitle(localized("Help & About")) }
            item {
                TrenteListBackground {
                    SettingsRow(title = localized("Frequently Asked Questions"), icon = Icons.Default.HelpOutline, onClick = { onOpen(Routes.FAQ) })
                    RowDivider()
                    ExternalLinkRow(title = localized("Rate on Google Play"), icon = Icons.Default.Star, onClick = { openUrl(context, ExternalLinks.writeReview) })
                    RowDivider()
                    SettingsRow(title = localized("About the Developer"), icon = Icons.Default.Person, onClick = { onOpen(Routes.ABOUT) })
                    RowDivider()
                    SettingsRow(title = localized("Credits"), icon = Icons.Default.Favorite, onClick = { onOpen(Routes.CREDITS) })
                    RowDivider()
                    ExternalLinkRow(title = localized("Privacy Policy"), icon = Icons.Default.PrivacyTip, onClick = { openUrl(context, ExternalLinks.privacyPolicy) })
                    RowDivider()
                    ExternalLinkRow(title = localized("Terms of Use"), icon = Icons.Default.Description, onClick = { openUrl(context, ExternalLinks.termsOfUse) })
                }
            }
            item {
                Text("Trente ${appInfo(context).versionDescription}", style = TrenteType.footnote, color = TrenteColors.secondaryText, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(top = 18.dp))
            }
            if (BuildConfig.DEBUG) {
                item { SectionTitle(localized("Debug")) }
                item {
                    TrenteListBackground {
                        SettingsRow(title = localized("Onboarding"), icon = Icons.Default.Star, onClick = { onClose(); onReplayOnboarding() })
                        RowDivider()
                        Column(Modifier.padding(16.dp)) {
                            Text("Trente+", style = TrenteType.body)
                            TrentePlusDebugOverride.entries.forEach { override ->
                                TrenteToggle(
                                    checked = container.trentePlus.debugOverride == override,
                                    onCheckedChange = { container.trentePlus.debugOverride = override },
                                    modifier = Modifier.padding(vertical = 6.dp)
                                ) {
                                    Text(
                                        when (override) {
                                            TrentePlusDebugOverride.STORE -> localized("App Store")
                                            TrentePlusDebugOverride.SUBSCRIBED -> localized("Subscribed")
                                            TrentePlusDebugOverride.NOT_SUBSCRIBED -> localized("Not Subscribed")
                                        },
                                        style = TrenteType.body
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/** Permission status, the two reminder toggles and the reminder time, like `NotificationSettingsView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationSettingsScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    var status by remember { mutableStateOf<NotificationPermissionStatus?>(null) }
    var preferences by remember { mutableStateOf(NotificationPreferences.stored(container.preferences)) }
    var reminderTime by remember { mutableStateOf(ReminderTime.stored(container.preferences)) }
    var isPickingTime by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { status = container.notificationPermission.status() }

    fun updatePreferences(block: NotificationPreferences.() -> NotificationPreferences) {
        preferences = preferences.block()
        preferences.store(container.preferences)
        container.notificationScheduler.scheduleSoon()
    }

    Scaffold(topBar = { TrenteTopBar(title = localized("Notifications"), onBack = onBack) }) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            TrenteListBackground {
                when (status) {
                    null -> Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
                    NotificationPermissionStatus.NOT_DETERMINED -> Column(Modifier.padding(16.dp)) {
                        TrentePrimaryButton(text = localized("Turn On Notifications"), icon = Icons.Default.Notifications, narrow = true, onClick = {
                            scope.launch { status = container.notificationPermission.requestIfNeeded() }
                        })
                    }
                    NotificationPermissionStatus.DENIED -> Column {
                        Row(Modifier.padding(16.dp)) {
                            Text(localized("Status"), style = TrenteType.body, modifier = Modifier.weight(1f))
                            Text(localized("Off"), style = TrenteType.body, color = TrenteColors.secondaryText)
                        }
                        RowDivider()
                        ExternalLinkRow(title = localized("Open Settings"), icon = Icons.Default.Notifications, onClick = { context.startActivity(notificationSettingsIntent(context)) })
                    }
                    NotificationPermissionStatus.AUTHORIZED -> Column {
                        Row(Modifier.padding(16.dp)) {
                            Text(localized("Status"), style = TrenteType.body, modifier = Modifier.weight(1f))
                            Text(localized("On"), style = TrenteType.body, color = TrenteColors.secondaryText)
                        }
                        RowDivider()
                        ExternalLinkRow(title = localized("Notification Settings"), icon = Icons.Default.Notifications, onClick = { context.startActivity(notificationSettingsIntent(context)) })
                    }
                }
            }
            if (status == NotificationPermissionStatus.NOT_DETERMINED || status == NotificationPermissionStatus.DENIED) {
                Footer(localized("Get a reminder when a new month starts and when a recurring transaction is due."))
            }
            if (status == NotificationPermissionStatus.AUTHORIZED) {
                SectionTitle(localized("Reminders"))
                TrenteListBackground {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(localized("Recurring Transactions"), style = TrenteType.body, modifier = Modifier.weight(1f))
                        Switch(checked = preferences.remindsRecurringTransactions, onCheckedChange = { checked -> updatePreferences { copy(remindsRecurringTransactions = checked) } })
                    }
                    RowDivider()
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(localized("New Month"), style = TrenteType.body, modifier = Modifier.weight(1f))
                        Switch(checked = preferences.announcesNewMonths, onCheckedChange = { checked -> updatePreferences { copy(announcesNewMonths = checked) } })
                    }
                    RowDivider()
                    Row(
                        Modifier.fillMaxWidth().clickable(enabled = preferences.usesReminderTime) { isPickingTime = true }.padding(16.dp).alpha(if (preferences.usesReminderTime) 1f else 0.5f),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(localized("Reminder Time"), style = TrenteType.body, modifier = Modifier.weight(1f))
                        Text(String.format("%02d:%02d", reminderTime.hour, reminderTime.minute), style = TrenteType.body, color = TrenteColors.secondaryText)
                    }
                }
                Footer(
                    when {
                        preferences.remindsRecurringTransactions && preferences.announcesNewMonths -> localized("Trente reminds you at this time when a new month starts and when a recurring transaction is due.")
                        preferences.remindsRecurringTransactions -> localized("Trente reminds you at this time when a recurring transaction is due.")
                        preferences.announcesNewMonths -> localized("Trente reminds you at this time when a new month starts.")
                        else -> localized("Turn on a reminder to choose when Trente notifies you.")
                    }
                )
            }
        }
    }
    if (isPickingTime) {
        val state = rememberTimePickerState(initialHour = reminderTime.hour, initialMinute = reminderTime.minute)
        AlertDialog(
            onDismissRequest = { isPickingTime = false },
            title = { Text(localized("Reminder Time")) },
            text = { TimePicker(state = state) },
            confirmButton = {
                TextButton(onClick = {
                    reminderTime = ReminderTime(state.hour, state.minute)
                    reminderTime.store(container.preferences)
                    container.notificationScheduler.scheduleSoon()
                    isPickingTime = false
                }) { Text(localized("Done")) }
            },
            dismissButton = { TextButton(onClick = { isPickingTime = false }) { Text(localized("Cancel")) } }
        )
    }
}

/** Which months are excluded from the export; shared by the two export screens. */
class ExportSelectionState {
    var excludedMonthIDs by mutableStateOf(setOf<UUID>())
}

/** Choose the months, notes and images, then export, like `TransactionExportView`. */
@Composable
fun TransactionExportScreen(state: ExportSelectionState, onBack: () -> Unit, onSelectMonths: () -> Unit) {
    val store = rememberStore() ?: return
    val container = LocalAppContainer.current
    val version = dataVersion()
    var includesNotes by remember { mutableStateOf(container.preferences.getBoolean(TransactionCSVFormat.INCLUDES_NOTES_KEY) ?: true) }
    var includesImages by remember { mutableStateOf(container.preferences.getBoolean(TransactionCSVFormat.INCLUDES_IMAGES_KEY) ?: true) }
    val options = remember(version) { store.months.sortedByDescending { it.startDate }.map { ExportMonthOption.from(it) } }
    val monthIDsWithImages = remember(version) { store.months.filter { month -> month.transactionGroups.any { it.hasImageAttachment } }.map { it.id }.toSet() }
    val selection = ExportSelection(
        options = options,
        excludedMonthIDs = state.excludedMonthIDs,
        monthIDsWithImages = monthIDsWithImages,
        format = TransactionCSVFormat(style = TransactionCSVFormat.Style.current, includesNotes = includesNotes, includesImages = includesImages)
    )
    val file = selection.file

    Scaffold(
        topBar = { TrenteTopBar(title = localized("Export Transactions"), onBack = onBack) },
        bottomBar = {
            BottomBarBackground {
                Box(Modifier.navigationBarsPadding().padding(16.dp)) {
                    ExportButton(
                    title = pluralized("Export ^[%lld Transaction](inflect: true)", selection.transactionCount),
                        file = file,
                        store = store,
                        enabled = selection.transactionCount > 0
                    )
                }
            }
        }
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionTitle(localized("What to Export"))
            TrenteListBackground {
                SettingsRow(
                    title = localized("Months"),
                    icon = Icons.Default.TableChart,
                    value = if (selection.includesEveryMonth) localized("All Months") else pluralized("^[%lld Month](inflect: true)", selection.selectedOptions.size),
                    onClick = onSelectMonths
                )
            }
            SectionTitle(localized("File"))
            TrenteListBackground {
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(localized("Include Notes"), style = TrenteType.body, modifier = Modifier.weight(1f))
                    Switch(checked = includesNotes, onCheckedChange = { includesNotes = it; container.preferences.putBoolean(TransactionCSVFormat.INCLUDES_NOTES_KEY, it) })
                }
                if (file.hasImages) {
                    RowDivider()
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(localized("Include Images"), style = TrenteType.body, modifier = Modifier.weight(1f))
                        Switch(checked = includesImages, onCheckedChange = { includesImages = it; container.preferences.putBoolean(TransactionCSVFormat.INCLUDES_IMAGES_KEY, it) })
                    }
                }
            }
            if (file.includesImages) {
                Footer(localized("Images are saved next to the spreadsheet in a .zip file."))
            }
        }
    }
}


/** Tick the months to export, grouped by year, like `ExportMonthSelectionView`. */
@Composable
fun ExportMonthSelectionScreen(state: ExportSelectionState, onBack: () -> Unit) {
    val store = rememberStore() ?: return
    val version = dataVersion()
    val options = remember(version) { store.months.sortedByDescending { it.startDate }.map { ExportMonthOption.from(it) } }
    val groups = remember(options) { ExportMonthOption.groupedByYear(options) }
    Scaffold(
        topBar = {
            TrenteTopBar(title = localized("Months"), onBack = onBack) {
                TextButton(onClick = {
                    state.excludedMonthIDs = if (state.excludedMonthIDs.isEmpty()) options.map { it.id }.toSet() else emptySet()
                }) { Text(if (state.excludedMonthIDs.isEmpty()) localized("Deselect All") else localized("Select All")) }
            }
        }
    ) { padding ->
        LazyColumn(contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = padding.calculateTopPadding() + 8.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            groups.forEach { group ->
                item { SectionTitle(group.year.toString()) }
                item {
                    TrenteListBackground {
                        group.options.forEachIndexed { index, option ->
                            val isSelected = option.id !in state.excludedMonthIDs
                            Row(
                                Modifier.fillMaxWidth().clickable {
                                    state.excludedMonthIDs = if (isSelected) state.excludedMonthIDs + option.id else state.excludedMonthIDs - option.id
                                }.padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(Modifier.weight(1f)) {
                                    Text(option.name, style = TrenteType.body)
                                    Text(pluralized("^[%lld transaction](inflect: true)", option.transactionCount), style = TrenteType.footnote, color = TrenteColors.secondaryText)
                                }
                                Icon(
                                    if (isSelected) Icons.Default.CheckCircle else Icons.Outlined.Circle,
                                    contentDescription = null,
                                    tint = if (isSelected) MaterialTheme.colorScheme.primary else TrenteColors.secondaryText
                                )
                            }
                            if (index < group.options.size - 1) RowDivider()
                        }
                    }
                }
            }
        }
    }
}

/** Searchable questions and answers, with the 50/30/20 card on top, like `FAQView`. */
@Composable
fun FAQScreen(onBack: () -> Unit) {
    var query by remember { mutableStateOf("") }
    val items = FAQItem.all
    val isSearching = query.trim().isNotEmpty()
    val results = remember(query) { if (isSearching) FAQItem.matching(query, items) else items }
    val sections = remember(results) { FAQSection.sections(if (isSearching) results else results.filter { it != FAQItem.featured }) }
    Scaffold(topBar = { TrenteTopBar(title = localized("Frequently Asked Questions"), onBack = onBack) }) { padding ->
        LazyColumn(contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = padding.calculateTopPadding() + 8.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            item {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    placeholder = { Text(localized("Search questions")) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    singleLine = true,
                    shape = CircleShape,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            if (!isSearching) {
                item { FeaturedCard() }
            }
            if (isSearching && results.isEmpty()) {
                item { Text(localized("No Matching Transactions").replace("Transactions", ""), style = TrenteType.subheadline, color = TrenteColors.secondaryText, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(24.dp)) }
            }
            sections.forEach { section ->
                item { SectionTitle(localized(section.topic.title)) }
                item {
                    TrenteListBackground {
                        section.items.forEachIndexed { index, item ->
                            FAQRow(item)
                            if (index < section.items.size - 1) RowDivider()
                        }
                    }
                }
            }
            item {
                TrenteListBackground {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(localized("Can't find your answer?"), style = TrenteType.headline)
                        Text(localized("Email the developer. I reply to every message!"), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                        ContactButton()
                    }
                }
            }
        }
    }
}

@Composable
private fun FAQRow(item: FAQItem) {
    var isExpanded by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxWidth().clickable { isExpanded = !isExpanded }.padding(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(localized(item.question), style = TrenteType.body, modifier = Modifier.weight(1f))
            Icon(if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore, contentDescription = null, tint = TrenteColors.secondaryText)
        }
        if (isExpanded) {
            Text(localized(item.answer), style = TrenteType.subheadline, color = TrenteColors.secondaryText, modifier = Modifier.padding(top = 8.dp))
        }
    }
}

@Composable
private fun FeaturedCard() {
    var isExpanded by remember { mutableStateOf(false) }
    val shares = OnboardingModel.suggestedPercentages
    TrenteListBackground {
        Column(Modifier.fillMaxWidth().clickable { isExpanded = !isExpanded }.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(localized("New to Trente?").uppercase(), style = TrenteType.caption.copy(fontWeight = FontWeight.SemiBold), color = TrenteColors.secondaryText)
            Text(localized("The 50/30/20 rule in 30 seconds"), style = TrenteType.headline)
            ProportionalBar(slices = BudgetCategory.entries.map { it.color to (shares[it] ?: 0).toDouble() }, spacing = 2.dp, minimumLength = 0.dp)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                BudgetCategory.entries.forEach { category ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        app.trente.ui.components.CategoryDot(category.color, size = 8.dp)
                        Spacer(Modifier.width(4.dp))
                        Text("${category.shortName} ${shares[category]}%", style = TrenteType.caption, color = TrenteColors.secondaryText)
                    }
                }
            }
            Text(localized("Split your take-home income into Needs, Wants and Savings and Debts. Trente sorts every transaction into one of them."), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
            if (isExpanded) {
                Text(localized(FAQItem.featured.answer), style = TrenteType.subheadline, modifier = Modifier.padding(top = 4.dp))
            }
        }
    }
}

/** Opens the mail app with the feedback template; offers to copy the address when none is installed, like `ContactButton`. */
@Composable
fun ContactButton(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val clipboard = LocalClipboardManager.current
    var showsFallback by remember { mutableStateOf(false) }
    TrentePrimaryButton(text = localized("Send Me an Email"), icon = Icons.Default.Email, modifier = modifier, onClick = {
        val url = SupportMail.feedbackURL(appInfo(context))
        try {
            context.startActivity(Intent(Intent.ACTION_SENDTO, Uri.parse(url)))
        } catch (exception: Exception) {
            showsFallback = true
        }
    })
    if (showsFallback) {
        AlertDialog(
            onDismissRequest = { showsFallback = false },
            title = { Text(localized("Couldn't Open Mail")) },
            text = { Text(localized("You can write to %@ from any email app.", SupportMail.ADDRESS)) },
            confirmButton = {
                TextButton(onClick = { clipboard.setText(AnnotatedString(SupportMail.ADDRESS)); showsFallback = false }) { Text(localized("Copy Address")) }
            },
            dismissButton = { TextButton(onClick = { showsFallback = false }) { Text(localized("OK")) } }
        )
    }
}

/** The developer's portrait, greeting, bio, contact button and links, like `AboutDeveloperView`. */
@Composable
fun AboutDeveloperScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val profile = DeveloperProfile.louis
    Scaffold(topBar = { TrenteTopBar(title = localized("About the Developer"), onBack = onBack) }) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(Modifier.padding(top = 16.dp)) {
                Image(painterResource(R.drawable.developer_photo), contentDescription = profile.name, contentScale = ContentScale.Crop, modifier = Modifier.size(140.dp).clip(CircleShape))
                Sticker(R.drawable.sticker_pig, modifier = Modifier.width(64.dp).align(Alignment.BottomEnd).padding(end = 0.dp))
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(localized(profile.greeting), style = TrenteType.largeTitle, textAlign = TextAlign.Center)
                Text(localized(profile.bio), style = TrenteType.body, color = TrenteColors.secondaryText, textAlign = TextAlign.Center)
            }
            ContactButton()
            TrenteCard(label = localized("Find Me Online"), icon = Icons.Default.Link, withPadding = false) {
                profile.links.forEachIndexed { index, link ->
                    ExternalLinkRow(title = localized(link.title), icon = null, onClick = { openUrl(context, link.url) })
                    if (index < profile.links.size - 1) RowDivider()
                }
            }
        }
    }
}

/** Illustrations, the 50/30/20 rule and thanks, like `CreditsView`. */
@Composable
fun CreditsScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    Scaffold(topBar = { TrenteTopBar(title = localized("Credits"), onBack = onBack) }) { padding ->
        LazyColumn(contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = padding.calculateTopPadding() + 8.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            CreditSection.all.forEach { section ->
                item { SectionTitle(localized(section.title)) }
                item {
                    TrenteListBackground {
                        section.credits.forEachIndexed { index, credit ->
                            val url = credit.url
                            Row(
                                Modifier.fillMaxWidth().let { if (url != null) it.clickable { openUrl(context, url) } else it }.padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                    Text(localized(credit.title), style = TrenteType.body)
                                    Text(localized(credit.detail), style = TrenteType.footnote, color = TrenteColors.secondaryText)
                                }
                                if (credit.url != null) {
                                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = TrenteColors.secondaryText)
                                }
                            }
                            if (index < section.credits.size - 1) RowDivider()
                        }
                    }
                }
            }
        }
    }
}
