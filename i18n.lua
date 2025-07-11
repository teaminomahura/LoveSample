local i18n = {}

i18n.current_locale = "en" -- デフォルトは英語
i18n.translations = {}

function i18n.set_locale(locale)
    i18n.current_locale = locale
    i18n.translations = require("config.locales." .. locale)
end

function i18n.t(key)
    return i18n.translations[key] or "MISSING_TRANSLATION: " .. key
end

-- 初期ロケールの設定
i18n.set_locale(i18n.current_locale)

return i18n
