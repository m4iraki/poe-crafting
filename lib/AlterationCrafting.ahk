#Requires AutoHotkey v2.0

class AlterationCrafting {
    static STRATEGY_ANY   := "ANY"
    static STRATEGY_BOTH  := "BOTH"
    static STRATEGY_CLEAN := "CLEAN"

    static RARITY_BLUE    := "Magic"

    static Evaluate(item, filters, strategy := "ANY") {
        matches   := Core.CountMatches(item, filters)
        totalMods := item.mods.Length

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

    static Run(userConf) {
        filteredFilters := userConf.HasProp("Filters") ? this._FilterFilters(userConf.Filters) : []
        conf := {
            MaxAttempts: userConf.HasProp("MaxAttempts") ? userConf.MaxAttempts : 0, ; 0 = Unlimited
            Strategy:    userConf.HasProp("Strategy")    ? userConf.Strategy    : this.STRATEGY_ANY,
            Filters:     filteredFilters
        }

        if (conf.Filters.Length == 0) {
            MsgBox("Ошибка: Список фильтров пуст!")
            ExitApp()
        }

        Util.Log("--- STARTING NEW SESSION (Strategy: " . conf.Strategy . ") ---")
        this._ExecuteLoop(conf)
    }

    static _FilterFilters(filters) {
        validFilters := []
        for f in filters {
            hasName := f.HasProp("name") && Trim(f.name) != ""
            hasText := f.HasProp("text") && Trim(f.text) != ""

            if (hasName || hasText) {
                validFilters.Push(f)
            } else {
                Util.Log("WARNING: Skipped empty filter at index " . A_Index)
            }
        }
        return validFilters
    }

    static _ExecuteLoop(conf) {
        consecutiveErrors := 0
        maxErrors         := 3

        alts := Stash.Get(Currencies.Alteration)
        augs := Stash.Get(Currencies.Augmentation)

        alts.Refresh()
        augs.Refresh()
        alts.UpdateUI()
        augs.UpdateUI()

        this._CheckInitialState(conf, augs)

        Loop (conf.MaxAttempts > 0 ? conf.MaxAttempts : 100000) {
            if (alts.Count < 1) {
                Util.Log("STOP: Out of Alterations")
                MsgBox("Закончились альты!")
                ExitApp()
            }

            alts.Use(Stash.CraftItem)
            item := Core.GetItem(Stash.CraftItem)
            if (item.empty) {
                consecutiveErrors++
                if (consecutiveErrors >= maxErrors) {
                    Util.Log("FATAL: " maxErrors " empty reads in a row. Is the item missing?")
                    MsgBox("Ошибка: Предмет не читается или пуст слишком долго. Проверьте сташ!", "Критическая ошибка", "Icon!")
                    ExitApp()
                }
        		continue
        	}
        	consecutiveErrors := 0

            if (Config.DebugLevel > 0) {
                Util.Log("Step " A_Index " (ALT): " Util.ReplaceNewLines(item.ToString()))
            }

            this._CheckSuccess(item, conf, "Успех достигнут на шаге " . A_Index . "!`n`n", "SUCCESS on step " . A_Index)

            if (augs.Count > 0 && this._ShouldAugment(item, conf)) {
                augs.Use(Stash.CraftItem)
                item := Core.GetItem(Stash.CraftItem)
                if (Config.DebugLevel > 0) {
                    Util.Log("Step " A_Index " (AUG): " Util.ReplaceNewLines(item.ToString()))
                }
                this._CheckSuccess(item, conf, "Успех достигнут на шаге " . A_Index . "!`n`n", "SUCCESS on step " . A_Index)
            }

        }

        Util.Log("FAILED: Reached MaxAttempts (" conf.MaxAttempts ")")
        MsgBox("Лимит попыток исчерпан.")
        ExitApp()
    }

    static _CheckInitialState(conf, augs) {
        ToolTip("Проверка текущего состояния предмета...")

        item   := Core.GetItem(Stash.CraftItem)

        if (item.rarity != this.RARITY_BLUE) {
            Util.Log("PRE-CHECK FAILURE: Item is not magic. " . Util.ReplaceNewLines(item.ToString()))
            MsgBox("Предмет не является магическим!`n`n" . item.ToString(), "Ошибка", "Icon! 4096")
            ExitApp()
        }

        this._CheckSuccess(item, conf, "Предмет УЖЕ подходит под фильтры!`n`n", "PRE-CHECK SUCCESS: Item already matches filters. ")

        if (augs.Count > 0 && this._ShouldAugment(item, conf)) {
            augs.Use(Stash.CraftItem)
            item := Core.GetItem(Stash.CraftItem)
            this._CheckSuccess(item, conf, "Успех достигнут!`n`n", "SUCCESS on Initial Augmentation")
        }

        ToolTip()
    }
    
    static _ShouldAugment(item, conf) {
        if (conf.Strategy = this.STRATEGY_CLEAN) {
            return item.mods.Length == 0 ; если начали с предмета, заануленного в 0
        }
        if (conf.Strategy = this.STRATEGY_ANY) {
            return item.mods.Length < 2
        }
        if (conf.Strategy = this.STRATEGY_BOTH) {
            return Core.CountMatches(item, conf.Filters) == item.mods.Length
        }
        return false
    }

    static _CheckSuccess(item, conf, message, logMessage) {
        if this.Evaluate(item, conf.Filters, conf.Strategy) {
            Util.Log(logMessage . Util.ReplaceNewLines(item.ToString()))
            MsgBox(message . item.ToString(), "Успех", "Iconi")
            ExitApp()
        }
    }
}