#Requires AutoHotkey v2.0

/*
 * Фреймворк. Общие методы для описания крафтов
 */
class CraftingCore {
    static TargetWindow := "ahk_class POEWindowClass"
    static ActiveMap    := {}
    static BaseHeight   := 1440

    /*
     * Конфигурация
     */
    static IniFile    := "settings.ini"
    static PingDelay  := 50 ; Базовая задержка (зависит от пинга)
    static FPSDelay   := 30 ; Задержка на отрисовку (зависит от производительности ПК)
    static LogFile    := "craft_log.txt"
    static DebugLevel := 0  ; 0 - только итог, 1 - всё подряд
    static EmptySlotIntensity := 40 ; Сумма цвета в ячейке, ниже которой считаем ячейку пустой

    static LoadSettings() {
        ; Если файла нет, создаем его с текущими дефолтами
        if !FileExist(this.IniFile) {
            IniWrite(this.PingDelay,          this.IniFile, "Delays",  "PingDelay"         )
            IniWrite(this.FPSDelay,           this.IniFile, "Delays",  "FPSDelay"          )
            IniWrite(this.LogFile,            this.IniFile, "General", "LogFile"           )
            IniWrite(this.DebugLevel,         this.IniFile, "General", "DebugLevel"        )
            IniWrite(this.EmptySlotIntensity, this.IniFile, "General", "EmptySlotIntensity")
        }

        ; Читаем значения из INI
        this.PingDelay          := Number(IniRead(this.IniFile, "Delays",  "PingDelay",          this.PingDelay         ))
        this.FPSDelay           := Number(IniRead(this.IniFile, "Delays",  "FPSDelay",           this.FPSDelay          ))
        this.LogFile            :=        IniRead(this.IniFile, "General", "LogFile",            this.LogFile           )
        this.DebugLevel         := Number(IniRead(this.IniFile, "General", "DebugLevel",         this.DebugLevel        ))
        this.EmptySlotIntensity := Number(IniRead(this.IniFile, "General", "EmptySlotIntensity", this.EmptySlotIntensity))
    }

    /*
     * Скейлинг окна вкладки под разрешение экрана
     */

    static InitializeMap() {
        try {
            WinGetClientPos(,, &W, &H, this.TargetWindow)
            k := H / this.BaseHeight

            for name, pos in StashMap.OwnProps() {
                if (pos.HasProp("x") && pos.HasProp("y")) {
                    this.ActiveMap.%name% := {
                        x: Round(pos.x * k),
                        y: Round(pos.y * k)
                    }
                }
            }
            this.Log("Map Initialized. Scale: " . Round(k, 2) . " (H:" . H . ")")
        } catch {
            MsgBox("Не удалось рассчитать координаты. Используем дефолты.")
            this.ActiveMap := StashMap
        }
    }

    /*
     * Проверка окна игры и активация, загрузка настроек
     */
    static Prepare() {
        if !WinExist(this.TargetWindow) {
            MsgBox("Игра не запущена! (Окно Path of Exile не найдено)", "Ошибка", "Icon!")
            ExitApp()
        }
        WinActivate(this.TargetWindow)
        WinWaitActive(this.TargetWindow, , 2) ; Ждем 2 секунды чтобы ОС отрисовала окно, если оно было неактивно
        this.LoadSettings()
        this.InitializeMap()
    }

    static Log(text) {
        try {
            FileAppend("[" . FormatTime(, "HH:mm:ss") . "] " . text . "`n", this.LogFile, "UTF-8")
        }
    }

    static UseCurrency(currency, item) {
        MouseMove(currency.x, currency.y, 0)
        Sleep(this.FPSDelay)
        Click("Right")
        Sleep(this.PingDelay)
        MouseMove(item.x, item.y, 0)
        Sleep(this.FPSDelay)
        Click("Left")
        Sleep(2 * this.PingDelay + this.FPSDelay)
    }

    /*
     * Проверка наличия валюты в ячейке по цвету (защита от пустых кликов)
     */
    static HasCurrency(currency) {
        color := PixelGetColor(currency.x, currency.y)

        ; Извлекаем RGB
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF

        ; Если сумма каналов меньше EmptySlotIntensity — ячейка считается пустой (темной)
        return (r + g + b > this.EmptySlotIntensity)
    }

    static GetItem(item) {
        maxRetries := 3
        rawText := ""

        Loop maxRetries {
            rawText := this.GetItemDetailedText(item)
            if (rawText != "")
                break
            Sleep(this.PingDelay * 3)
        }

        if (rawText = "") {
            MsgBox(
                "Ошибка: Не удалось скопировать данные предмета.`n`n" .
                "Совет: Увеличьте PingDelay (сейчас: " . this.PingDelay . "мс) или проверьте FPS.",
                "Ошибка копирования", "Icon! 4096"
            )
            return []
        }

        return this.GetFullParsedItem(rawText)
    }

    static GetItemDetailedText(item) {
        A_Clipboard := ""
        MouseMove(item.x, item.y, 0)
        Sleep(this.FPSDelay)
        Send("^!c")
        if !ClipWait(0.5)
            return ""
        return A_Clipboard
    }

    /*
     * Парсинг предмета
     */
    static GetFullParsedItem(itemText) {
        parsedMods := []
        text := StrReplace(itemText, "`r`n", "`n") ; нормализируем переносы, если встречаются `r`n и `n
        lines := StrSplit(text, "`n")

        currentMod := ""

        for index, line in lines {
            line := Trim(line)
            if (line = "") {
				continue
			}
            ; Описание эксплисита начинается с { (Prefix|Suffix) Modifier "(Mod Name)" (Tier: (Tier)) — (Tags) }
            if RegExMatch(line, '\{\s?(Prefix|Suffix)\sModifier\s"(.*?)"\s\(Tier:\s(\d+)\)', &match) {
                if (currentMod != "")
                    parsedMods.Push(currentMod)

                currentMod := {
                    type: match[1],
                    name: match[2],
                    tier: Number(match[3]),
                    desc: ""
                }
                continue
            }

            ; Разделитель блоков ------
            if SubStr(line, 1, 2) = "--" {
                if (currentMod != "") {
                    parsedMods.Push(currentMod)
                    currentMod := ""
                }
                continue
            }

            ; Убираем значения из описания модов
            if IsObject(currentMod) {
                cleanLine := RegExReplace(line, "[\d\-\(\)%+]+", "")
                currentMod.desc .= cleanLine " "
            }
        }

        if IsObject(currentMod)
            parsedMods.Push(currentMod)

        for mod in parsedMods
            mod.desc := Trim(RegExReplace(mod.desc, "\s+", " "))

        return parsedMods
    }

    static GetRarity(itemText) {
        if RegExMatch(itemText, "Rarity: (\w+)", &match)
            return match[1]
        return ""
    }

    static GetItemSummary(itemMods) {
        summary := "Текущие моды:`n"
        for i, mod in itemMods {
            summary .= "[" . mod.type . "] " . mod.name . " (T" . mod.tier . "): " . mod.desc . "`n"
        }
        return summary
    }

    /*
     * Хелпер для отладки: выводит содержимое распарсенных модов
     */
    static Dump(arr) {
        if !IsObject(arr) || (arr.HasProp("Length") && arr.Length = 0)
            return "Предмет не содержит известных модов или ошибка парсинга."

        str := ""
        for i, obj in arr {
            str .= "MOD #" i ": " obj.name " (T" obj.tier ")`n"
            str .= "   DESC: " obj.desc "`n`n"
        }
        return str
    }

    /*
     * Подсчет кол-ва модов, подходящих по фильтрам
     * Fail-fast для сложных модов (например of Shaping)
     */
    static CountMatches(itemMods, filters) {
        matchCount := 0
        for mod in itemMods {
            for f in filters {
                nameMatch := !f.HasProp("name") || (mod.name = f.name)
                if (!nameMatch) {
                    continue
                }
                tierMatch := !f.HasProp("tier") || (mod.tier <= f.tier)
                if (!tierMatch) {
                    continue
                }
                textMatch := !f.HasProp("text") || InStr(mod.desc, f.text)
                if (!textMatch) {
                    continue
                }
                matchCount++
                break
            }
        }
        return matchCount
    }

}

/*
 * Крафт с помощью Orb of Alteration и Orb of Augmentation
 */
class AlterationCrafting {
    static Version        := 1.0
    static MajorV         := 1.0
    static STRATEGY_ANY   := "ANY"
    static STRATEGY_BOTH  := "BOTH"
    static STRATEGY_CLEAN := "CLEAN"
    static RARITY_BLUE    := "Magic"
    /*
     * Оценка предмета на соответствие стратегии (ANY, BOTH, CLEAN)
     */
    static Evaluate(itemMods, filters, strategy := "ANY") {
        matches   := CraftingCore.CountMatches(itemMods, filters)
        totalMods := itemMods.Length

        if (strategy == this.STRATEGY_ANY) {
            return (matches > 0)
        }

        if (strategy == this.STRATEGY_BOTH) {
            return (totalMods == 2 && matches == 2)
        }

        if (strategy == this.STRATEGY_CLEAN) {
            return (matches > 0 && matches == totalMods)
        }

        return false
    }

    /*
     * Дополняем конфиг, если передали не полный
     * Проверяем версию и осмысленность конфига
     */
    static Run(userConf) {
        filteredFilters := userConf.HasProp("Filters") ? this._FilterFilters(userConf.Filters) : []
        conf := {
            Version:     userConf.HasProp("Version")     ? userConf.Version     : this.Version,
            MaxAttempts: userConf.HasProp("MaxAttempts") ? userConf.MaxAttempts : 0, ; 0 = Unlimited
            Strategy:    userConf.HasProp("Strategy")    ? userConf.Strategy    : this.STRATEGY_ANY,
            Filters:     filteredFilters,
            DebugLevel:  userConf.HasProp("DebugLevel")  ? userConf.DebugLevel  : 0
        }

        if (conf.Filters.Length == 0) {
            MsgBox("Ошибка: Список фильтров пуст!")
            ExitApp()
        }

        if (conf.Version < this.MajorV) {
            MsgBox("Рецепт устарел! Требуется v" . this.Version)
            ExitApp()
        }

        this._ExecuteLoop(conf)
    }

    static _FilterFilters(filters) {
        validFilters := []
        for f in filters {
            ; Проверяем, что это объект и в нем есть ключ name или text
            hasName := f.HasProp("name") && Trim(f.name) != ""
            hasText := f.HasProp("text") && Trim(f.text) != ""

            if (hasName || hasText) {
                validFilters.Push(f)
            } else {
                CraftingCore.Log("WARNING: Skipped empty filter at index " . A_Index)
            }
        }
        return validFilters
    }

    static _ExecuteLoop(conf) {
        CraftingCore.Prepare()
        CraftingCore.DebugLevel := conf.DebugLevel
        CraftingCore.Log("--- STARTING NEW SESSION (Strategy: " . conf.Strategy . ") ---")
        this._CheckInitialState(conf)
        consecutiveErrors := 0
        maxErrors         := 3
        Loop (conf.MaxAttempts > 0 ? conf.MaxAttempts : 100000) {
            if !CraftingCore.HasCurrency(CraftingCore.ActiveMap.Alteration) {
                CraftingCore.Log("STOP: Out of Alterations")
                MsgBox("Закончились альты!")
                ExitApp()
            }

            CraftingCore.UseCurrency(CraftingCore.ActiveMap.Alteration, CraftingCore.ActiveMap.CraftItem)
            item := CraftingCore.GetItem(CraftingCore.ActiveMap.CraftItem)
            if (item.Length == 0) {
                consecutiveErrors++
                if (consecutiveErrors >= maxErrors) {
                    CraftingCore.Log("FATAL: " maxErrors " empty reads in a row. Is the item missing?")
                    MsgBox("Ошибка: Предмет не читается или пуст слишком долго. Проверьте сташ!", "Критическая ошибка", "Icon!")
                    ExitApp()
                }
        		continue
        	}
        	consecutiveErrors := 0

        	summary := CraftingCore.GetItemSummary(item)
            if (conf.DebugLevel > 0) {
                CraftingCore.Log("Step " A_Index " (ALT): " StrReplace(summary, "`n", " | "))
            }

            this._CheckSuccess(item, conf, "Успех достигнут на шаге " . A_Index . "!`n`n", "SUCCESS on step " . A_Index)

            if (this._ShouldAugment(item, conf)) {
                CraftingCore.UseCurrency(CraftingCore.ActiveMap.Augmentation, CraftingCore.ActiveMap.CraftItem)
                updatedItem := CraftingCore.GetItem(CraftingCore.ActiveMap.CraftItem)
                this._CheckSuccess(updatedItem, conf, "Успех достигнут на шаге " . A_Index . "!`n`n", "SUCCESS on step " . A_Index)
            }

        }

        if (A_Index == conf.MaxAttempts) {
            CraftingCore.Log("FAILED: Reached MaxAttempts (" conf.MaxAttempts ")")
            MsgBox("Лимит попыток исчерпан.")
            ExitApp()
        }
    }

    static _CheckInitialState(conf) {
        ToolTip("Проверка текущего состояния предмета...")

        parsedItem := CraftingCore.GetItem(CraftingCore.ActiveMap.CraftItem)
        rarity     := CraftingCore.GetRarity(CraftingCore.GetItemDetailedText(CraftingCore.ActiveMap.CraftItem))

        if (rarity != this.RARITY_BLUE) {
            summary := CraftingCore.GetItemSummary(parsedItem)
            CraftingCore.Log("PRE-CHECK FAILURE: Item is not magic. " . StrReplace(summary, "`n", " | "))
            MsgBox("Предмет не является магическим!`n`n" . summary, "Ошибка", "Icon! 4096")
            ExitApp()
        }

        this._CheckSuccess(parsedItem, conf, "Предмет УЖЕ подходит под фильтры!`n`n", "PRE-CHECK SUCCESS: Item already matches filters. ")
        this._InitialAugmentation(parsedItem, conf)

        ToolTip()
    }

    static _InitialAugmentation(item, conf) {
        if this._ShouldAugment(item, conf) {
            CraftingCore.UseCurrency(CraftingCore.ActiveMap.Augmentation, CraftingCore.ActiveMap.CraftItem)
            updatedItem := CraftingCore.GetItem(CraftingCore.ActiveMap.CraftItem)
            this._CheckSuccess(updatedItem, conf, "Успех достигнут!`n`n", "SUCCESS on Initial Augmentation")
        }
    }
    
    static _ShouldAugment(item, conf) {
        canAugment := item.Length < 2 && CraftingCore.HasCurrency(CraftingCore.ActiveMap.Augmentation)
        if (!canAugment) {
            return false
        }
        if (conf.Strategy = this.STRATEGY_CLEAN) {
            return item.Length == 0 ; если начали с предмета, заануленного в 0
        }
        if (conf.Strategy = this.STRATEGY_ANY) {
            return true
        }
        if (conf.Strategy = this.STRATEGY_BOTH) {
            return CraftingCore.CountMatches(item, conf.Filters) == item.Length
        }
        return false
    }

    static _CheckSuccess(item, conf, message, logMessage) {
        if this.Evaluate(item, conf.Filters, conf.Strategy) {
            summary := CraftingCore.GetItemSummary(item)
            CraftingCore.Log(logMessage . StrReplace(summary, "`n", " | "))
            MsgBox(message . summary, "Успех", "Iconi")
            ExitApp()
        }
    }
}

class StashMap {
	static Transmutation := {x:  75, y: 370}
	static Alteration    := {x: 150, y: 370}
	static Annulment     := {x: 225, y: 370}
	static Chance        := {x: 300, y: 370}
	static Augmentation  := {x: 300, y: 445}

	static Exalted       := {x: 400, y: 370}

	static Regal         := {x: 580, y: 370}
	static Alchemy       := {x: 655, y: 370}
	static Chaos         := {x: 730, y: 370}
	static Blessing      := {x: 805, y: 370}

	static Jewellers     := {x: 150, y: 535}
	static Fusing        := {x: 225, y: 535}
	static Chromatic     := {x: 300, y: 535}

	static Scouring      := {x: 580, y: 535}

	static Whetstone     := {x: 580, y: 275}
	static Scrap         := {x: 655, y: 275}

	static CraftItem     := {x: 445, y: 615}
}

; Горячая клавиша для экстренной остановки
F4:: {
	CraftingCore.Log("SCRIPT STOPPED BY USER (F4)")
	ToolTip("Script Terminated")
	Sleep(1000)
	ExitApp()
}