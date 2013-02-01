# vmi.util.exec.ExecutionManager.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.Module
# require vmi.util.debug.Logger
# require vmi.util.Types
# require vmi.util.time.DataTimer
# require vmi.util.url.URLUtils

# ExecutionManager module that manages other modules.
class ExecutionManager extends Module

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# Initializes the ExecutionManager module.
    constructor: (id) ->
        super(id)

        # Creates the global module access point if it doesn't already exist.
        VIZME.mod ?= {}

        VIZME.mod[id] = this

        # Applies this as the executive module.
        if not VIZME.exec
            VIZME.exec = this

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the module.
    initialize: () =>
        try
            if Types.isNone(VIZME.mod[Logger.ID])
                log = new Logger()
                VIZME.mod[Logger.ID] = log
                log.initialize()
        catch err

        return super()

#___________________________________________________________________________________________________ updateSize
    updateSize: () =>
        return


