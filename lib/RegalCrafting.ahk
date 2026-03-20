#Requires AutoHotkey v2.0

class RegalCrafting {
    static STRATEGY_3ANY := { name: "3ANY", count: 3, p: 1, s: 1 }
    static STRATEGY_2P1S := { name: "2P1S", count: 3, p: 2, s: 1 }
    static STRATEGY_1P2S := { name: "1P2S", count: 3, p: 1, s: 2 }

    static STRATEGY_2ANY := { name: "2ANY", count: 2, p: 0, s: 0 }
    static STRATEGY_2P0S := { name: "2P0S", count: 2, p: 2, s: 0 }
    static STRATEGY_0P2S := { name: "0P2S", count: 2, p: 0, s: 2 }
    static STRATEGY_1P1S := { name: "1P1S", count: 2, p: 1, s: 1 }

    static STRATEGY_1ANY := { name: "1ANY", count: 1, p: 0, s: 0 }
    static STRATEGY_1P0S := { name: "1P0S", count: 1, p: 1, s: 0 }
    static STRATEGY_0P1S := { name: "0P1S", count: 1, p: 0, s: 1 }

    static Run(conf) {
        mandatoryFilters := this._FilterFilters(conf.MandatoryFilters)
        niceFilters := this._FilterFilters(conf.NiceFilters, mandatoryFilters)
        allFilters := []
        allFilters.Push(mandatoryFilters*)
        allFilters.Push(niceFilters*)
        altFilters := (conf.MandatoryStrategy.count == 3) ? mandatoryFilters : allFilters
        altStrategy := (conf.NiceStrategy.count == 3) ? AlterationCrafting.STRATEGY_BOTH : AlterationCrafting.STRATEGY_ANY
        conf := {
            MandatoryFilters: mandatoryFilters,
            NiceFilters: niceFilters,
            AllFilters: allFilters,
            MandatoryStrategy: conf.MandatoryStrategy,
            NiceStrategy: conf.NiceStrategy,
            MinCount: Max(conf.MandatoryStrategy.count, conf.NiceStrategy.count),
            MinPref: Max(conf.MandatoryStrategy.p, conf.NiceStrategy.p),
            MinSuff: Max(conf.MandatoryStrategy.s, conf.NiceStrategy.s),
            AltFilters: altFilters,
            AltStrategy: altStrategy,
        }
        this._CheckStrat(conf)
        result := this.ExecuteLoop(conf)
        switch result.exec {
            case Util.EXECUTE_SUCCESS:
                Util.SuccessWithMessageAndLog(
                    "Успех достигнут на шаге " result.steps "!`n`n" result.item.ToString(),
                    "SUCCESS on step " result.steps ": " Util.ReplaceNewLines(result.item.ToString())
                )
            case Util.EXECUTE_OUT_OF_CURRENCY:
                Util.FailWithMessageAndLog(
                    "Закончились регалы или скоринги!",
                    "FAILED: Out of " Currencies.Regal.name " or " Currencies.Scouring.name
                )
            case this.EXECUTE_OUT_OF_ALTS:
                Util.FailWithMessageAndLog(
                    "Закончились альты!",
                    "FAILED: Out of " Currencies.Alteration.name
                )
        }
    }


    static EXECUTE_OUT_OF_ALTS := "Out of Alterations"
    static ExecuteLoop(conf) {
        regal := Stash.Get(Currencies.Regal)
        scour := Stash.Get(Currencies.Scouring)
        aug := Stash.Get(Currencies.Augmentation)
        alt := Stash.Get(Currencies.Alteration)
        item :=  Core.GetItem(Stash.CraftItem)
        steps := 0

        if (regal.Count <= 0 || scour.Count <= 0) {
            return { exec: Util.EXECUTE_OUT_OF_CURRENCY, steps: steps, item: item }
        }
        
        Loop {
            eval := this.Evaluate(item, conf)
            switch eval {
                case this.EVAL_AUG:
                    if (aug.Count > 0) {
                        item := aug.Use(Stash.CraftItem)
                        steps++
                        continue
                    } else {
                        if (alt.Count > 0) {
                            item := alt.Use(Stash.CraftItem)
                            steps++
                            continue
                        } else {
                            return { exec: this.EXECUTE_OUT_OF_ALTS, steps: steps, item: item }
                        }
                    }
                case this.EVAL_ALT:
                    altResult := AlterationCrafting.ExecuteLoop(alt, aug, conf.AltFilters, conf.AltStrategy)
                    if (altResult.HasProp("steps")) {
                        steps += altResult.steps
                    }
                    switch altResult.exec {
                        case Util.EXECUTE_OUT_OF_CURRENCY:
                            return { exec: this.EXECUTE_OUT_OF_ALTS, steps: steps, item: altResult.item }
                        case Util.EXECUTE_SUCCESS:
                            item := altResult.item
                            continue
                    }
                case this.EVAL_SUCCESS:
                    return { exec: Util.EXECUTE_SUCCESS, steps: steps, item: item }
                case this.EVAL_FAILURE:
                    if (scour.Count > 0) {
                        item := scour.Use(Stash.CraftItem)
                        steps++
                        continue
                    } else {
                        return { exec: Util.EXECUTE_OUT_OF_CURRENCY, steps: steps, item: item }
                    }
                case this.EVAL_REGAL:
                    if (regal.Count > 0) {
                        item := regal.Use(Stash.CraftItem)
                        steps++
                        continue
                    } else {
                        return { exec: Util.EXECUTE_OUT_OF_CURRENCY, steps: steps, item: item }
                    }
            }
        }
    }

    static EVAL_SUCCESS := "Success"
    static EVAL_FAILURE := "Failure"
    static EVAL_ALT := "AlterationCrafting"
    static EVAL_REGAL := "Regal"
    static EVAL_AUG := "Augment"
    static Evaluate(item, conf) {
        switch item.rarity {
            case ItemData.RARITY_WHITE:
                return this.EVAL_ALT
            case ItemData.RARITY_BLUE:
                canSucceedMagic := conf.MinCount <= 2 && conf.MinPref <= 1 && conf.MinSuff <= 1

                mandatoryMatches := Core.CountMatches(item, conf.MandatoryFilters)
                allMatches := Core.CountMatches(item, conf.AllFilters)

                magicSuccess := canSucceedMagic
                    && (mandatoryMatches >= conf.MandatoryStrategy.count)
                    && (allMatches >= conf.NiceStrategy.count)
                
                regalMaySuccess := (allMatches >= conf.NiceStrategy.count - 1)
                    && (mandatoryMatches >= conf.MandatoryStrategy.count - 1)
                
                augMaySuccess := (item.mods.Length <= 1)
                    && (allMatches >= conf.NiceStrategy.count - 2)
                    && (mandatoryMatches >= conf.MandatoryStrategy.count - 2)

                ;MsgBox("canSucceedMagic " canSucceedMagic 
                ;    . "`nmagicSuccess " magicSuccess
                ;    . "`nregalMaySuccess " regalMaySuccess
                ;    . "`naugMaySuccess " augMaySuccess
                ;    . "`nmandatoryMatches " mandatoryMatches
                ;    . "`nallMatches " allMatches)
                switch {
                    case magicSuccess:
                        return this.EVAL_SUCCESS
                    case augMaySuccess:
                        return this.EVAL_AUG
                    case regalMaySuccess:
                        return this.EVAL_REGAL
                    default:
                        return this.EVAL_FAILURE
                }
            case ItemData.RARITY_GOLD:
                matches := Core.GetMatches(item, conf.MandatoryFilters)
                if (matches.Length < conf.MandatoryStrategy.count) {
                    return this.EVAL_FAILURE
                }
                prefixes := Util.ArrCount(matches, (mod) => mod.type == ItemData.PREFIX)
                suffixes := Util.ArrCount(matches, (mod) => mod.type == ItemData.SUFFIX)
                if (prefixes < conf.MandatoryStrategy.p || suffixes < conf.MandatoryStrategy.p) {
                    return this.EVAL_FAILURE
                }

                matches := Core.GetMatches(item, conf.AllFilters)
                if (matches.Length < conf.NiceStrategy.count) {
                    return this.EVAL_FAILURE
                }
                prefixes := Util.ArrCount(matches, (mod) => mod.type == ItemData.PREFIX)
                suffixes := Util.ArrCount(matches, (mod) => mod.type == ItemData.SUFFIX)
                if (prefixes < conf.NiceStrategy.p || suffixes < conf.NiceStrategy.p) {
                    return this.EVAL_FAILURE
                }

                return this.EVAL_SUCCESS
        }
    }

    static _FilterFilters(filters, higherLevelFilters := []) {
        validFilters := []
        for f in filters {
            name := f.HasProp("name") ? Trim(f.name) : ""
            hasName := name != ""
            text := f.HasProp("text") ? Trim(f.text) : ""
            hasText := text != ""
            inHigher := false
            for hlFilter in higherLevelFilters {
                hlname := hlFilter.HasProp("name") ? Trim(hlFilter.name) : ""
                hltext := hlFilter.HasProp("text") ? Trim(hlFilter.text) : ""
                if (hlname == name && hltext == text) { ; can overlap?
                    inHigher := true
                    break
                }
            }
            if (inHigher) {
                continue
            }
            if (hasName || hasText) {
                validFilters.Push(f)
            } else {
                Util.Log("WARNING: Skipped empty filter at index " . A_Index)
            }
        }
        return validFilters
    }

    static _CheckStrat(conf) {
        if (conf.MandatoryFilters.Length < conf.MandatoryStrategy.count) {
            Util.FailWithMessage("Выбранная стратегия " conf.MandatoryStrategy.name " предполагает большее кол-во необходимых модов, чем указано в конфиге!"
            )
        }
        if (conf.NiceFilters.Length + conf.MandatoryFilters.Length < conf.NiceStrategy.count) {
            Util.FailWithMessage("Выбранная стратегия " conf.NiceStrategy.name "предполагает большее кол-во желаемых модов, чем указано в конфиге!"
            )
        }

        strategyMismatch := Min(conf.MinPref, conf.MinSuff) == 2
        if (strategyMismatch) {
            Util.FailWithMessage("Выбранные стратегии " conf.MandatoryStrategy.name " и " conf.NiceStrategy.name " несовместимы!"
            )
        }
    }
}
