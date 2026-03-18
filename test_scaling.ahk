#Requires AutoHotkey v2.0
#Include lib.ahk

/**
 * Тестовый скрипт для визуальной проверки скейлинга.
 * Нажмите F2, чтобы обновить координаты и показать маркеры.
 * Нажмите F3, чтобы скрыть маркеры.
 */

MarkerSize := 10
MarkerColor := "00FF00"

Markers := []

F2:: {
    ClearMarkers()

    try {
        CraftingCore.Prepare()
    } catch {
        MsgBox("Игра не запущена или окно не найдено!")
        return
    }

    for name, pos in CraftingCore.ActiveMap.OwnProps() {
        CreateMarker(pos.x, pos.y, name)
    }
}

F3:: ClearMarkers()

CreateMarker(x, y, label) {
    global Markers, MarkerSize, MarkerColor

    WinGetPos(&winX, &winY, , , "ahk_class POEWindowClass")

    client := {x:0, y:0}

    ClientToScreen(WinExist("ahk_class POEWindowClass"), client)

    m := Gui("+AlwaysOnTop -Caption +ToolWindow")
    m.BackColor := MarkerColor

    m.SetFont("s9 w700", "Segoe UI")

    m.Add("Text", "x0 y0 cBlack Background" . MarkerColor, " " . label . " ")

    absX := client.x + x
    absY := client.y + y

    m.Show("x" . absX . " y" . absY . " NoActivate")
    Markers.Push(m)
}

ClientToScreen(hwnd, pt) {
    static point := Buffer(8)
    NumPut("Int", pt.x, "Int", pt.y, point)
    DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", point)
    pt.x := NumGet(point, 0, "Int")
    pt.y := NumGet(point, 4, "Int")
}

ClearMarkers() {
    global Markers
    for m in Markers {
        m.Destroy()
    }
    Markers := []
}

F5:: ExitApp()