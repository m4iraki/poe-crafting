#Requires AutoHotkey v2.0

class ItemData {
    __New(name := "", rarity := "", mods := []) {
        this.name := name
        this.rarity := rarity
        this.mods := mods
        this.empty := name = ""
    }
    ToString() {
        string := this.name "`nRarity: " this.rarity "`n"
        for i, mod in this.mods {
            string .= "[" . mod.type . "] " . mod.name . " (T" . mod.tier . "): " . mod.desc . "`n"
        }
        return string
    }
}