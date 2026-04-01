#Requires AutoHotkey v2.0

class Core {

    static GetItem(item) {
        maxRetries := 3
        rawText := ""

        loop maxRetries {
            rawText := this.GetItemDetailedText(item)
            if (rawText != "")
                break
            Sleep(Config.PingDelay * 3)
        }

        if (rawText = "") {
            Util.FailWithMessage(
                "Ошибка: Не удалось скопировать данные предмета.`n`n" .
                "Совет: Увеличьте PingDelay (сейчас: " . Config.PingDelay . "мс) или проверьте FPS."
            )
        }

        return this.GetFullParsedItem(rawText)
    }

    static GetItemDetailedText(item) {
        A_Clipboard := ""
        MouseMove(item.centerX, item.centerY, 0)
        Sleep(Config.FPSDelay)
        Send("^!c")
        if !ClipWait(0.5)
            return ""
        return A_Clipboard
    }

    static GetFullParsedItem(itemText) {
        parsedMods := []
        lines := Util.SplitNormalize(itemText)
        rarity := this.GetRarity(itemText)
        name := ""
        if RegExMatch(itemText, "m)^([^:^-][^:\r\n]+)$(*ACCEPT)", &names) {
            name := names[1]
        }
        ilvl := ""
        if RegExMatch(itemText, "m)^Item Level: (\d+)$(*ACCEPT)", &levels) {
            ilvl := levels[1]
        }

        currentMod := ""

        for index, line in lines {
            line := Trim(line)
            if (line = "") {
                continue
            }
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

            if SubStr(line, 1, 2) = "--" {
                if (currentMod != "") {
                    parsedMods.Push(currentMod)
                    currentMod := ""
                }
                continue
            }

            if IsObject(currentMod) {
                currentMod.desc .= line " "
            }
        }

        if IsObject(currentMod)
            parsedMods.Push(currentMod)

        for mod in parsedMods
            mod.desc := Trim(RegExReplace(mod.desc, "\s+", " "))

        return ItemData(name, rarity, parsedMods, ilvl)
    }

    static GetRarity(itemText) {
        if RegExMatch(itemText, "m)^Rarity: (\w+)$(*ACCEPT)", &match)
            return match[1]
        return ""
    }

    static ModMatches(mod, filter) {
        nameMismatch := filter.HasProp("name") && !(mod.name = filter.name)
        if (nameMismatch) {
            return false
        }
        tierMismatch := filter.HasProp("tier") && (mod.tier > filter.tier)
        if (tierMismatch) {
            return false
        }
        textMismatch := filter.HasProp("text") && !InStr(mod.desc, filter.text)
        if (textMismatch) {
            return false
        }
        return true
    }

    static ModMatchesFilters(mod, filters) {
        for f in filters {
            if (this.ModMatches(mod, f)) {
                return true
            }
        }
        return false
    }

    static HasMatches(item, filters) {
        return Util.ArrExists(item.mods, (mod) => this.ModMatchesFilters(mod, filters))
    }

    static CountMatches(item, filters) {
        return Util.ArrCount(item.mods, (mod) => this.ModMatchesFilters(mod, filters))
    }

    static GetMatches(item, filters) {
        return Util.ArrFilter(item.mods, (mod) => this.ModMatchesFilters(mod, filters))
    }

    static PartitionMatches(item, filters) {
        return Util.ArrPartition(item.mods, (mod) => this.ModMatchesFilters(mod, filters))
    }

    static MinMax(value, min, max) {
        Min(max, Max(value, min))
    }
}
