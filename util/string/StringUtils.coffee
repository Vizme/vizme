# vmi.util.string.StringUtils.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# require vmi.util.Types

# ignore String

class StringUtils

#===================================================================================================
#                                                                                       C L A S S

    # ORIGINAL B64 Character set is not web/filesytem safe.
    # @B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    # So we remap the unsafe characters using the same remapping as Cloudfront:
    # '+' => '-'
    # '=' => '_'
    # '/' => '~'
    @B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-~_"

#___________________________________________________________________________________________________ startsWith
    @startsWith: (sourceStr, searchStr) ->
        ### Checks to see if the string starts with the specified search string and returns the
        result.

        @@@param sourceStr:string
            Source string on which to check.

        @@@param searchStr:string,array
            String to test for a start match. This can also be an array of strings if you want to
            multiple strings.

        @@@returns boolean
            Whether or not the string starts with the specified search string.
        ###

        if not Types.isString(sourceStr) or Types.isNone(searchStr)
            return false

        if Types.isArray(searchStr)
            for s in searchStr
                if sourceStr.indexOf(s) == 0
                    return true
            return false

        return sourceStr.indexOf(searchStr) == 0

#___________________________________________________________________________________________________ endsWith
# Checks to see if the string ends with the specified search string and returns the result.
# @param sourceStr - Source string on which to check.
# @param searchStr - String to test for an end match.
# @returns boolean - Whether or not the string ends with the specified search string.
    @endsWith: (sourceStr, searchStr) ->
        if not Types.isString(sourceStr) or Types.isNone(searchStr)
            return false

        return sourceStr.indexOf(searchStr) + searchStr.length == sourceStr.length

#___________________________________________________________________________________________________ rSplit
# Splits the source string by the sep the maxSplit times from the right instead of from the left as
# the default String.split() function does.
    @rSplit: (sourceStr, sep, maxsplit) ->
        split = sourceStr.split(sep)

        if maxsplit
            return [split.slice(0, -maxsplit).join(sep)].concat(split.slice(-maxsplit))

        return split

#___________________________________________________________________________________________________ capitalizeFirstLetter
# Capitalizes the first letter in the supplied string.
    @capitalizeFirstLetter: (string) ->
        return string.charAt(0).toUpperCase() + string.slice(1)


#___________________________________________________________________________________________________ getAsXMLDOM
# Returns the input string as an XML DOM object in a cross-browser fashion.
    @getAsXMLDOM: (xmlString) ->
        if window.ActiveXObject
            xml       = new ActiveXObject('Microsoft.XMLDOM')
            xml.async ='false'
            xml.loadXML(xmlString)
            return xml
        else if $.browser.safari
            xmlSafari = new DOMParser()
            return xmlSafari.parseFromString(xmlString, 'text/xml')
        else
            return xmlString

#___________________________________________________________________________________________________ getRandom
# Returns a randomized string consisting of a-z, A-Z, 0-9 of the specified length. If no length is
# specified the default 8 character length is used.
    @getRandom: (length) ->
        length = if length then length else 8
        s      = ""
        offset = 1

        while s.length < length
            switch Math.floor(3*Math.random()) + offset
                when 0 then i = [48, 57]
                when 1 then i = [65, 90]
                else        i = [97, 121]

            s     += String.fromCharCode(i[0] + Math.floor((i[1] - i[0] + 1)*Math.random()))
            offset = 0

        return s

#___________________________________________________________________________________________________ strip
    @strip: (s) ->
        return s.replace(/^\s+|\s+$/g, '')

#___________________________________________________________________________________________________ rStrip
    @rStrip: (s) ->
        return s.replace(/\s+$/, '')

#___________________________________________________________________________________________________ lStrip
    @lStrip: (s) ->
        return s.replace(/^\s+/, '')

#___________________________________________________________________________________________________ lStrip
    @repeat: (s, length) ->
        out = s
        while 2*out.length < length
            out += out

        while out.length + s.length < length
            out += s

        return out

#___________________________________________________________________________________________________ lPad
    @lPad: (src, pad, length) ->
        while src.length < length
            src = pad + src
        return src

#___________________________________________________________________________________________________ rPad
    @rPad: (src, pad, length) ->
        while src.length < length
            src = src + pad
        return src

#___________________________________________________________________________________________________ isNumeric
    @isNumeric: (s) ->
        s = StringUtils.strip(s)
        if s.length == 0
            return false

        if (/[^0-9-\.]+/g).exec(s.substr(0,1))
            return false

        return Types.isEmpty((/[^0-9- \t\n\.eE]+/g).exec(s))

#___________________________________________________________________________________________________ encode64
    @encode64: (s) ->
        cls  = StringUtils
        keys = cls.B64_CHARS
        out  = ''
        i    = 0

        s = cls.encodeUTF8(s)

        while i < s.length
            chr1 = s.charCodeAt(i++)
            chr2 = s.charCodeAt(i++)
            chr3 = s.charCodeAt(i++)

            enc1 = chr1 >> 2
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4)
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6)
            enc4 = chr3 & 63

            if isNaN(chr2)
                enc3 = 64
                enc4 = 64
            else if isNaN(chr3)
                enc4 = 64

            out += keys.charAt(enc1) + keys.charAt(enc2) + keys.charAt(enc3) + keys.charAt(enc4)

        return out

#___________________________________________________________________________________________________ decode64
    @decode64: (s) ->
        cls  = StringUtils
        keys = cls.B64_CHARS
        sfcc = String.fromCharCode
        out  = ''
        i    = 0

        s = s.replace(/[^A-Za-z0-9\+\/\=]/g, "")

        while i < s.length
            enc1 = keys.indexOf(s.charAt(i++))
            enc2 = keys.indexOf(s.charAt(i++))
            enc3 = keys.indexOf(s.charAt(i++))
            enc4 = keys.indexOf(s.charAt(i++))

            chr1 = (enc1 << 2) | (enc2 >> 4)
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2)
            chr3 = ((enc3 & 3) << 6) | enc4

            out = out + sfcc(chr1)

            if enc3 != 64
                out = out + sfcc(chr2)
            if enc4 != 64
                out = out + sfcc(chr3)

        return cls.decodeUTF8(out)

#___________________________________________________________________________________________________ encodeUTF8
    @encodeUTF8: (s) ->
        s    = s.replace(/\r\n/g, '\n')
        sfcc = String.fromCharCode
        out  = ''
        n    = 0

        while n < s.length
            c = s.charCodeAt(n)

            if c < 128
                out += sfcc(c)
            else if c > 127 and c < 2048
                out += sfcc((c >> 6) | 192)
                out += sfcc((c & 63) | 128)
            else
                out += sfcc((c >> 12) | 224)
                out += sfcc(((c >> 6) & 63) | 128)
                out += sfcc((c & 63) | 128)
            n++

        return out

#___________________________________________________________________________________________________ decodeUTF8
    @decodeUTF8: (s) ->
        sfcc = String.fromCharCode
        out  = ''
        i    = 0

        while i < s.length
            c = s.charCodeAt(i)

            if c < 128
                out += sfcc(c)
                i++
            else if c > 191 and c < 224
                c2   = s.charCodeAt(i + 1)
                out += sfcc(((c & 31) << 6) | (c2 & 63))
                i   += 2
            else
                c2   = s.charCodeAt(i+1)
                c3   = s.charCodeAt(i+2)
                out += sfcc(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63))
                i   += 3

        return out
