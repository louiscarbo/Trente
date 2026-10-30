package app.trente.core.support

/**
 * Resolves an English key to the user's language.
 *
 * The keys are the English sentences, exactly like the iOS string catalog, so the same translations serve both apps.
 * The app installs a provider backed by Android resources; without one, the key itself is returned with its
 * placeholders filled in.
 */
fun interface LocalizedStringProvider {
    fun localized(key: String, args: Array<out Any?>): String
}

object Localization {
    @Volatile
    var provider: LocalizedStringProvider = DefaultLocalizedStringProvider
}

fun localized(key: String, vararg args: Any?): String = Localization.provider.localized(key, args)

object DefaultLocalizedStringProvider : LocalizedStringProvider {
    private val placeholder = Regex("%(\\d+\\$)?(@|lld|ld|d|s|lf|f)")

    override fun localized(key: String, args: Array<out Any?>): String {
        var next = 0
        return placeholder.replace(key) { match ->
            val position = match.groupValues[1]
            val index = if (position.isEmpty()) next++ else position.dropLast(1).toInt() - 1
            args.getOrNull(index)?.toString() ?: match.value
        }
    }
}
