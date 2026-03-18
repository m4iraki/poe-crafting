#Requires AutoHotkey v2.0
#Include lib.ahk

MyFilters := [
    { name: "Oracle's" },
    { name: "Unyielding" },
    { name: "Vigorous" },
    { name: "of Shaping", tier: 1, text: "Reservation Efficiency" },
    { name: "of Shaping", tier: 1, text: "Life when you Block" },
    { text: "Physical Damage Reduction", tier: 2 }
]
conf := {
    Version:     1.0,
    Strategy:    AlterationCrafting.STRATEGY_ANY, ; "ANY", "BOTH", "CLEAN"
    Filters:     MyFilters,
}

AlterationCrafting.Run(conf)