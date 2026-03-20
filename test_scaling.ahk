#Requires AutoHotkey v2.0
#Include lib/_Includes.ahk

/**
 * Тестовый скрипт для визуальной проверки скейлинга.
 * Нажмите F2, чтобы обновить координаты и показать маркеры.
 * Нажмите F3, чтобы скрыть маркеры.
 */

F2:: {
    ClearMarkers()

    for name, currencyItem in Stash.Currencies {
        currencyItem.Refresh()
        currencyItem.Show()
    }
}

F3:: ClearMarkers()

ClearMarkers() {
    for name, currencyItem in Stash.Currencies {
        currencyItem.Hide()
    }
}