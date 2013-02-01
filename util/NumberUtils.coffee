# vmi.util.NumberUtils.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.util.Types

class NumberUtils

#___________________________________________________________________________________________________ roundTo
    @roundTo: (number, digits, fixed) ->
        number = Math.round(number*Math.pow(10,digits)) / Math.pow(10,digits)

        if fixed
            return number.toFixed(digits)
        else
            return number
