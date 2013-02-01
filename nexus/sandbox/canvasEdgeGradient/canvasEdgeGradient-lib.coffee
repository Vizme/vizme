# canvasEdgeGradient-lib.coffee
# Vizme, Inc. (C)2012
# Eric David Wills and Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.Response
# require vmi.util.canvas.CanvasUtils

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm  = new PageManager('#container', 400, 5000, 0)
    pm.loadModule(Response, false)
    pm.initializeComplete()

    imageURL = 'https://d2us6wg1i94or4.cloudfront.net/grad/b/#S#/#C#/#G#'

    # Render all compareBoxes
    $('.compareBox').each((index, element) ->
        e        = $(element)
        size     = parseInt(e.attr('data-size'), 10)
        color    = e.attr('data-color')
        gradient = e.attr('data-gradient')

        canvas = e.find('.canvasSwatch')
        canvas.width(size)
        canvas.attr('width', size)
        canvas.height(size)
        canvas.attr('height', size)

        test = e.find('.canvasTest')
        test.width(2.5*size)
        test.attr('width', 2.5*size)
        test.height(1.5*size)
        test.attr('height', 1.5*size)

        image = e.find('.imageCompare')
        url = imageURL.replace('#S#', Math.round(size)).
                       replace('#C#', color.substr(1)).
                       replace('#G#', gradient.substr(1))
        image.css('background-image', "url('#{url}')")
        image.width(size)
        image.height(size)

        gradSize = Math.round(0.5*size)
        CanvasUtils.renderEdgeGradient(canvas, gradSize, color, gradient)
        CanvasUtils.renderEdgeGradient(test, gradSize, color, gradient)
        e.find('.info').html("Size: #{size}px<br />Gradient: #{gradSize}px<br />Image URL: #{url}")
    )