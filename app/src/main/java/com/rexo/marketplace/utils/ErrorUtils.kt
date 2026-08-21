package com.rexo.marketplace.utils

/**
 * Utility for sanitizing error messages before displaying them to users.
 * Strips technical details like URLs, API keys, JSON errors, and Supabase internals.
 * Returns clean, user-friendly messages.
 */
object ErrorUtils {

    private val URL_PATTERN = Regex("https?://[^\\s\"']+", RegexOption.IGNORE_CASE)
    private val API_KEY_PATTERN = Regex("(apikey|key|token|secret|authorization)[=:\\s]*[^\\s\"',}]+", RegexOption.IGNORE_CASE)
    private val JSON_DETAIL_PATTERN = Regex("\\{[^}]*\\}")

    /**
     * Sanitize a raw error message for user display.
     * - Strips URLs (http/https patterns)
     * - Strips API keys and tokens
     * - Strips JSON details
     * - Returns user-friendly messages based on recognized keywords
     * - Default: "Something went wrong. Please try again."
     */
    fun sanitizeErrorMessage(rawMessage: String?): String {
        if (rawMessage.isNullOrBlank()) {
            return "Something went wrong. Please try again."
        }

        val lower = rawMessage.lowercase()

        // Network / connectivity issues
        if (lower.contains("timeout") || lower.contains("timed out")) {
            return "Connection timed out. Please check your internet and try again."
        }
        if (lower.contains("unable to resolve host") || lower.contains("no address associated") ||
            lower.contains("network") || lower.contains("connect")) {
            return "Network error. Please check your internet connection."
        }

        // Authentication issues
        if (lower.contains("not authenticated") || lower.contains("unauthorized") ||
            lower.contains("sign in") || lower.contains("login")) {
            return "Please sign in to continue."
        }
        if (lower.contains("invalid login") || lower.contains("invalid credentials")) {
            return "Invalid email or password. Please try again."
        }

        // Table/schema issues (should not happen in production, but handle gracefully)
        if (lower.contains("could not find") && lower.contains("table")) {
            return "Service temporarily unavailable. Please try again later."
        }
        if (lower.contains("schema")) {
            return "Service temporarily unavailable. Please try again later."
        }

        // JSON / deserialization errors
        if (lower.contains("json") || lower.contains("serializ") || lower.contains("deserializ") ||
            lower.contains("unexpected") || lower.contains("parsing")) {
            return "Something went wrong. Please try again."
        }

        // Permission issues
        if (lower.contains("permission") || lower.contains("forbidden") || lower.contains("denied")) {
            return "You don't have permission to perform this action."
        }

        // Not found
        if (lower.contains("not found") || lower.contains("no rows")) {
            return "The requested item was not found."
        }

        // Rate limiting
        if (lower.contains("rate limit") || lower.contains("too many requests")) {
            return "Too many requests. Please wait a moment and try again."
        }

        // If the message contains URLs or API keys, strip and return generic
        if (URL_PATTERN.containsMatchIn(rawMessage) || API_KEY_PATTERN.containsMatchIn(rawMessage)) {
            return "Something went wrong. Please try again."
        }

        // If message is short and clean (no technical jargon), allow it through
        val cleaned = rawMessage
            .let { URL_PATTERN.replace(it, "") }
            .let { API_KEY_PATTERN.replace(it, "") }
            .let { JSON_DETAIL_PATTERN.replace(it, "") }
            .trim()

        if (cleaned.length < 80 && !cleaned.contains("Exception") &&
            !cleaned.contains("supabase", ignoreCase = true) &&
            !cleaned.contains("postgrest", ignoreCase = true) &&
            !cleaned.contains("\$[")) {
            return cleaned.ifBlank { "Something went wrong. Please try again." }
        }

        return "Something went wrong. Please try again."
    }
}
