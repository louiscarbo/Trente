package app.trente.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.trente.R
import app.trente.core.model.BudgetCategory
import app.trente.core.model.Currency
import app.trente.core.presentation.OnboardingDirection
import app.trente.core.presentation.OnboardingModel
import app.trente.core.presentation.OnboardingStep
import app.trente.core.services.notifications.NotificationText
import app.trente.core.services.notifications.RecurringNotificationPlanner
import app.trente.core.services.notifications.RecurringNotificationRequest
import app.trente.core.support.NotificationPermissionStatus
import app.trente.core.support.localized
import app.trente.notifications.notificationSettingsIntent
import app.trente.ui.LocalAppContainer
import app.trente.ui.Observed
import app.trente.ui.components.CategoryDot
import app.trente.ui.components.CurrencyTextField
import app.trente.ui.components.DateField
import app.trente.ui.components.ErrorAlert
import app.trente.ui.components.IncomeRepartitionComponent
import app.trente.ui.components.MonthCurrencyPicker
import app.trente.ui.components.PageIndicator
import app.trente.ui.components.Sticker
import app.trente.ui.components.TrenteCard
import app.trente.ui.components.TrentePrimaryButton
import app.trente.ui.components.TrenteSecondaryButton
import app.trente.ui.components.WeightedColumn
import app.trente.ui.rememberStore
import app.trente.ui.theme.CardShape
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import app.trente.ui.theme.color
import app.trente.ui.theme.darken
import kotlinx.coroutines.launch

/** Welcome, budget, split, notifications, all set; then the paywall, like `OnboardingView`. */
@Composable
fun OnboardingScreen(isFirstLaunch: Boolean, onFinish: () -> Unit) {
    val store = rememberStore() ?: return
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    val onboarding = remember { Observed(OnboardingModel(steps = OnboardingStep.entries)) }
    fun mutate(block: OnboardingModel.() -> Unit) = onboarding.mutate(block)
    var saveError by remember { mutableStateOf<String?>(null) }
    var incomeError by remember { mutableStateOf<String?>(null) }
    var isShowingPaywall by remember { mutableStateOf(false) }
    var permissionStatus by remember { mutableStateOf(NotificationPermissionStatus.NOT_DETERMINED) }
    LaunchedEffect(Unit) { permissionStatus = container.notificationPermission.status() }

    fun advance() {
        if (onboarding.value.isLastStep) onFinish() else mutate { goForward() }
    }

    fun saveMonthAndContinue() {
        try {
            mutate { saveMonth(store, reusingExistingMonth = isFirstLaunch) }
            advance()
        } catch (exception: Exception) {
            saveError = exception.localizedMessage ?: exception.toString()
        }
    }

    fun startTracking() {
        try {
            mutate { addIncome(store) }
            isShowingPaywall = true
        } catch (exception: Exception) {
            incomeError = exception.localizedMessage ?: exception.toString()
        }
    }

    if (isShowingPaywall) {
        val closePaywall = { isShowingPaywall = false; onFinish() }
        BackHandler(onBack = closePaywall)
        TrentePlusScreen(onClose = closePaywall)
        return
    }

    BackHandler(enabled = onboarding.value.canGoBack) { mutate { goBack() } }

    Column(Modifier.fillMaxSize().statusBarsPadding()) {
        Box(Modifier.fillMaxWidth().height(48.dp).padding(horizontal = 16.dp), contentAlignment = Alignment.Center) {
            PageIndicator(pageCount = onboarding.value.steps.size, currentPage = onboarding.value.steps.indexOf(onboarding.value.currentStep), onSelect = {})
            if (onboarding.value.canGoBack) {
                IconButton(onClick = { mutate { goBack() } }, modifier = Modifier.align(Alignment.CenterStart)) {
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, contentDescription = localized("Back"))
                }
            }
        }
        AnimatedContent(
            targetState = onboarding.value.currentStep,
            transitionSpec = {
                val forward = onboarding.value.direction == OnboardingDirection.FORWARD
                slideInHorizontally { if (forward) it else -it } togetherWith slideOutHorizontally { if (forward) -it else it }
            },
            label = "onboardingStep"
        ) { step ->
            when (step) {
                OnboardingStep.WELCOME -> StepLayout(
                    title = localized("Take control of your budget."),
                    subtitle = localized("Trente splits your budget into Needs, Wants and Savings, so you always know what's left this month."),
                    isHero = true,
                    actions = { TrentePrimaryButton(text = localized("Get Started"), onClick = ::advance) }
                ) {
                    val height = (LocalConfiguration.current.screenHeightDp * 0.55f).dp.coerceAtLeast(420.dp)
                    CategoryTreemap(percentages = OnboardingModel.suggestedPercentages, modifier = Modifier.fillMaxWidth().height(height))
                }
                OnboardingStep.BUDGET -> StepLayout(
                    title = localized("Your monthly budget"),
                    subtitle = localized("Think of it as the money you're free to spend each month, once taxes are taken care of."),
                    actions = { TrentePrimaryButton(text = localized("Continue"), enabled = onboarding.value.canContinue, onClick = ::advance) }
                ) {
                    TrenteCard(label = localized("Month Details"), icon = Icons.Default.CalendarMonth) {
                        DateField(label = localized("Start Date"), date = onboarding.value.draft.startDate, onDateChange = { date -> mutate { draft.startDate = date } })
                        MonthCurrencyPicker(currencyCode = onboarding.value.draft.currency.isoCode, onCurrencyChange = { currency -> mutate { draft.currency = currency } })
                    }
                    TrenteCard(label = localized("Ideal Budget"), icon = Icons.Default.Speed) {
                        CurrencyTextField(
                            amountCents = onboarding.value.budgetCents,
                            onAmountChange = { cents -> mutate { budgetCents = cents } },
                            currencyCode = onboarding.value.draft.currency.isoCode,
                            textStyle = TrenteType.title,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                    Row(Modifier.padding(horizontal = 4.dp), verticalAlignment = Alignment.Top) {
                        Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = TrenteColors.secondaryText, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Column {
                            Text(localized("Income varies?"), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                            Text(localized("Use your best estimate. Log extra income as it comes in, and adjust next month's budget."), style = TrenteType.footnote, color = TrenteColors.secondaryText)
                        }
                    }
                }
                OnboardingStep.SPLIT -> StepLayout(
                    title = localized("Split your budget"),
                    subtitle = localized("We start you on the 50/30/20 rule. Adjust it until it fits your life, you can change it every month."),
                    actions = { TrentePrimaryButton(text = localized("Continue"), enabled = onboarding.value.isRepartitionComplete, onClick = ::saveMonthAndContinue) }
                ) {
                    TrenteCard(label = localized("Ideal Budget"), icon = Icons.Default.Speed) {
                        Text(
                            app.trente.core.support.MoneyFormat.budget(onboarding.value.budgetCents / 100.0, onboarding.value.draft.currency.isoCode),
                            style = TrenteType.title,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                        IncomeRepartitionComponent(
                            repartition = onboarding.value.draft.idealRepartition,
                            amountToSplit = onboarding.value.budgetCents,
                            currencyCode = onboarding.value.draft.currency.isoCode,
                            onRepartitionChange = { repartition -> mutate { draft.idealRepartition = repartition } },
                            onCompleteChange = { complete -> mutate { isRepartitionComplete = complete } }
                        )
                    }
                    Column(Modifier.padding(horizontal = 4.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        BudgetCategory.entries.forEach { category ->
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                CategoryDot(category.color)
                                Spacer(Modifier.width(8.dp))
                                Text(category.displayName, style = TrenteType.subheadline.copy(fontWeight = FontWeight.SemiBold))
                                Spacer(Modifier.width(8.dp))
                                Text(category.shortExamples, style = TrenteType.footnote, color = TrenteColors.secondaryText)
                            }
                        }
                    }
                }
                OnboardingStep.NOTIFICATIONS -> NotificationsStep(
                    currency = onboarding.value.draft.currency,
                    status = permissionStatus,
                    onEnable = {
                        scope.launch {
                            permissionStatus = container.notificationPermission.requestIfNeeded()
                            if (onboarding.value.currentStep == OnboardingStep.NOTIFICATIONS) advance()
                        }
                    },
                    onOpenSettings = { context -> context.startActivity(notificationSettingsIntent(context)) },
                    onContinue = ::advance
                )
                OnboardingStep.ALL_SET -> StepLayout(
                    title = localized("You're all set!"),
                    subtitle = localized("Your first month starts today. Log expenses as you go and Trente shows you what's left."),
                    centered = true,
                    header = { Sticker(R.drawable.sticker_rocket, rotation = 0f, modifier = Modifier.width(170.dp)) },
                    actions = { TrentePrimaryButton(text = localized("Start Tracking"), onClick = ::startTracking) }
                ) {
                    onboarding.value.savedMonth?.let { month ->
                        MonthSummaryCard(
                            name = month.name,
                            remaining = month.remainingAmount,
                            spent = month.spentAmount(app.trente.core.model.BudgetScope.All),
                            currencyCode = month.currency.isoCode,
                            isOverspent = month.overSpent,
                            modifier = Modifier.widthIn(max = 420.dp)
                        )
                    }
                }
            }
        }
    }
    ErrorAlert(message = saveError, onDismiss = { saveError = null }, title = localized("We couldn't save your month"), retry = ::saveMonthAndContinue)
    ErrorAlert(message = incomeError, onDismiss = { incomeError = null; isShowingPaywall = true }, title = localized("We couldn't add your income"), retry = ::startTracking)
}

/** Header, scrolling content and bottom actions, like `OnboardingStepLayout` on a phone. */
@Composable
private fun StepLayout(
    title: String,
    subtitle: String,
    isHero: Boolean = false,
    centered: Boolean = false,
    header: (@Composable () -> Unit)? = null,
    actions: @Composable () -> Unit,
    content: @Composable () -> Unit
) {
    Column(Modifier.fillMaxSize().imePadding()) {
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
            horizontalAlignment = if (centered) Alignment.CenterHorizontally else Alignment.Start
        ) {
            if (header != null) header()
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    title,
                    style = if (isHero) TrenteType.largeTitle.copy(fontSize = 46.sp, lineHeight = 52.sp, fontWeight = FontWeight.Black) else TrenteType.largeTitle,
                    textAlign = if (centered) TextAlign.Center else TextAlign.Start,
                    modifier = Modifier.fillMaxWidth()
                )
                Text(subtitle, style = TrenteType.body, color = TrenteColors.secondaryText, textAlign = if (centered) TextAlign.Center else TextAlign.Start, modifier = Modifier.fillMaxWidth())
            }
            content()
            Spacer(Modifier.height(8.dp))
        }
        Column(Modifier.navigationBarsPadding().padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            actions()
        }
    }
}

@Composable
private fun NotificationsStep(
    currency: Currency,
    status: NotificationPermissionStatus,
    onEnable: () -> Unit,
    onOpenSettings: (android.content.Context) -> Unit,
    onContinue: () -> Unit
) {
    val context = LocalContext.current
    StepLayout(
        title = localized("Never miss an expense"),
        subtitle = localized("Trente tells you when a new month starts and when a recurring payment like rent is due, so you can mark it as paid right from the notification."),
        centered = true,
        header = {
            NotificationPreview(
                title = NotificationText.amountTitle(-800_00, currency, localized("Rent")),
                message = RecurringNotificationPlanner.body(RecurringNotificationRequest.Kind.DUE, isIncome = false),
                modifier = Modifier.widthIn(max = 370.dp)
            )
        },
        actions = {
            when (status) {
                NotificationPermissionStatus.NOT_DETERMINED -> {
                    TrentePrimaryButton(text = localized("Turn On Notifications"), onClick = onEnable)
                    TrenteSecondaryButton(text = localized("Not Now"), onClick = onContinue)
                }
                NotificationPermissionStatus.DENIED -> {
                    TrentePrimaryButton(text = localized("Open Settings"), onClick = { onOpenSettings(context) })
                    TrenteSecondaryButton(text = localized("Not Now"), onClick = onContinue)
                }
                NotificationPermissionStatus.AUTHORIZED -> TrentePrimaryButton(text = localized("Continue"), onClick = onContinue)
            }
        }
    ) {}
}

/** A fake notification card, like `NotificationPreview`. */
@Composable
fun NotificationPreview(title: String, message: String, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().padding(bottom = 12.dp)) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surfaceContainer.copy(alpha = 0.7f),
            modifier = Modifier.matchParentSize().padding(horizontal = 15.dp).padding(top = 12.dp)
        ) {}
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = MaterialTheme.colorScheme.surfaceContainer,
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.06f)),
            shadowElevation = 6.dp,
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(Modifier.padding(horizontal = 14.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                androidx.compose.foundation.Image(painterResource(R.mipmap.ic_launcher), contentDescription = null, modifier = Modifier.size(38.dp).clip(RoundedCornerShape(9.dp)))
                Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                    Row {
                        Text(title, style = TrenteType.subheadline.copy(fontWeight = FontWeight.SemiBold), maxLines = 1, modifier = Modifier.weight(1f))
                        Text(localized("now"), style = TrenteType.footnote, color = TrenteColors.secondaryText)
                    }
                    Text(message, style = TrenteType.subheadline, maxLines = 2)
                }
            }
        }
    }
}

/** The three category slabs stacked by their share, with the pig on Needs, like `CategoryTreemap`. */
@Composable
fun CategoryTreemap(percentages: Map<BudgetCategory, Int>, modifier: Modifier = Modifier) {
    val categories = BudgetCategory.entries
    WeightedColumn(weights = categories.map { (percentages[it] ?: 0).toDouble() }, modifier = modifier) { index ->
        val category = categories[index]
        val color = category.color
        Box(
            Modifier
                .fillMaxWidth()
                .clip(CardShape)
                .background(color)
                .border(BorderStroke(3.dp, color.darken(0.1f)), CardShape)
        ) {
            Row(Modifier.fillMaxSize().padding(start = 18.dp, end = 18.dp, top = 12.dp, bottom = 6.dp), verticalAlignment = Alignment.Bottom) {
                Column(Modifier.weight(1f).padding(bottom = 10.dp)) {
                    Text(category.shortName, style = TrenteType.title2, color = color.darken(0.8f))
                    Text(category.shortExamples, style = TrenteType.footnote, color = color.darken(0.8f).copy(alpha = 0.75f))
                }
                Text(
                    "${percentages[category] ?: 0}%",
                    style = TrenteType.largeTitle.copy(fontSize = 56.sp, lineHeight = 60.sp, fontWeight = FontWeight.Black, letterSpacing = (-2).sp),
                    color = color.darken(0.8f),
                    maxLines = 1
                )
            }
            if (category == BudgetCategory.NEEDS) {
                Sticker(R.drawable.sticker_pig, rotation = 0f, modifier = Modifier.width(120.dp).align(Alignment.TopEnd).padding(top = 4.dp, end = 4.dp))
            }
        }
    }
}

@Suppress("unused")
private val unusedColor = Color.Unspecified
