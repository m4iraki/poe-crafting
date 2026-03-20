#Requires AutoHotkey v2.0

class Stash {

    static _RawSlotSize := 53
	static _RawCraftItem := { x: 285, y: 370, w: 97, h: 182 }

	static Currencies := Map()
	static CraftItem := unset
	static IsInitialized := false

	static Initialize() {
		if (this.IsInitialized) {
			return
		}

		scaleFactor := Config.ScaleFactor

		for propName, currencyType in Currencies.OwnProps() {
            if (currencyType.HasProp("rawX") && currencyType.HasProp("rawY") && currencyType.HasProp("name")) {
			    pos := ItemPosition(currencyType.rawX, currencyType.rawY, this._RawSlotSize, this._RawSlotSize, scaleFactor)
			    this.Currencies[currencyType] := CurrencyItem(currencyType, pos)
            }
		}
		this.CraftItem := ItemPosition(this._RawCraftItem.x, this._RawCraftItem.y, this._RawCraftItem.w, this._RawCraftItem.h, scaleFactor)

		this.IsInitialized := true
	}

	static Get(currencyType) {
		if (this.IsInitialized) {
			this.Initialize()
		}
		if (this.Currencies.Has(currencyType)) {
            currency := this.Currencies[currencyType]
            currency.Refresh()
            currency.UpdateUI() 
			return currency
		}

		MsgBox("Не найдена запись '" (currencyType.name) "' в Stash")
	}
	static GetStashItem() {
		if (this.IsInitialized) {
			this.Initialize()
		}
		return this.CraftItem
	}
}

class CurrencyType {
	__New(name, rawX, rawY) {
		this.name := name
		this.rawX := rawX
		this.rawY := rawY
	}
}

class Currencies {
	static Transmutation := CurrencyType("Orb of Transmutation", 30, 250)
	static Alteration := CurrencyType("Orb of Alteration", 87, 250)
	static Annulment := CurrencyType("Orb of Annulment", 144, 250)
	static Chance := CurrencyType("Orb of Chance", 202, 250)
	static Augmentation := CurrencyType("Orb of Augmentation", 202, 307)
	static Exalted := CurrencyType("Exalted Orb", 277, 250)
	static Regal := CurrencyType("Regal Orb", 411, 250)
	static Alchemy := CurrencyType("Orb of Alchemy", 468, 250)
	static Chaos := CurrencyType("Chaos Orb", 525, 250)
	static Scouring := CurrencyType("Orb of Scouring", 411, 376)
}

class CurrencyItem {
    gui := ""
    __New(currencyType, position) {
        this.currencyType := currencyType
        this.position := position
        this._count := 0
        this.gui := ""
    }

    static SyncThreshold := 50
    _callsSinceSync := 0

    Count {
        get => this._count
        set {
            if (this._count != value) {
                this._count := value
                this.UpdateUI()
            }
        }
    }

    Use(targetPos) {
        if (this.Count > 0) {
            Util.MClick(this.position, "Right")
            Util.MClick(targetPos, "Left")
            this.Count--
            this._callsSinceSync++
            Sleep(Config.PingDelay + Config.FPSDelay)
            update := Core.GetItem(targetPos)
            if (this._callsSinceSync >= CurrencyItem.SyncThreshold) {
                this.Refresh()
                this.UpdateUI()
            } else {
                this.UpdateUI()
            }
            if (Config.DebugLevel > 0) {
                Util.Log("Step " A_Index " (" this.currencyType.name "): " Util.ReplaceNewLines(update.ToString()))
            }
            HistoryDashboard.AddItem(update)
            return update
        } else { ; вызывающий должен проверять сам. отсуствие валюты должно обрабатываться
            Util.Log("ERROR: Tried to use " this.currencyType.name " but Count is 0")
            MsgBox("Ошибка!`nПытался использовать " this.currencyType.name " но они отсутствуют!", "Ошибка", "Icon! 4096")
            ExitApp()
        }
    }

    UpdateUI() {
        if (this.gui == "") {
            this.gui := UI.CreateFrame(this.position, this._count)
        }

        color := (this._count < 10) ? "Red" : "White"
        this.gui["Count"].SetFont("c" . color)
        this.gui["Count"].Value := this._count
    }

    Refresh() {
        rawText := Core.GetItemDetailedText(this.position)
        this._callsSinceSync := 0
        if (rawText == "" || !InStr(rawText, "Rarity: Currency")) {
            this.Count := 0
            return false
        }

        if (!RegExMatch(rawText, "m)^([^:^-][^:\r\n]+)$(*ACCEPT)", &name)) {
            this.Count := 0
            return false
        }
        if (name[1] != this.currencyType.name) {
            this.Count := 0
            return false
        }
        if RegExMatch(rawText, "m)^Stack Size: ([\d,.]+)", &match) {
            this.Count := Number(StrReplace(match[1], ","))
            return true
        }
        return false
    }

    Show() => (!(this.gui == "") ? this.gui.Show("NoActivate") : this.UpdateUI())
    Hide() => (!(this.gui == "") ? this.gui.Hide() : "")
}