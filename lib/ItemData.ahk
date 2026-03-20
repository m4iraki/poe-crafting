#Requires AutoHotkey v2.0

class ItemData {
    static PrefixesStr := "Prefixes"
    static SuffixesStr := "Suffixes"
    __New(name := "", rarity := "", mods := []) {
        this.name := name
        this.rarity := rarity
        this.mods := mods
        this.empty := name = ""
        this.prefixes := []
        this.suffixes := []
        for i, mod in mods {
            if (mod.type == "Prefix") {
                this.prefixes.Push(mod)
            }
            if (mod.type == "Suffix") {
                this.suffixes.Push(mod)
            }
        }
    }
    ToString() {
        string := this.name "`nRarity: " this.rarity "`n"
        for i, mod in this.mods {
            string .= "[" . mod.type . "] " . mod.name . " (T" . mod.tier . "): " . mod.desc . "`n"
        }
        return string
    }

    CompactString() {
        prefixes := Util.ModsMapCompact(this.prefixes)
        prefixPadding := Max(prefixes.width, StrLen(ItemData.PrefixesStr))
        suffixes := Util.ModsMapCompact(this.suffixes)
        suffixPadding := Max(suffixes.width, StrLen(ItemData.SuffixesStr))

        string := this.name "`nRarity: " this.rarity "`n" Util.PadRight("Prefixes", prefixPadding) "| " Util.PadRight("Suffixes", suffixPadding) "`n"
        rows := Max(this.prefixes.Length, this.suffixes.Length)
        idx := 1
        loop rows {
            prefStr := (prefixes.strings.Length >= idx) ? prefixes.strings[idx] : ""
            sufStr := (suffixes.strings.Length >= idx) ? suffixes.strings[idx] : ""
            str := Util.PadRight(prefStr, prefixPadding) "| " Util.PadRight(sufStr, suffixPadding)
            string .= str "`n"
            idx++
        }
        return string
    }

}
