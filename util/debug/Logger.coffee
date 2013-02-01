# vmi.util.debug.Logger.coffee
# Vizme, Inc. (C)2011-2013
# Scott Ernst

# import vmi.util.module.Module
# require vmi.util.Types

# Logger module for inspecting output.
class Logger extends Module

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'log'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(Logger.ID)
        @_buffer  = []
        @_errors  = []

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ active
    active: () =>
        page = window.PAGE
        return Types.isSet(window.console) and (
            VIZME.CONFIG.DEBUG or (page and page.FORCE_LOG)
        )

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
    initialize: () =>
        # Make the trace function globally accessible through VIZME.trace
        VIZME.trace = @trace
        while VIZME.TRC.length > 0
            @trace(VIZME.TRC.shift())

        return super()

#___________________________________________________________________________________________________ trace
# Displays the login/register state for the user account box.
    trace: (args...) =>
        if not @active()
            @_buffer.push(args)
            return

        me = Logger
        while @_buffer.length > 0
            me._traceArgs(@_buffer.shift())

        me._traceArgs(args)
        return

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ log
    @_log: (item) =>
        c      = window.console
        useDir = Types.isSet(c.dir)

        if not Types.isSet(item)
            c.log('Empty trace item')

        if Types.isError(item)
            c.log('ERROR[' + err.name + ']: ' + err.message  + '\n' + err.stack)
            if useDir
                c.dir(err)
        else if Types.isString(item) or not useDir
            c.log(item)
        else
            c.dir(item)

        return

#___________________________________________________________________________________________________ _traceArgs
    @_traceArgs: (args) ->
        c     = window.console
        me    = Logger
        isSet = Types.isSet

        try
            if args.length == 0
                return
            else if args.length == 1 and Types.isArray(args[0])
                args = args[0]
            else if args.length == 1
                me._log(args[0])
                return

            # Use grouping for logs when on supported browsers (IE does not support this).
            useGroup = isSet(c.group) and isSet(c.groupEnd)
            ioff     = 0
            if useGroup
                c.group(args[0])
                ioff++

            for i in [ioff..args.length]
                me._log(args[i])

            if ioff > 0 && isSet(c.trace)
                c.trace()

            if ioff > 0 and useGroup
                c.groupEnd()

        catch err
            if isSet(c) and isSet(c.log)
                try
                    c.log(err.message + '\n' + err.stack)
                catch e
                    c.log(err)

        return
