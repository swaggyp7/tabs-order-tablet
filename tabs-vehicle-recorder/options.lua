function draw()
    UiPush(); UiTranslate(UiCenter(),UiMiddle()-80); UiAlign("center top"); UiFont("regular.ttf",24)
    UiText("TABS Order Tablet"); UiTranslate(0,50)
    UiText("LMB select / add   |   Q move / fire   |   Backspace undo")
    UiTranslate(0,40); UiText("Fire mode: Z next weapon   |   X next ammunition")
    UiTranslate(0,40); UiText("F7 execute   |   F5 stop   |   R start a new plan")
    UiTranslate(0,60); if UiTextButton("Close") then Menu() end; UiPop()
end
