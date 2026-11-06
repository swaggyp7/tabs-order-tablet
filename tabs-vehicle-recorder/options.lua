function draw()
    UiPush(); UiTranslate(UiCenter(),UiMiddle()-200); UiAlign("center top"); UiFont("regular.ttf",24)
    UiText("TABS ORDER TABLET"); UiTranslate(0,45); UiFont("regular.ttf",19)
    local function line(s) UiText(s); UiTranslate(0,32) end
    line("LMB  Select vehicle / Add order")
    line("Q  Route / Single shot / Moving fire target")
    line("Moving fire: select target, then click the route endpoint")
    line("Z / X  Weapon / Ammo     G  Cancel pending target")
    line("F7  Start selected     F8  Start all     F5  Stop selected")
    line("T  Start delay: 3 / 5 / 7 / 10 seconds")
    line("Backspace  Undo     Delete  Clear     R  Select vehicle")
    line("H  Toggle full controls in game")
    UiTranslate(0,20); if UiTextButton("Close") then Menu() end; UiPop()
end
