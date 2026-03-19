#Requires AutoHotkey v2.0

; Без зависимостей
#Include Config.ahk
#Include ItemPosition.ahk
; Базовые зависимости
#Include Util.ahk
#Include UI.ahk
#Include Core.ahk
#Include Stash.ahk
; Конкретные имплементации
#Include AlterationCrafting.ahk

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