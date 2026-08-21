package com.rexo.marketplace.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "rexo_settings")

/**
 * PreferencesManager - DataStore-based persistence for user preferences.
 * Stores theme mode (System/Light/Dark) and language (English/Hindi).
 */
class PreferencesManager(private val context: Context) {
    companion object {
        val THEME_KEY = stringPreferencesKey("theme_mode") // "System", "Light", "Dark"
        val LANGUAGE_KEY = stringPreferencesKey("language") // "English", "Hindi"
    }

    val themeMode: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[THEME_KEY] ?: "System"
    }

    val language: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[LANGUAGE_KEY] ?: "English"
    }

    suspend fun setThemeMode(mode: String) {
        context.dataStore.edit { prefs ->
            prefs[THEME_KEY] = mode
        }
    }

    suspend fun setLanguage(language: String) {
        context.dataStore.edit { prefs ->
            prefs[LANGUAGE_KEY] = language
        }
    }
}
