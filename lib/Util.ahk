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

}
