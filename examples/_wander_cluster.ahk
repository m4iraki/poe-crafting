#Requires AutoHotkey v2.0
#Include ../lib/_Includes.ahk

MandatoryFilters := [
    { text: "to Intelligence" },
    { text: "to All Attributes" }
]
NiceFilters := [
    { text: "increased Effect" },
    { text: "to Maximum Energy Shield" }
]
conf := {
    MandatoryFilters: MandatoryFilters,
    NiceFilters: NiceFilters,
    MandatoryStrategy: RegalCrafting.STRATEGY_1ANY,
    NiceStrategy: RegalCrafting.STRATEGY_2ANY,
}

RegalCrafting.Run(conf)