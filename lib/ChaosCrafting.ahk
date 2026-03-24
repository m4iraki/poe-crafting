#Requires AutoHotkey v2.0

class ChaosCrafting {

    static Run(conf) {
        conf := this._PrepareConf(conf)
        result := this.ExecuteLoop(conf)
        switch result.exec {
            case Util.EXECUTE_SUCCESS:
                Util.SuccessWithMessageAndLog(
                    "Успех достигнут на шаге " result.steps "!`n`n" result.item.ToString(),
                    "SUCCESS on step " result.steps ": " Util.ReplaceNewLines(result.item.ToString())
                )
            case Util.EXECUTE_OUT_OF_CURRENCY:
                Util.FailWithMessageAndLog(
                    "Закончились хаосы!",
                    "FAILED: Out of " Currencies.Chaos.name
                )
            case this.EXEC_CANNOT_MAKE_RARE:
                Util.FailWithMessageAndLog(
                    "Не могу сделать предмет редким!",
                    "FAILED: Cannot make item rare"
                )
            case Util.EXECUTE_NOT_A_CRAFTABLE_ITEM:
                Util.FailWithMessageAndLog(
                    "Предмет неподходящей редкости!",
                    "FAILED: " Util.EXECUTE_NOT_A_CRAFTABLE_ITEM
                )
        }
    }

    static EVAL_MAKE_WHITE_TO_RARE := "Make white to rare" ; alch | trans + regal
    static EVAL_MAKE_BLUE_TO_RARE := "Make blue to rare" ; regal | scour + alch if not fractured?
    static EVAL_NOT_A_CRAFTABLE_ITEM := "Not a craftable item"

    static EVAL_EXALTED := "Exalted"
    static EVAL_CHAOS := "Chaos"
    static EVAL_SUCCESS := "Success"

    static Evaluate(item, conf) {
        switch item.rarity {
            case ItemData.RARITY_WHITE:
                return this.EVAL_MAKE_WHITE_TO_RARE
            case ItemData.RARITY_BLUE:
                ; todo Проверить, можно ли из текущего состояния выиграть регалом
                return this.EVAL_MAKE_BLUE_TO_RARE
            case ItemData.RARITY_GOLD:
                matches := Core.PartitionMatches(item, conf.RequiredFilters)
                hasExclusion := Util.ArrExists(matches.unfit, (mod) => Core.ModMatchesFilters(mod, conf.ExcludeFilters))
                if (hasExclusion) {
                    return this.EVAL_CHAOS
                }
                return (matches.fit.Length >= conf.MinMatches) ? this.EVAL_SUCCESS : this.EVAL_CHAOS
            default:
                return this.EVAL_NOT_A_CRAFTABLE_ITEM
        }
    }

    static EXEC_CANNOT_MAKE_RARE := "Cannot make item Rare"
    static ExecuteLoop(conf) {
        step := 0

        item := Core.GetItem(Stash.CraftItem)
        eval := this.Evaluate(item, conf)

        chaos := Stash.Get(Currencies.Chaos)
        scouring := Stash.Get(Currencies.Scouring)
        transmute := Stash.Get(Currencies.Transmutation)
        regal := Stash.Get(Currencies.Regal)
        alchemy := Stash.Get(Currencies.Alchemy)
        exalted := Stash.Get(Currencies.Exalted)

        loop {
            switch eval {
                case this.EVAL_SUCCESS:
                    return { exec: Util.EXECUTE_SUCCESS, item: item, steps: step }
                case this.EVAL_NOT_A_CRAFTABLE_ITEM:
                    return { exec: Util.EXECUTE_NOT_A_CRAFTABLE_ITEM, item: item, steps: step }
                case this.EVAL_CHAOS:
                    if (chaos.Count > conf.MinChaos) {
                        item := chaos.Use(Stash.CraftItem)
                        step++
                        eval := this.Evaluate(item, conf)
                        continue
                    } else {
                        return { exec: Util.EXECUTE_OUT_OF_CURRENCY, item: item, steps: step }
                    }
                case this.EVAL_MAKE_WHITE_TO_RARE:
                    if (alchemy.Exists()) {
                        item := alchemy.Use(Stash.CraftItem)
                        eval := this.Evaluate(item, conf)
                        continue
                    } else {
                        if (transmute.Exists() && regal.Exists()) {
                            transmute.Use(Stash.CraftItem)
                            item := regal.Use(Stash.CraftItem)
                            eval := this.Evaluate(item, conf)
                            continue
                        } else {
                            return { exec: this.EXEC_CANNOT_MAKE_RARE, item: item, steps: step }
                        }
                    }
                case this.EVAL_MAKE_BLUE_TO_RARE:
                    if (regal.Exists()) {
                        item := regal.Use(Stash.CraftItem)
                        eval := this.Evaluate(item, conf)
                        continue
                    } else {
                        if (scouring.Exists() && alchemy.Exists()) {
                            scouring.Use(Stash.CraftItem)
                            item := alchemy.Use(Stash.CraftItem)
                            eval := this.Evaluate(item, conf)
                            continue
                        } else {
                            return { exec: this.EXEC_CANNOT_MAKE_RARE, item: item, steps: step }
                        }
                    }
            }
        }
    }

    static _PrepareConf(conf) {
        return {
            RequiredFilters: Util.PropOrDefault(conf, "RequiredFilters", []),
            ExcludeFilters: Util.PropOrDefault(conf, "ExcludeFilters", []),
            MinMatches: Util.MinMax(1, 6, Util.PropOrDefault(conf, "MinMatches", 1)),
            ; MaxMatches: Util.MinMax(1, 6, Util.PropOrDefault(conf, "MaxMatches", 6)),
            ; EmptyPrefix: Util.PropOrDefault(conf, "EmptyPrefix", false),
            ; EmptySuffix: Util.PropOrDefault(conf, "EmptySuffix", false),
            ; UseExalted: Util.PropOrDefault(conf, "UseExalted", false),
            MinChaos: Max(0, Util.PropOrDefault(conf, "MinChaos", 0)),
            ; MinExalted: Max(0, Util.PropOrDefault(conf, "MinExalted", 0)),
        }
    }
}
