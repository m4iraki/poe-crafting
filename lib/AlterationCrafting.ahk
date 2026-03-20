#Requires AutoHotkey v2.0

class AlterationCrafting {
    static STRATEGY_ANY := "ANY"
    static STRATEGY_BOTH := "BOTH"
    static STRATEGY_CLEAN := "CLEAN"

    static EVAL_SUCCESS := "Success"
    static EVAL_FAILURE := "Failure"
    static EVAL_AUGMENT := "Augment"
    static Evaluate(item, filters, strategy := this.STRATEGY_ANY) {
        matches := Core.CountMatches(item, filters)
        totalMods := item.mods.Length

        switch strategy {
            case this.STRATEGY_ANY:
                if (matches > 0) {
                    return this.EVAL_SUCCESS
                } else {
                    return (item.mods.Length < 2) ? this.EVAL_AUGMENT : this.EVAL_FAILURE
                }
            case this.STRATEGY_BOTH:
                if (totalMods == 2) {
                    return (matches == 2) ? this.EVAL_SUCCESS : this.EVAL_FAILURE
                } else {
                    return (matches == totalMods) ? this.EVAL_AUGMENT : this.EVAL_FAILURE
                }
            case this.STRATEGY_CLEAN:
                return (matches > 0 && matches == totalMods) ? this.EVAL_SUCCESS : this.EVAL_FAILURE
        }
    }

    static Run(userConf) {
        filteredFilters := userConf.HasProp("Filters") ? this._FilterFilters(userConf.Filters) : []
        maxAttempts := userConf.HasProp("MaxAttempts") ? userConf.MaxAttempts : 0
        strategy := userConf.HasProp("Strategy") ? userConf.Strategy : this.STRATEGY_ANY

        if (filteredFilters.Length == 0) {
            Util.FailWithMessage("Ошибка: Список фильтров пуст!")
        }

        Util.Log("--- STARTING NEW SESSION (Strategy: " . strategy . ") ---")
        alts := Stash.Get(Currencies.Alteration)
        augs := Stash.Get(Currencies.Augmentation)
        result := this.ExecuteLoop(alts, augs, filteredFilters, strategy, maxAttempts)
        switch result.exec {
            case Util.EXECUTE_SUCCESS:
                Util.SuccessWithMessageAndLog(
                    "Успех достигнут на шаге " result.steps "!`n`n" result.item.ToString(),
                    "SUCCESS on step " result.steps ": " Util.ReplaceNewLines(result.item.ToString())
                )
            case Util.EXECUTE_OUT_OF_CURRENCY:
                Util.FailWithMessageAndLog(
                    "Закончились альты!",
                    "FAILED: Out of " Currencies.Alteration.name
                )
            case this.EXECUTE_OUT_OF_ATTEMPTS:
                Util.FailWithMessageAndLog(
                    "Лимит попыток исчерпан.",
                    "FAILED: Reached MaxAttempts"
                )
        }
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

    static EXECUTE_OUT_OF_ATTEMPTS := "Out of attempts"
    static ExecuteLoop(alts, augs, filters, strategy, maxAttempts := 0) {
        consecutiveErrors := 0
        maxErrors := 3

        eval := this._CheckInitialState(filters, strategy, augs)
        item := Core.GetItem(Stash.CraftItem)
        switch eval {
            case this.EVAL_SUCCESS:
                return { exec: Util.EXECUTE_SUCCESS, steps: 0, item: item}
            default:
        }

        loop ((maxAttempts > 0) ? maxAttempts : 100000) {
            if (alts.Count < 1) {
                return { exec: Util.EXECUTE_OUT_OF_CURRENCY, steps: A_Index, item: item}
            }

            item := alts.Use(Stash.CraftItem)

            if (item.empty) {
                consecutiveErrors++
                if (consecutiveErrors >= maxErrors) {
                    Util.FailWithMessageAndLog(
                        "Ошибка: Предмет не читается или отсутствует. Проверьте стeш!",
                        "FATAL: " maxErrors " empty reads in a row. Is the item missing?"
                    )
                }
                continue
            }
            consecutiveErrors := 0
            eval := this.Evaluate(item, filters, strategy)
            switch eval {
                case this.EVAL_AUGMENT:
                    item := augs.Use(Stash.CraftItem)
                    eval := this.Evaluate(item, filters, strategy)
                default:
            }
            switch eval {
                case this.EVAL_SUCCESS:
                    return { exec: Util.EXECUTE_SUCCESS, steps: A_Index, item: item}
                default:
            }
        }

        return { exec: this.EXECUTE_OUT_OF_ATTEMPTS, item: item }
    }

    static _CheckInitialState(filters, strategy, augs) {
        ToolTip("Проверка текущего состояния предмета...")

        item := Core.GetItem(Stash.CraftItem)

        if (item.rarity != ItemData.RARITY_BLUE) {
            transmutes := Stash.Get(Currencies.Transmutation)
            if (transmutes.Count > 0) {
                item := transmutes.Use(Stash.CraftItem)
            } else {
                Util.FailWithMessageAndLog(
                    "Предмет не является магическим и закончились трансмутки!",
                    "FAILURE: Item is not magic and out of " transmutes.currencyType.name ". "
                )
            }
        }
        
        eval := this.Evaluate(item, filters, strategy)
        ToolTip()

        switch eval {
            case this.EVAL_AUGMENT:
                item := augs.Use(Stash.CraftItem)
                return this.Evaluate(item, filters, strategy)
            default:
                return eval
        }
    }
}