package app.trente.core.services

import java.net.URI
import java.util.UUID

/** The links the widget opens: `trente://month/<id>` and `trente://newtransaction/<month id>`. */
sealed class DeepLink {
    data class Month(val id: UUID) : DeepLink()
    data class NewTransaction(val monthID: UUID) : DeepLink()

    val targetMonthID: UUID
        get() = when (this) {
            is Month -> id
            is NewTransaction -> monthID
        }

    val url: String
        get() = when (this) {
            is Month -> url(HOST_MONTH, id)
            is NewTransaction -> url(HOST_NEW_TRANSACTION, monthID)
        }

    private val opensNewTransaction: Boolean get() = this is NewTransaction

    /** The month the link names, or the latest one without the new transaction sheet. */
    fun destination(months: List<app.trente.core.model.Month>): DeepLinkDestination? {
        months.firstOrNull { it.id == targetMonthID }?.let { return DeepLinkDestination(it, opensNewTransaction) }
        return months.firstOrNull()?.let { DeepLinkDestination(it, opensNewTransaction = false) }
    }

    companion object {
        const val SCHEME = "trente"
        private const val HOST_MONTH = "month"
        private const val HOST_NEW_TRANSACTION = "newtransaction"

        fun parse(text: String): DeepLink? {
            val uri = try {
                URI(text)
            } catch (exception: Exception) {
                return null
            }
            if (uri.scheme?.lowercase() != SCHEME) return null
            val host = uri.host?.lowercase() ?: return null
            val pathItems = (uri.path ?: "").split('/').filter { it.isNotEmpty() }
            if (pathItems.size != 1) return null
            val id = try {
                UUID.fromString(pathItems[0])
            } catch (exception: IllegalArgumentException) {
                return null
            }
            return when (host) {
                HOST_MONTH -> Month(id)
                HOST_NEW_TRANSACTION -> NewTransaction(id)
                else -> null
            }
        }

        private fun url(host: String, id: UUID): String = "$SCHEME://$host/${id.toString().uppercase()}"
    }
}

data class DeepLinkDestination(val month: app.trente.core.model.Month, val opensNewTransaction: Boolean)
