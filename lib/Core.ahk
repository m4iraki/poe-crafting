#Requires AutoHotkey v2.0

class Core {

    static GetItem(item) {
        maxRetries := 3
        rawText := ""

        Loop maxRetries {
            rawText := this.GetItemDetailedText(item)
            if (rawText != "")
                break
            Sleep(Config.PingDelay * 3)
        }

        if (rawText = "") {
            MsgBox(
                "Ошибка: Не удалось скопировать данные предмета.`n`n" .
                "Совет: Увеличьте PingDelay (сейчас: " . Config.PingDelay . "мс) или проверьте FPS.",
                "Ошибка копирования", "Icon! 4096"
            )
            return []
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

        return parsedMods
    }

    static GetRarity(itemText) {
        if RegExMatch(itemText, "m)^Rarity: (\w+)$(*ACCEPT)", &match)
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