#Requires AutoHotkey v2.0

class UI {

    static Initialize() {
        if !WinExist(Config.TargetWindow) {
            MsgBox("Игра не запущена! (Окно Path of Exile не найдено)", "Ошибка", "Icon!")
            ExitApp()
        }
        WinActivate(Config.TargetWindow)
        WinWaitActive(Config.TargetWindow, , 2)
        
        WinGetClientPos(,, &W, &H, Config.TargetWindow)
        Config.ScaleFactor := H / Config.BaseHeight
    }

    static CreateFrame(pos, count) {
        hwnd := WinExist("ahk_class POEWindowClass")
        if !hwnd {
            return
        }
        WinGetClientPos(,,, &winH, hwnd)

        scaleFactor := Config.ScaleFactor
        border := Max(1, Round(2 * scaleFactor))

        rect := this.GetClientPos(hwnd)
        absX := rect.x + pos.x
        absY := rect.y + pos.y

        m := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000 +LastFound")
        m.BackColor := "EEAA99"
        WinSetTransColor("EEAA99", m.Hwnd)

        frameColor := "ffffff"
        m.Add("Text", "x0 y0 w" pos.w " h" border " Background" frameColor)
        m.Add("Text", "x0 y" (pos.h - border) " w" pos.w " h" border " Background" frameColor)
        m.Add("Text", "x0 y0 w" border " h" pos.h " Background" frameColor)
        m.Add("Text", "x" (pos.w - border) " y0 w" border " h" pos.h " Background" frameColor)

        fontSize := Max(8, Round(10 * scaleFactor))
        m.SetFont("s" fontSize " w700", "Segoe UI")

        textW := Round(35 * scaleFactor)
        textX := pos.w - border - textW - 2
        textY := pos.h - border - fontSize - 8

        m.Add("Text", "vCountShadow c000000 x" (textX+1) " y" (textY+1) " w" textW " Right BackgroundTrans", "0")
        m.Add("Text", "vCount cWhite x" textX " y" textY " w" textW " Right BackgroundTrans", "0")

        m.Show("x" absX " y" absY " w" pos.w " h" pos.h " NoActivate")
        return m
    }

    static GetClientPos(hwnd) {
        point := Buffer(8, 0)
        DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", point)
        return { x: NumGet(point, 0, "Int"), y: NumGet(point, 4, "Int") }
    }

    static ItemHistory() {
        
    }
}