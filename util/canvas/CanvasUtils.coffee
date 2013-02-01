# vmi.util.canvas.CanvasUtils.coffee
# Vizme, Inc. (C)2012
# Scott Ernst and Eric D. Wills

# require vmi.util.Types
# require vmi.util.color.ColorMixer

# global G_vmlCanvasManager

class CanvasUtils

    @_HALF_PI            = Math.PI/2
    @_QUARTER_PI         = Math.PI/4
    @_BUTTON_DOWN_ADJUST = 20

#___________________________________________________________________________________________________ setSize
    @setSize: (canvas, width, height) ->
        if Types.isSet(width)
            canvas.attr('width', width + '')
            canvas.width(width)

        if Types.isSet(height)
            canvas.attr('height', height + '')
            canvas.height(height)

#___________________________________________________________________________________________________ getContext2D
    @getContext2D: (canvas) ->
        ###Retrieves the context 2D instance for the canvas in a cross-browser compatible way.###

        try
            c = canvas[0]
        catch err
            c = canvas

        if Types.isNone(c.getContext)
            return G_vmlCanvasManager.initElement(c).getContext("2d")

        return c.getContext('2d')

#___________________________________________________________________________________________________ getCanvasColors
    @getCanvasColors: (canvas, sets, force) ->
        if Types.isSet(sets.CNVS_COLS) and not force and not sets.CNVS_COLS.refresh
            return sets.CNVS_COLS

        if Types.isSet(sets.fill)
            fill     = new ColorMixer(sets.fill)
            grad     = new ColorMixer(sets.grad).rawRgb()
            bor      = new ColorMixer(if sets.border then sets.border else sets.color).rawRgb()
            high     = if sets.high then new ColorMixer(sets.high) else null
        else
            high = null
            cols = VIZME.exec.styles.getDOMColors(canvas)

            switch sets.CNVS_DTYPE
                when 'btn'
                    fill = cols.back.bbn
                    bor  = cols.front.fbn
                else
                    fill = cols.back.bck
                    bor  = cols.back.bor

            fill     = new ColorMixer(fill)
            grad     = fill.getBendShifts('brgb', 1)[0]
            bor      = new ColorMixer(bor).rawRgb()
            if high
                high = new ColorMixer(high).rawRgb()

        if not high
            high = fill.getUpShifts('brgb', 1)[0]
        fill = fill.rawRgb()

        d = {f:fill, g:grad, b:bor, h:high}
        sets.CNVS_COLS = d

        return d

#___________________________________________________________________________________________________ renderGradientBox
    @renderGradientBox: (canvas, sets, refresh) ->
        cls        = CanvasUtils
        c          = cls.getCanvasColors(canvas, sets, refresh)
        fill       = c.f
        grad       = c.g
        bor        = c.b
        high       = c.h
        highTop    = 1.0
        highBottom = 0.0

        # Display mode with values for (over, down) or null for standard.
        mode = sets.displayMode
        if mode == 'over'
            [fill, grad]          = [grad, fill]
            [highTop, highBottom] = [highBottom, highTop]
        else if mode == 'down'
            [fill, grad]          = [grad, fill]
            [highTop, highBottom] = [highBottom, highTop]

            if ColorMixer.rgbToLuma(grad) > 0.5
                grad = [grad[0] - cls._BUTTON_DOWN_ADJUST,
                        grad[1] - cls._BUTTON_DOWN_ADJUST,
                        grad[2] - cls._BUTTON_DOWN_ADJUST]
            else
                grad = [grad[0] + cls._BUTTON_DOWN_ADJUST,
                        grad[1] + cls._BUTTON_DOWN_ADJUST,
                        grad[2] + cls._BUTTON_DOWN_ADJUST]
            if ColorMixer.rgbToLuma(bor) > 0.5
                bor = [bor[0] - cls._BUTTON_DOWN_ADJUST,
                       bor[1] - cls._BUTTON_DOWN_ADJUST,
                       bor[2] - cls._BUTTON_DOWN_ADJUST]
            else
                bor = [bor[0] + cls._BUTTON_DOWN_ADJUST,
                       bor[1] + cls._BUTTON_DOWN_ADJUST,
                       bor[2] + cls._BUTTON_DOWN_ADJUST]

        context = CanvasUtils.getContext2D(canvas)
        width   = canvas.width()
        height  = canvas.height()

        if width == 0 or height == 0
            return

        context.clearRect(0, 0, width, height)

        xMin     = 0.5
        yMin     = 0.5
        xMax     = width - 0.5
        yMax     = height - 0.5
        if sets.round and VIZME.CONFIG.BRWSR != 'opera'
            round    = sets.round
            maxRound = 2*parseInt(canvas.css('font-size').replace('px','')) / VIZME.exec.styles.globalScale()
            radius   = round*Math.round(Math.min(Math.min(0.5*width, 0.5*height), maxRound))
        else
            radius = 0

        context.beginPath()
        if radius > 0
            context.moveTo(xMax - radius, yMin)
            context.arcTo(xMax, yMin, xMax, yMin + radius, radius)
            context.lineTo(xMax, yMax - radius)
            context.arcTo(xMax, yMax, xMax - radius, yMax, radius)
            context.lineTo(xMin + radius, yMax)
            context.arcTo(xMin, yMax, xMin, yMax - radius, radius)
            context.lineTo(xMin, yMin + radius)
            context.arcTo(xMin, yMin, yMin + radius, xMin, radius)
        else
            context.moveTo(xMax, yMin)
            context.lineTo(xMax, yMax)
            context.lineTo(xMin, yMax)
            context.lineTo(xMin, yMin)
        context.closePath()

        gradient = context.createLinearGradient(0, yMin, 0, yMax)
        gradient.addColorStop(0.0, "rgba(#{fill[0]}, #{fill[1]}, #{fill[2]}, 1.0)")
        gradient.addColorStop(1.0, "rgba(#{grad[0]}, #{grad[1]}, #{grad[2]}, 1.0)")
        context.fillStyle = gradient
        context.fill()

        context.strokeStyle = "rgba(#{bor[0]}, #{bor[1]}, #{bor[2]}, 1.0)"
        context.stroke();

        xMin = 1.5
        yMin = 1.5
        xMax = width - 1.5
        yMax = height - 1.5

        context.beginPath()
        if radius > 0
            context.moveTo(xMax - radius, yMin)
            context.arcTo(xMax, yMin, xMax, yMin + radius, radius)
            context.lineTo(xMax, yMax - radius)
            context.arcTo(xMax, yMax, xMax - radius, yMax, radius)
            context.lineTo(xMin + radius, yMax)
            context.arcTo(xMin, yMax, xMin, yMax - radius, radius)
            context.lineTo(xMin, yMin + radius)
            context.arcTo(xMin, yMin, yMin + radius, xMin, radius)
        else
            context.moveTo(xMax, yMin)
            context.lineTo(xMax, yMax)
            context.lineTo(xMin, yMax)
            context.lineTo(xMin, yMin)
        context.closePath()

        gradient = context.createLinearGradient(0, yMin, 0, yMax)
        gradient.addColorStop(0.0, "rgba(#{high[0]}, #{high[1]}, #{high[2]}, #{highTop})")
        gradient.addColorStop(1.0, "rgba(#{high[0]}, #{high[1]}, #{high[2]}, #{highBottom})")
        context.strokeStyle = gradient
        context.stroke()

#___________________________________________________________________________________________________ renderEdgeGradient
    @renderEdgeGradient: (canvas, gradSize, color, gradient) ->
        cls = CanvasUtils

        if Types.isString(color)
            color = new ColorMixer(color).rawRgb()
        if Types.isString(gradient)
            gradient = new ColorMixer(gradient).rawRgb()

        context = CanvasUtils.getContext2D(canvas)
        width   = canvas.width()
        height  = canvas.height()

        if width == 0 or height == 0
            return

        imageData = context.getImageData(0, 0, width, height)
        for y in [0..height]
            offset = y*width;
            for x in [0..width]
                dx = Math.min(x, width - x)
                dy = Math.min(y, height - y)
                a  = 0.0
                if dx >= gradSize and dy >= gradSize
                    a = 1.0
                else
                    d = 0.0
                    if dx > gradSize or dy > gradSize
                        d = Math.min(Math.min(dx, dy) / gradSize, 1.0)
                    else
                        radMult = 0.4*(Math.SQRT2 - 1.0)
                        dxr     = gradSize - dx
                        dyr     = gradSize - dy
                        theta   = if dxr > 0.0 then Math.atan2(dyr, dxr) else cls._HALF_PI
                        rtheta  = Math.abs(cls._QUARTER_PI - theta) / cls._QUARTER_PI
                        mult    = Math.exp(-Math.max(0.1, rtheta)) - 0.368
                        rprime  = gradSize*(1.0 + radMult*mult)
                        d       = Math.max(rprime - Math.sqrt(dxr*dxr + dyr*dyr), 0.0) / rprime
                    a = 0.5 - 0.41*Math.cos(d*2.5) + 0.28*Math.sin(d*2.5)

                i  = 4*(offset + x)
                ar = 1.0 - a
                imageData.data[i]     = a*color[0] + ar*gradient[0]
                imageData.data[i + 1] = a*color[1] + ar*gradient[1]
                imageData.data[i + 2] = a*color[2] + ar*gradient[2]
                imageData.data[i + 3] = 255
        context.putImageData(imageData, 0, 0)
