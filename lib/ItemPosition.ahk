#Requires AutoHotkey v2.0

class ItemPosition {
    __New(x := 0, y := 0, w := 0, h := 0, scale := 1.0) {
        this.x := x * scale
        this.y := y * scale
        this.w := w * scale
        this.h := h * scale
        this.centerX := this.x + this.w / 2
        this.centerY := this.y + this.h / 2
    }


    ToString() {
        return "Pos: [" this.x "," this.y "] Size: " this.w "x" this.h
    }
}
