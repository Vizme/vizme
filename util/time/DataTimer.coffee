# vmi.util.time.DataTimer.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

#import vmi.util.Types

# A DataTimer in an AS3 style
class DataTimer

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# @param {Object} interval
# @param {Object} data
# @param {Object} repeat
# @param {Object} completeCallback
# @param {Object} intervalCallback
    constructor: (interval, repeat, data, completeCallback, intervalCallback) ->
        @_interval         = interval
        @_data             = data
        @_repeatCount      = if Types.isNone(repeat) then 1 else repeat
        @_count            = 0
        @_intervalCallback = completeCallback
        @_completeCallback = intervalCallback
        @_timerID          = null

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: running
    running: () =>
        return not Types.isNone(@_timerID)

#___________________________________________________________________________________________________ GS: data
    data: (value) =>
        if Types.isSet(value)
            @_data = value

        return @_data

#___________________________________________________________________________________________________ GS: interval
    interval: (value) =>
        if Types.isSet(value)
            @_interval = value
            @reset()

        return @_interval

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ start
    start: () =>
        if @_timerID
          return false

        @_timerID = setInterval(@_handleComplete, @_interval)
        return true

#___________________________________________________________________________________________________ stop
    stop: () =>
        if not @_timerID
          return false

        clearInterval(@_timerID)
        @_timerID = null
        return true

#___________________________________________________________________________________________________ restart
    restart: () =>
        @reset()
        @start()
        return true

#___________________________________________________________________________________________________ reset
    reset: () =>
        @stop()
        @_count = 0
        return true

#___________________________________________________________________________________________________ destroy
    destroy: () =>
        @stop()

        @_intervalCallback = null
        @_completeCallback = null
        @_data             = null
        @_interval         = 0

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleComplete
    _handleComplete: () =>
        @_count++

        if @_repeatCount > 0 and @_count >= @_repeatCount
            @stop()

        hasInterval = Types.isFunction(@_intervalCallback)
        f           = if hasInterval then @_intervalCallback else @_completeCallback

        if @_repeatCount == 0
            f(this)
        else if @_count < @_repeatCount and hasInterval
            f(this)
        else if @_repeatCount > 0 and @_count >= @_repeatCount
            if Types.isFunction(@_completeCallback)
                @_completeCallback(this)
            else if hasInterval
                f(this)
