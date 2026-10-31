package app.trente

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import app.trente.core.support.KeyValueStore

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

    private fun component(context: Context) = ComponentName(context, "app.trente.icon.$alias")

    companion object {
        private const val PENDING_KEY = "appIcon.pending"

        fun current(context: Context, preferences: KeyValueStore): AppIcon =
            pending(preferences) ?: enabled(context)

        /** Disabling the alias that launched the app closes it, so the switch waits for the app to leave the screen. */
        fun select(icon: AppIcon, preferences: KeyValueStore) = preferences.putString(PENDING_KEY, icon.alias)

        fun applyPending(context: Context, preferences: KeyValueStore) {
            val icon = pending(preferences) ?: return
            preferences.remove(PENDING_KEY)
            val manager = context.packageManager
            entries.forEach { candidate ->
                manager.setComponentEnabledSetting(
                    candidate.component(context),
                    if (candidate == icon) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
        }

        private fun pending(preferences: KeyValueStore): AppIcon? =
            preferences.getString(PENDING_KEY)?.let { alias -> entries.firstOrNull { it.alias == alias } }

        private fun enabled(context: Context): AppIcon {
            val manager = context.packageManager
            return entries.firstOrNull { icon ->
                val state = manager.getComponentEnabledSetting(icon.component(context))
                state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED || (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && icon == GREEN)
            } ?: GREEN
        }
    }
}
