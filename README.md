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
#Include ../lib/_Includes.ahk

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
    MaxAttempts: 500,
    Strategy:    AlterationCrafting.STRATEGY_ANY, ; "ANY", "BOTH", "CLEAN"
    Filters:     MyFilters,
}

; Запускаем крафт
AlterationCrafting.Run(conf)
```
Для крафта с Regal Orb нужно 2 списка фильтров: необходимые моды и желательные моды, а также 2 стратегии для необходимых и желательных модов. Стратегия желательных модов должна быть такой же или шире, чем стратегия для необходимых (нельзя ожидать 2 префикса + 1 суффикс с необходимыми модами и 1 префикс и 2 суффикса с желательными модами)
```
#Requires AutoHotkey v2.0
#Include ../lib/_Includes.ahk

MandatoryFilters := [
    { text: "to Intelligence" },
    { text: "to All Attributes" }
]
NiceFilters := [
    { text: "increased Effect" },
    { text: "to Maximum Energy Shield" }
]
conf := {
    MandatoryFilters: MandatoryFilters,
    NiceFilters: NiceFilters,
    MandatoryStrategy: RegalCrafting.STRATEGY_1ANY,
    NiceStrategy: RegalCrafting.STRATEGY_2ANY,
}

RegalCrafting.Run(conf)
```
---
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
* Крафт с помощью Chaos Orb + Exalted Orb
* Расширенный функционал для кастомных сценариев