package app.trente

import android.Manifest
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import app.trente.core.services.DeepLink
import app.trente.ui.AppRoot
import app.trente.ui.LocalAppContainer
import app.trente.ui.theme.TrenteTheme
import kotlinx.coroutines.CompletableDeferred

class MainActivity : ComponentActivity() {
    private var pendingDeepLink by mutableStateOf<DeepLink?>(null)
    private var permissionAnswer: CompletableDeferred<Boolean>? = null

    private val permissionLauncher = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        permissionAnswer?.complete(granted)
        permissionAnswer = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val container = appContainer
        container.notificationCenter.requester = {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val answer = CompletableDeferred<Boolean>()
                permissionAnswer = answer
                permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                answer.await()
            } else {
                true
            }
        }
        pendingDeepLink = intent?.dataString?.let(DeepLink::parse)
        setContent {
            TrenteTheme {
                CompositionLocalProvider(LocalAppContainer provides container) {
                    AppRoot(
                        pendingDeepLink = pendingDeepLink,
                        onDeepLinkHandled = { pendingDeepLink = null }
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingDeepLink = intent.dataString?.let(DeepLink::parse)
    }

    override fun onResume() {
        super.onResume()
        appContainer.notificationScheduler.scheduleSoon()
    }
}
