# Path of Exile Wrist Saver 

Фреймворк на **AutoHotkey v2** для автоматизации крафта предметов в Path of Exile.

---

## Инструкция по использованию

### 1. Подготовка в игре
* **Язык:** Только **English** (парсер настроен на английские регулярные выражения).
* **Настройки UI:** Включите **Advanced Mod Descriptions** (Settings -> UI). Без этого скрипт не увидит Тиры.
* **Сташ:** Откройте валютную вкладку сташа. Предмет для крафта должен лежать в координатах, указанных в `CraftItem`.
* **Прерывание:** По дефолту прерывание на F4, можно добавить в конец файла с рецептом свою кнопку.

### 2. Настройка фильтров
Создайте `.ahk` файл (например, `flasks.ahk`) и опишите нужные моды:

```autohotkey
#Requires AutoHotkey v2.0
#Include lib.ahk

; Описание фильтров
; необходимо указать хотя бы название или часть описания мода, можно и то и то
; можно настраивать одноименные моды с помощью описания, например инфлюенсные моды или нотаблы на кластерах
MyFilters := [
    { text: "when you are Hit by an Enemy", tier: 2 },
    { text: "increased Charge Recovery", tier: 2 },
    { text: "gain a Flask Charge when you deal a Critical Strike", tier: 2 },
    { text: "reduced Charges per use", tier: 2 },
    { name: "of the Rainbow" },
    { name: "of the Cheetah" },
    { name: "of Tenaciousness" },
    { name: "of the Owl" },
    { name: "of the Heron" },
    { name: "of Bog Moss" },
    { name: "of the Sunfish" },
    { text: "increased Evasion Rating during Effect", tier: 2 },
    { text: "increased Armour during Effect", tier: 2 },
    { text: "increased Critical Strike Chance during Effec", tier: 2 }
]

; Собираем объект для передачи в алгоритм крафта
conf := {
    Version:     1.0,
    MaxAttempts: 500,
    CraftMode:   AlterationCrafting.STRATEGY_ANY, ; "ANY", "BOTH", "CLEAN"
    Filters:     MyFilters,
    DebugLevel:  0 ; 0 - только итог, 1 - всё подряд
}

; Запускаем крафт
AlterationCrafting.Run(conf)
```
---

## Архитектура проекта

Проект разделен на логические слои, чтобы изменения в одном файле не ломали работу других:

* **`lib.ahk` (Движок):**
* * `CraftingCore`: "Руки" скрипта. Работа с окном игры, клики, парсинг текста через Regex, проверка наличия валюты по цвету пикселей.
* `AlterationCrafting`: "Мозг" скрипта. Алгоритмы принятия решений (когда использовать *Orb of Alteration*, а когда *Orb of Augmentation*).
* **`StashMap` (Разметка):** Координаты элементов вкладки для разрешения 2560x1440.
* **`settings.ini`:** Локальные настройки задержек и чувствительности (создается автоматически при первом запуске).
* **`YourCraft.ahk` (User Config):** Файл с описанием ваших фильтров и выбором стратегии.

### Автоматический скейлинг
Движок использует **вертикальный скейлинг**. Координаты из `StashMap` автоматически пересчитываются под текущую высоту клиентской области окна PoE.
> *Поддерживает большинство разрешений (1080p, 2K, 4K) и оконные режимы.*

### Fail-Fast Фильтрация
Метод оценки модов оптимизирован для производительности:
1. Проверка **Имени** (дешево).
2. Проверка **Тира** (сравнение чисел).
3. Проверка **Текста** мода через `InStr` (только если имя и тир совпали).

---
## TODO
* Крафт с помощью Regal Orb + Orb of Scouring (поверх AlterationCrafting)
* Крафт с помощью Chaos Orb + Exalted Orb
* Расширенный функционал для кастомных сценариев