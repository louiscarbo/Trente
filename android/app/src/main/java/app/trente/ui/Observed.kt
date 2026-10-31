package app.trente.ui

import androidx.compose.runtime.Stable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.neverEqualPolicy

/** Holds a plain model: every composable that reads [value] redraws after [mutate] or [refresh]. */
@Stable
class Observed<T>(model: T) {
    private val state = mutableStateOf(model, neverEqualPolicy())

    val value: T get() = state.value

    fun mutate(block: T.() -> Unit) {
        state.value.block()
        refresh()
    }

    fun refresh() {
        state.value = state.value
    }
}
