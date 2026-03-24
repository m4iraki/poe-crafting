#Requires AutoHotkey v2.0
#Include ../lib/_Includes.ahk

RequiredFilters := [
    { name: "of Shaping", text: "Life when you Block" },
    { name: "of Shaping", text: "increased Reservation Efficiency", tier: 1 },
]
ExcludeFilters := [
    { name: "The Shaper's" },
    { name: "of Shaping" }
]
conf := {
    RequiredFilters : RequiredFilters,
    ExcludeFilters : ExcludeFilters,
    MinMatches : 1,
}

ChaosCrafting.Run(conf)