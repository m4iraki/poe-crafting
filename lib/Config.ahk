#Requires AutoHotkey v2.0

class Config {
    static TargetWindow := "ahk_class POEWindowClass"

    static BaseHeight := 1080
    static ScaleFactor := 1.0

    static IniFile := "settings.ini"
    static PingDelay := 50 ; Базовая задержка (зависит от пинга)
    static FPSDelay := 30 ; Задержка на отрисовку (зависит от производительности ПК)
    static LogFile := "craft_log.txt"
    static DebugLevel := 0  ; 0 - только итог, 1 - всё подряд

    static Initialize() {
        ; Если файла нет, создаем его с текущими дефолтами
        if !FileExist(this.IniFile) {
            IniWrite(this.PingDelay, this.IniFile, "Delays", "PingDelay")
            IniWrite(this.FPSDelay, this.IniFile, "Delays", "FPSDelay")
            IniWrite(this.LogFile, this.IniFile, "General", "LogFile")
            IniWrite(this.DebugLevel, this.IniFile, "General", "DebugLevel")
        }

        ; Читаем значения из INI
        this.PingDelay := Number(IniRead(this.IniFile, "Delays", "PingDelay", this.PingDelay))
        this.FPSDelay := Number(IniRead(this.IniFile, "Delays", "FPSDelay", this.FPSDelay))
        this.LogFile := IniRead(this.IniFile, "General", "LogFile", this.LogFile)
        this.DebugLevel := Number(IniRead(this.IniFile, "General", "DebugLevel", this.DebugLevel))
    }
}
