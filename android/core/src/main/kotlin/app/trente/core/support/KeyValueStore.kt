package app.trente.core.support

/** A small typed preference store, standing in for `UserDefaults`. The app backs it with SharedPreferences. */
interface KeyValueStore {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun getInt(key: String): Int?
    fun putInt(key: String, value: Int)
    fun getLong(key: String): Long?
    fun putLong(key: String, value: Long)
    fun getBoolean(key: String): Boolean?
    fun putBoolean(key: String, value: Boolean)
    fun getDouble(key: String): Double?
    fun putDouble(key: String, value: Double)
    fun remove(key: String)
}

class InMemoryKeyValueStore : KeyValueStore {
    private val values = mutableMapOf<String, Any>()

    override fun getString(key: String): String? = values[key] as? String
    override fun putString(key: String, value: String) { values[key] = value }
    override fun getInt(key: String): Int? = values[key] as? Int
    override fun putInt(key: String, value: Int) { values[key] = value }
    override fun getLong(key: String): Long? = values[key] as? Long
    override fun putLong(key: String, value: Long) { values[key] = value }
    override fun getBoolean(key: String): Boolean? = values[key] as? Boolean
    override fun putBoolean(key: String, value: Boolean) { values[key] = value }
    override fun getDouble(key: String): Double? = values[key] as? Double
    override fun putDouble(key: String, value: Double) { values[key] = value }
    override fun remove(key: String) { values.remove(key) }
}
