# vmi.origin.previews.webpage.webpage-lib.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.shared.vml.webpage.Webpage
# require vmi.util.exec.PageManager
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.util.url.URLUtils

#___________________________________________________________________________________________________ init
libraryInit = () ->
    sp = if PAGE.GUTTER then 25 else 0
    pm = new PageManager('#v-container', 400, PAGE.MAX_WEBPAGE_WIDTH, sp)
    pm.loadModule(Help,   false)
    pm.loadModule(Webpage, false)
    pm.initializeComplete()

    $('.v-vmldebug-error').resize((event) ->
        target = $(event.currentTarget)
        canvas = target.find('.v-vmldebug-canvasBack')
        CanvasUtils.setSize(canvas, target.width(), target.height())
        CanvasUtils.renderEdgeGradient(canvas, 24, '#FF9E9E', '#FF7575')
    ).resize()

    VIZME.mod.webpage.show()
    VIZME.resize()
