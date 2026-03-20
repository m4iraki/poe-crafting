#Requires AutoHotkey v2.0

class Util {
    static Log(text) {
        try {
            FileAppend("[" . FormatTime(, "HH:mm:ss") . "] " . text . "`n", Config.LogFile, "UTF-8")
        }
    }

    static MClick(target, button) {
        MouseMove(target.centerX, target.centerY, 0)
        Sleep(Config.FPSDelay)
        Click(button)
        Sleep(Config.PingDelay)
    }
    static ReplaceNewLines(string) {
        return StrReplace(string, "`n", " | ")
    }

    static SplitNormalize(string) {
        text := StrReplace(string, "`r`n", "`n") ; нормализируем переносы, если встречаются `r`n и `n
        return StrSplit(text, "`n")
    }

    static ModsMapCompact(mods) {
        width := 0
        strings := []
        for i, mod in mods {
            string := mod.name " (T " mod.tier ")"
            width := Max(width, StrLen(string))
            strings.Push(string)
        }
        return { strings: strings, width: width }
    }

    static PadRight(str, length, min := 0, char := " ") {
        loop Max(min, length - StrLen(str)) {
            str .= char
        }
        return str
    }
}
