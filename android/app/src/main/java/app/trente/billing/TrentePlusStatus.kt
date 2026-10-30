package app.trente.billing

import android.app.Activity
import android.app.Application
import android.util.Log
import app.trente.BuildConfig
import app.trente.core.model.TrenteDates
import app.trente.core.services.TrentePlus
import app.trente.core.services.TrentePlusDebugOverride
import app.trente.core.services.TrentePlusEntitlement
import app.trente.core.support.KeyValueStore
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.android.billingclient.api.acknowledgePurchase
import com.android.billingclient.api.queryProductDetails
import com.android.billingclient.api.queryPurchasesAsync
import java.time.Instant
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** One plan of the Trente+ subscription, with its price from Google Play. */
data class TrentePlusPlan(
    val basePlanId: String,
    val offerToken: String,
    val formattedPrice: String,
    val billingPeriod: String
) {
    val isYearly: Boolean get() = basePlanId == TrentePlus.YEARLY_PLAN_ID
}

/**
 * The Trente+ subscription through Google Play Billing.
 *
 * The last known status is cached so the app and the widget start with it before Play answers.
 */
class TrentePlusStatus(
    private val application: Application,
    private val preferences: KeyValueStore,
    private val scope: CoroutineScope
) : PurchasesUpdatedListener {
    private val mutableHasActiveSubscription = MutableStateFlow(TrentePlusEntitlement.cached(preferences))
    private val mutableIsSubscribed = MutableStateFlow(TrentePlusEntitlement.cached(preferences))
    private val mutablePlans = MutableStateFlow<List<TrentePlusPlan>>(emptyList())
    private val mutableIsAvailable = MutableStateFlow(true)

    /** Whether Trente+ is unlocked, debug override included. */
    val isSubscribed: StateFlow<Boolean> get() = mutableIsSubscribed.asStateFlow()

    val plans: StateFlow<List<TrentePlusPlan>> get() = mutablePlans.asStateFlow()

    /** False when Google Play isn't reachable on this device. */
    val isAvailable: StateFlow<Boolean> get() = mutableIsAvailable.asStateFlow()

    var debugOverride: TrentePlusDebugOverride = if (BuildConfig.DEBUG) TrentePlusDebugOverride.stored(preferences) else TrentePlusDebugOverride.STORE
        set(value) {
            field = value
            value.store(preferences)
            publish()
        }

    private var isAutoRenewing = true
    private var productDetails: ProductDetails? = null
    private val initialRefresh = CompletableDeferred<Unit>()

    private val client: BillingClient = BillingClient.newBuilder(application)
        .setListener(this)
        .enablePendingPurchases()
        .build()

    val automaticUnlockedUntil: Instant
        get() {
            if (!isSubscribed.value) return TrenteDates.distantPast
            return TrenteDates.distantFuture
        }

    fun start() {
        connect()
    }

    private fun connect() {
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    mutableIsAvailable.value = true
                    scope.launch { refresh() }
                } else {
                    Log.w(TAG, "Billing setup failed: ${result.debugMessage}")
                    mutableIsAvailable.value = result.responseCode != BillingClient.BillingResponseCode.BILLING_UNAVAILABLE
                    initialRefresh.complete(Unit)
                }
            }

            override fun onBillingServiceDisconnected() {
                mutableIsAvailable.value = false
            }
        })
    }

    suspend fun refresh() {
        try {
            val purchases = withContext(Dispatchers.IO) {
                client.queryPurchasesAsync(
                    QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()
                )
            }
            if (purchases.billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                apply(purchases.purchasesList)
            }
            loadPlans()
        } catch (exception: Exception) {
            Log.w(TAG, "Billing refresh failed", exception)
        } finally {
            initialRefresh.complete(Unit)
        }
    }

    private suspend fun loadPlans() {
        if (productDetails != null) return
        val product = QueryProductDetailsParams.Product.newBuilder()
            .setProductId(TrentePlus.PRODUCT_ID)
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
        val result = withContext(Dispatchers.IO) {
            client.queryProductDetails(QueryProductDetailsParams.newBuilder().setProductList(listOf(product)).build())
        }
        val details = result.productDetailsList?.firstOrNull() ?: return
        productDetails = details
        mutablePlans.value = details.subscriptionOfferDetails.orEmpty().map { offer ->
            val phase = offer.pricingPhases.pricingPhaseList.last()
            TrentePlusPlan(
                basePlanId = offer.basePlanId,
                offerToken = offer.offerToken,
                formattedPrice = phase.formattedPrice,
                billingPeriod = phase.billingPeriod
            )
        }.sortedBy { if (it.isYearly) 1 else 0 }
    }

    private suspend fun apply(purchases: List<Purchase>) {
        val active = purchases.filter { it.purchaseState == Purchase.PurchaseState.PURCHASED && it.products.contains(TrentePlus.PRODUCT_ID) }
        for (purchase in active) {
            if (!purchase.isAcknowledged) {
                withContext(Dispatchers.IO) {
                    client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build())
                }
            }
        }
        isAutoRenewing = active.any { it.isAutoRenewing }
        mutableHasActiveSubscription.value = active.isNotEmpty()
        publish()
    }

    private fun publish() {
        val subscribed = debugOverride.isSubscribed(mutableHasActiveSubscription.value)
        TrentePlusEntitlement.cache(subscribed, preferences)
        mutableIsSubscribed.value = subscribed
    }

    /** Waits for the first answer from Google Play, then tells whether Trente+ is unlocked. */
    suspend fun currentStatus(): Boolean {
        initialRefresh.await()
        return isSubscribed.value
    }

    fun subscribe(activity: Activity, plan: TrentePlusPlan) {
        val details = productDetails ?: return
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(details)
                        .setOfferToken(plan.offerToken)
                        .build()
                )
            )
            .build()
        client.launchBillingFlow(activity, params)
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        if (result.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            scope.launch { refresh() }
        }
    }

    private companion object {
        const val TAG = "TrentePlus"
    }
}
