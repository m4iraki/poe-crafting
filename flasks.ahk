#Requires AutoHotkey v2.0
#Include lib.ahk

MyFilters := [
    { text: "when you are Hit by an Enemy", tier: 2 },
    { text: "increased Charge Recovery", tier: 2 },
    { text: "gain a Flask Charge when you deal a Critical Strike", tier: 2 },
    { text: "reduced Charges per use", tier: 2 },
    { name: "of the Rainbow" },
    { name: "of the Cheetah" },
    { name: "of Tenaciousness" },
    { name: "of the Owl" },
    { name: "of the Heron" },
    { name: "of Bog Moss" },
    { name: "of the Sunfish" },
    { text: "increased Evasion Rating during Effect", tier: 2 },
    { text: "increased Armour during Effect", tier: 2 },
    { text: "increased Critical Strike Chance during Effec", tier: 2 }
]

conf := {
    Version:     1.0,
    MaxAttempts: 500,
    CraftMode:   AlterationCrafting.STRATEGY_ANY, ; "ANY", "BOTH", "CLEAN"
    Filters:     MyFilters,
    DebugLevel:  0 ; 0 - только итог, 1 - всё подряд
}

AlterationCrafting.Run(conf)