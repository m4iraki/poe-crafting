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

    static SUCCESS := "Успех"
    static ICON_OK := "Iconi"
    static ERROR := "Ошибка"
    static ICON_ERROR := "Icon! 4096"

    static ExitWithMessage(message, success) {
        MsgBox(
            message,
            success ? this.SUCCESS : this.ERROR,
            success ? this.ICON_OK : this.ICON_ERROR
        )
        ExitApp()
    }

    static ExitWithMessageAndLog(message, logMessage := "", success := true) {
        logMessage := (logMessage == "") ? message : logMessage
        this.Log(logMessage)
        this.ExitWithMessage(message, success)
    }

    static SuccessWithMessage(message) {
        this.ExitWithMessage(message, true)
    }

    static FailWithMessage(message) {
        this.ExitWithMessage(message, false)
    }

    static SuccessWithMessageAndLog(message, logMessage := "") {
        this.ExitWithMessageAndLog(message, logMessage, true)
    }
    
    static FailWithMessageAndLog(message, logMessage := "") {
        this.ExitWithMessageAndLog(message, logMessage, false)
    }
}
