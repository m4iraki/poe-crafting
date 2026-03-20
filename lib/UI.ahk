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

class HistoryDashboard {
    static gui := ""
    static left := []
    static right := []
    static height := 5
    static totalCount := 0

    static Initialize() {
        if (this.gui != "") {
            return
        }
        scaleFactor := Config.ScaleFactor
        stashItem := Stash.CraftItem

        fontSize := Round(9 * scaleFactor)
        singleLineHeight := (fontSize * 1.33) * 1.2
        contentHeight := Round(singleLineHeight * 6) 
        rowHeight := contentHeight + Round(10 * scaleFactor)

        padding := Round(2 * scaleFactor)
        colWidth := Round(350 * scaleFactor)
        
        windowWidth := (colWidth * 2) + (padding * 3)
        windowHeight := (rowHeight * this.height) + (padding * 2)
        
        posX := stashItem.right - (windowWidth / 2)
        posY := stashItem.bottom + Round(10 * scaleFactor)

        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "ItemHistory")
        this.gui.BackColor := "0A0A0A"
        WinSetTransColor("050505 240", this.gui.Hwnd)
        currentY := padding
        loop this.height {
            this.gui.SetFont("s" fontSize " cFFEEAA", "Consolas")
            this.left.Push(this.gui.Add("Text", "x" padding " y" currentY " w" colWidth " r6 -Wrap", ""))
            this.right.Push(this.gui.Add("Text", "x" (padding*2 + colWidth) " y" currentY " w" colWidth " r8 -WRAP", ""))
            
            currentY += rowHeight
            if (A_Index < this.height) {
                lineY := currentY - Round(8 * scaleFactor)
                this.gui.Add("Progress", "x" padding " y" lineY " w" (windowWidth - padding*2) " h1 Background222222", 0)
            }
        }
        
        this.gui.Add("Progress", "x" (padding + colWidth + padding/2) " y" padding " w1 h" (windowHeight - padding*2) " Background222222", 0)
        this.gui.Show("x" posX " y" posY " NoActivate")
    }

    static AddItem(item) {
        this.Initialize()
        
        currentIndex := Mod(this.totalCount, this.height) + 1
        isSecondColumn := Mod(Floor(this.totalCount / this.height), 2)
        targetArray := isSecondColumn ? this.right : this.left
        
        if (currentIndex == 1) {
            for ctrl in targetArray
                ctrl.Value := ""
        }

        for ctrl in this.left
            ctrl.SetFont("c888888")
        for ctrl in this.right
            ctrl.SetFont("c888888")

        targetArray[currentIndex].SetFont("cFFFFFF") 
        targetArray[currentIndex].Value := item.CompactString()
        
        this.totalCount++
    }
}