#Requires AutoHotkey v2.0
#SingleInstance

; Без зависимостей
#Include Config.ahk
#Include ItemPosition.ahk
#Include ItemData.ahk
; Базовые зависимости
#Include Util.ahk
#Include UI.ahk
#Include Core.ahk
#Include Stash.ahk
; Конкретные имплементации
#Include AlterationCrafting.ahk
#Include RegalCrafting.ahk
#Include ChaosCrafting.ahk

; Инициализация
Config.Initialize()
UI.Initialize()
Stash.Initialize()


; Горячая клавиша для экстренной остановки
F4:: {
	Util.Log("SCRIPT STOPPED BY USER (F4)")
	ToolTip("Script Terminated")
	Sleep(1000)
	ExitApp()
}
; Пауза
F5:: {
	Pause(-1)
}