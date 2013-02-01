# vmi.util.SizeUtils.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.util.Types

# Class for converting between file sizes
class SizeUtils

#===================================================================================================
#                                                                                       C L A S S

    @BYTES     = {id:'B',  bytes:1}
    @KILOBYTES = {id:'KB', bytes:1024}
    @MEGABYTES = {id:'MB', bytes:1048576}
    @GIGABYTES = {id:'GB', bytes:1073741824}

#___________________________________________________________________________________________________ convert
    @convert: (size, fromSize, toSize, roundDigits) ->
        cls = SizeUtils
        if Types.isEmpty(toSize)
            toSize = cls.BYTES

        result = size*fromSize.bytes/toSize.bytes
        if Types.isSet(roundDigits)
            power = Math.pow(10, roundDigits)
            return Math.round(power*result) / power
        else
            return result

#___________________________________________________________________________________________________ prettyPrint
    @prettyPrint: (size, roundDigits) ->
        cls = SizeUtils

        if size == 0
            return '0B'

        if size >= cls.GIGABYTES.bytes
            toSize = cls.GIGABYTES
        else if size >= cls.MEGABYTES.bytes
            toSize = cls.MEGABYTES
        else if size >= cls.KILOBYTES.bytes
            toSize = cls.KILOBYTES
        else
            return size + cls.BYTES.id

        return cls.convert(size, cls.BYTES, toSize, roundDigits) + toSize.id

#___________________________________________________________________________________________________ bytesToKilobytes
    @bytesToKilobytes: (size, roundDigits) ->
        return SizeUtils.convert(size, SizeUtils.BYTES, SizeUtils.KILOBYTES, roundDigits)

#___________________________________________________________________________________________________ bytesToMegabytes
    @bytesToMegabytes: (size, roundDigits) ->
        return SizeUtils.convert(size, SizeUtils.BYTES, SizeUtils.MEGABYTES, roundDigits)

#___________________________________________________________________________________________________ bytesToGigabytes
    @bytesToGigabytes: (size, roundDigits) ->
        return SizeUtils.convert(size, SizeUtils.BYTES, SizeUtils.GIGABYTES, roundDigits)
