package app.trente.ui.screens

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.trente.R
import app.trente.billing.TrentePlusPlan
import app.trente.core.model.TrentePlusBenefit
import app.trente.core.support.ExternalLinks
import app.trente.core.support.localized
import app.trente.ui.LocalAppContainer
import app.trente.ui.components.CloseStyle
import app.trente.ui.components.Sticker
import app.trente.ui.components.TrenteCard
import app.trente.ui.components.TrenteListBackground
import app.trente.ui.components.TrentePrimaryButton
import app.trente.ui.components.TrenteTopBar
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import kotlinx.coroutines.launch

/** The paywall: the pig, the benefits, the monthly and yearly plans, like `SubscriptionView`. */
@Composable
fun TrentePlusScreen(onClose: () -> Unit) {
    val context = LocalContext.current
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    val status = container.trentePlus
    val isSubscribed by status.isSubscribed.collectAsState()
    val plans by status.plans.collectAsState()
    val isAvailable by status.isAvailable.collectAsState()
    var selectedPlan by remember { mutableStateOf<TrentePlusPlan?>(null) }
    val wasSubscribed = remember { isSubscribed }
    LaunchedEffect(isSubscribed) { if (isSubscribed && !wasSubscribed) onClose() }
    LaunchedEffect(plans) { if (selectedPlan == null) selectedPlan = plans.firstOrNull { it.isYearly } ?: plans.firstOrNull() }

    Scaffold(
        topBar = { TrenteTopBar(title = "", onBack = onClose, closeStyle = CloseStyle.CLOSE) },
        bottomBar = {
            Column(Modifier.navigationBarsPadding().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (isSubscribed) {
                    TrentePrimaryButton(text = localized("Manage Subscription"), onClick = { openUrl(context, ExternalLinks.manageSubscriptions) })
                } else {
                    val plan = selectedPlan
                    TrentePrimaryButton(
                        text = if (plan != null) "${localized("Subscribe")} · ${plan.formattedPrice}" else localized("Subscribe"),
                        enabled = plan != null && isAvailable,
                        onClick = { (context as? Activity)?.let { activity -> plan?.let { status.subscribe(activity, it) } } }
                    )
                }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                    TextButton(onClick = { scope.launch { status.refresh() } }) { Text(localized("Restore Purchases"), style = TrenteType.footnote) }
                    TextButton(onClick = { openUrl(context, ExternalLinks.privacyPolicy) }) { Text(localized("Privacy Policy"), style = TrenteType.footnote) }
                    TextButton(onClick = { openUrl(context, ExternalLinks.termsOfUse) }) { Text(localized("Terms of Use"), style = TrenteType.footnote) }
                }
            }
        }
    ) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Sticker(R.drawable.sticker_pig, rotation = 0f, modifier = Modifier.width(170.dp))
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Trente+", style = TrenteType.largeTitle)
                Text(localized("Let Trente+ do the typing, and unlock new features."), style = TrenteType.body, color = TrenteColors.secondaryText, textAlign = TextAlign.Center)
            }
            TrenteCard(label = localized("Included with Trente+"), icon = Icons.Default.AutoAwesome) {
                TrentePlusBenefit.all.forEach { benefit ->
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Box(
                            Modifier.size(36.dp).clip(RoundedCornerShape(9.dp)).background(benefit.tintColor()),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                when (benefit.icon) {
                                    TrentePlusBenefit.BenefitIcon.REPEAT -> Icons.Default.Repeat
                                    TrentePlusBenefit.BenefitIcon.PHOTO -> Icons.Default.Photo
                                    TrentePlusBenefit.BenefitIcon.PALETTE -> Icons.Default.Palette
                                    TrentePlusBenefit.BenefitIcon.HEART -> Icons.Default.Favorite
                                },
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                        Column {
                            Text(localized(benefit.title), style = TrenteType.headline)
                            Text(localized(benefit.detail), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                        }
                    }
                }
            }
            if (!isSubscribed) {
                TrenteListBackground {
                    if (plans.isEmpty()) {
                        Text(
                            if (isAvailable) localized("Loading plans…") else localized("Google Play isn't available on this device."),
                            style = TrenteType.subheadline,
                            color = TrenteColors.secondaryText,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                    plans.forEach { plan ->
                        val isSelected = plan == selectedPlan
                        Row(Modifier.fillMaxWidth().clickable { selectedPlan = plan }.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(if (isSelected) Icons.Default.CheckCircle else Icons.Outlined.Circle, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                            Spacer(Modifier.width(12.dp))
                            Text(if (plan.isYearly) localized("Yearly") else localized("Monthly"), style = TrenteType.body, modifier = Modifier.weight(1f))
                            Text(plan.formattedPrice, style = TrenteType.body, color = TrenteColors.secondaryText)
                        }
                    }
                }
            } else {
                Text(localized("You have access to all Trente+ benefits. Thanks for subscribing!"), style = TrenteType.subheadline, color = TrenteColors.secondaryText, textAlign = TextAlign.Center)
            }
        }
    }
}

@Composable
private fun TrentePlusBenefit.tintColor(): Color = when (tint) {
    TrentePlusBenefit.BenefitTint.BLUE -> TrenteColors.blue
    TrentePlusBenefit.BenefitTint.ORANGE -> TrenteColors.orange
    TrentePlusBenefit.BenefitTint.PURPLE -> TrenteColors.purple
    TrentePlusBenefit.BenefitTint.RED -> TrenteColors.red
}
