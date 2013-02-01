# vmi.util.color.ColorMixer.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.util.Types

class ColorMixer

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: (color, mode) ->
        cls = ColorMixer

        # Set raw color (stored in HSLA format)
        if Types.isString(color)
            # Possible empty values are '' in FF and transparent in Opera and IE.
            # Webkit uses rgba(0,0,0,0)
            if color.length == 0 or color.toLowerCase() == 'transparent'
                @_rawColor = [0, 0, 0, 0]
            else
                @_rawColor = cls.decodeToHsl(color)
        else if Types.isNumber(color)
            @_rawColor = cls.decodeToHsl(cls.intToHex(color))
        else
            switch mode
                when 'rgb' then @_rawColor = cls.rgbToHsl(color)
                when 'hsv' then @_rawColor = cls.rgbToHsl(cls.hsvToRgb(color))
                else            @_rawColor = color

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: hex
    hex: () =>
        return ColorMixer.hslToHex(@_rawColor)

#___________________________________________________________________________________________________ GS: bareHex
    bareHex: () =>
        return ColorMixer.hslToHex(@_rawColor, true)

#___________________________________________________________________________________________________ GS: hsl
    hsl: () =>
        return ColorMixer.encodeHsl(@_rawColor)

#___________________________________________________________________________________________________ GS: rawHsl
    rawHsl: () =>
        return @_rawColor

#___________________________________________________________________________________________________ GS: rgb
    rgb: () =>
        return ColorMixer.encodeRgb(ColorMixer.hslToRgb(@_rawColor))

#___________________________________________________________________________________________________ GS: rawRgb
    rawRgb: () =>
        return ColorMixer.hslToRgb(@_rawColor)

#___________________________________________________________________________________________________ GS: rawHsv
    rawHsv: () =>
        return ColorMixer.rgbToHsv(@rawRgb())

#___________________________________________________________________________________________________ GS: alpha
    alpha: () =>
        return @_rawColor[3]

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ getBendShifts
    getBendShifts: (encode, count, step) =>
        step  ?= 8
        count ?= 3
        return if @_rawColor[2] > 0.5*count*step then @getDownShifts(encode, count, step) else
        @getUpShifts(encode, count, step)

#___________________________________________________________________________________________________ getDownShifts
    getDownShifts: (encode, count, step) =>
        step  ?= 8
        count ?= 3
        delta = Math.min(Math.floor(@_rawColor[2] / count), step)
        res   = []
        i     = 0
        while i < count
            i++
            d    = @_rawColor.concat()
            d[2] = Math.max(0, d[2] - i*delta)
            switch encode
                when 'hsl' then res.push(ColorMixer.encodeHsl(d))
                when 'bhex' then res.push(ColorMixer.hslToHex(d, true))
                when 'hex' then res.push(ColorMixer.hslToHex(d))
                when 'brgb' then res.push(ColorMixer.hslToRgb(d))
                else
                    res.push(d)

        return res

#___________________________________________________________________________________________________ getUpShifts
    getUpShifts: (encode, count, step) =>
        step  ?= 8
        count ?= 3
        delta = Math.min(Math.floor((100 - @_rawColor[2]) / count), step)
        res   = []
        i     = 0
        while i < count
            i++
            u    = @_rawColor.concat()
            u[2] = Math.min(100, u[2] + i*delta)
            switch encode
                when 'hsl' then res.push(ColorMixer.encodeHsl(u))
                when 'bhex' then res.push(ColorMixer.hslToHex(u, true))
                when 'hex' then res.push(ColorMixer.hslToHex(u))
                when 'brgb' then res.push(ColorMixer.hslToRgb(u))
                else
                    res.push(u)

        return res

#___________________________________________________________________________________________________ decodeToHsl
    @decodeToHsl: (color) ->
        cls = ColorMixer
        if Types.isEmpty(color)
            return [0, 0, 0, 1]

        if color.indexOf('hsl') != -1
            return cls.decodeHsl(color)

        if color.indexOf('rgb') != -1
            return cls.rgbToHsl(cls.decodeRgb(color))

        return cls.hexToHsl(color)

#___________________________________________________________________________________________________ decodeToRgb
    @decodeToRgb: (color) ->
        cls = ColorMixer
        return cls.hslToRgb(cls.decodeToHsl(color))

#___________________________________________________________________________________________________ colorToHex
    @colorToHex: (color) ->
        cls = ColorMixer
        if color.substr(0, 1) == '#'
            return color

        if not Types.isString(color)
            return '#FFF'

        if color.indexOf('hsl') != -1
            return cls.hslToHex(cls.decodeHsl(color))

        if color.indexOf('rgb') != -1
            return cls.rgbToHex(cls.decodeRgb(color))

        return color.toUpperCase()

#___________________________________________________________________________________________________ intToHex
    @intToHex: (color) ->
        hex = Number(color).toString(16)
        return "000000".substr(0, 6 - hex.length) + hex

#___________________________________________________________________________________________________ hexToRgb
    @hexToRgb: (color) ->
        c = color.replace('#','').replace('0x','')

        if c.length < 2
            return [0, 0, 0, 1]

        if c.length == 3
            c1 = c.charAt(0)
            c2 = c.charAt(1)
            c3 = c.charAt(2)
            c = c1 + c1 + c2 + c2 + c3 + c3

        r = parseInt(c.substring(0,2),16)
        g = parseInt(c.substring(2,4),16)
        b = parseInt(c.substring(4,6),16)
        return [r, g, b, 1]

#___________________________________________________________________________________________________ hexToHsl
    @hexToHsl: (color) ->
        cls = ColorMixer
        return cls.rgbToHsl(cls.hexToRgb(color))

#___________________________________________________________________________________________________ hexToHsv
    @hexToHsv: (color) ->
        cls = ColorMixer
        return cls.rgbToHsv(cls.hexToRgb(color))

#___________________________________________________________________________________________________ rgbToHex
    @rgbToHex: (rgb, bare) ->
        rgb = rgb[2] | (rgb[1] << 8) | (rgb[0] << 16)
        rgb = rgb.toString(16).toUpperCase()
        while rgb.length < 6
            rgb = '0' + rgb
        return (if bare then '' else '#') + rgb

#___________________________________________________________________________________________________ hslToHex
    @hslToHex: (hsl, bare) ->
        cls = ColorMixer
        return cls.rgbToHex(cls.hslToRgb(hsl), bare).toUpperCase()

#___________________________________________________________________________________________________ encodeRgb
    @encodeRgb: (src) ->
        if src.length > 3
            an = 'a'
            av = ', ' + src[3]
        else
            an = ''
            av = ''

        return "rgb#{an}(#{src[0]}, #{src[1]}, #{src[2]}#{av})"

#___________________________________________________________________________________________________ decodeRgb
    @decodeRgb: (rgbColor) ->
        if rgbColor.indexOf('rgba') != -1
            digits = /(.*?)rgba\((\d+), (\d+), (\d+), (\d+)\)/
        else
            digits = /(.*?)rgb\((\d+), (\d+), (\d+)\)/
        digits = digits.exec(rgbColor)

        if Types.isEmpty(digits)
            return rgbColor

        rgba = [parseInt(digits[2]), parseInt(digits[3]), parseInt(digits[4]),
                if digits[5] then parseFloat(digits[5]) else 1]

#___________________________________________________________________________________________________ encodeHsl
    @encodeHsl: (src) ->
        if src.length > 3
            an = 'a'
            av = ', ' + src[3]
        else
            an = ''
            av = ''

        return "hsl#{an}(#{src[0]}, #{src[1]}%, #{src[2]}%#{av})"

#___________________________________________________________________________________________________ decodeHsl
    @decodeHsl: (hslColor) ->
        if hslColor.indexOf('hsla') != -1
            digits = /(.*?)hsla\((\d+), (\d+)%, (\d+)%, (\d+)\)/
        else
            digits = /(.*?)hsl\((\d+), (\d+)%, (\d+)%\)/
        digits = digits.exec(hslColor)

        if Types.isEmpty(digits)
            return hslColor

        return [parseFloat(digits[2]), parseFloat(digits[3]), parseFloat(digits[4]),
                if Types.isSet(digits[5]) then parseFloat(digits[5]) else 1]

#___________________________________________________________________________________________________ rgbToHsl
    @rgbToHsl: (rgb) ->
        r = rgb[0] / 255
        g = rgb[1] / 255
        b = rgb[2] / 255
        a = if Types.isSet(rgb[3]) then rgb[3] else 1

        maxC = Math.max(r, g, b)
        minC = Math.min(r, g, b)

        l = 0.5*(maxC + minC)

        if maxC == minC
            return [0, 0, 100*l, a]

        d = maxC - minC
        s = if l > 0.5 then d/(2 - maxC - minC) else d/(maxC + minC)
        if r == maxC
            h = (g - b) / d + (if g < b then 6 else 0)
        else if g == maxC
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        h /= 6

        return [360*h, 100*s, 100*l, a]

#___________________________________________________________________________________________________ hslToRgb
    @hslToRgb: (hsl) ->
        h = hsl[0] / 360
        s = hsl[1] / 100
        l = hsl[2] / 100
        a = if Types.isSet(hsl[3]) then hsl[3] else 1

        if s == 0
            rgb = Math.round(255*l)
            return [rgb, rgb, rgb, a]

        hue2rgb = (p, q, t) ->
            t += if t < 0 then 1 else 0
            t -= if t > 1 then 1 else 0
            if t < 1/6
                return p + (q - p)*6*t
            if t < 1/2
                return q
            if t < 2/3
                return p + (q - p)*(2/3 - t)*6
            return p

        q = if l < 0.5 then l*(1 + s) else l + s - l*s
        p = 2*l - q
        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)

        return [Math.round(255*r), Math.round(255*g), Math.round(255*b), a]

#___________________________________________________________________________________________________ rgbToHsv
    @rgbToHsv: (rgb) ->
        r = rgb[0] / 255
        g = rgb[1] / 255
        b = rgb[2] / 255
        a = if Types.isSet(rgb[3]) then rgb[3] else 1

        maxC = Math.max(r, g, b)
        minC = Math.min(r, g, b)

        v = maxC

        d = maxC - minC
        s = if maxC == 0 then 0 else d / maxC

        if maxC == minC
            return [0, 100*s, 100*v, a]

        if r == maxC
            h = (g - b) / d + (if g < b then 6 else 0)
        else if g == maxC
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        h /= 6

        return [360*h, 100*s, 100*v, a]

#___________________________________________________________________________________________________ hsvToRgb
    @hsvToRgb: (hsv) ->
        h = hsv[0] / 360
        s = hsv[1] / 100
        v = hsv[2] / 100
        a = if Types.isSet(hsv[3]) then hsv[3] else 1

        i = Math.floor(6*h)
        f = 6*h - i
        p = v*(1 - s)
        q = v*(1 - f*s)
        t = v*(1 - (1 - f)*s)

        switch i%6
            when 0
                r = v
                g = t
                b = p
            when 1
                r = q
                g = v
                b = p
            when 2
                r = p
                g = v
                b = t
            when 3
                r = p
                g = q
                b = v
            when 4
                r = t
                g = p
                b = v
            when 5
                r = v
                g = p
                b = q

        return [Math.round(255*r), Math.round(255*g), Math.round(255*b), a]

#___________________________________________________________________________________________________ rgbToLuma
    @rgbToLuma: (rgb) ->
        return (0.2126*rgb[0] + 0.7152*rgb[1] + 0.0722*rgb[2]) / 255.0

