# vmi.util.module.Module.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# require vmi.util.Types

# General Vizme Login (register) module.
class Module

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: (id) ->
        # Identifier for the module
        @_moduleID    = id
        @_initialized = false

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: id
# Module identifier.
    id: () =>
        return @_moduleID

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the module.
    initialize: () =>
        @_initialized = true
        return true

#___________________________________________________________________________________________________ dumpSnapshot
# Creates a cache snapshot of the module for storage in the history module to support browser
# back and forward actions.
    dumpSnapshot: () =>
        return {}

#___________________________________________________________________________________________________ loadSnapshot
# Loads a previously created cache snapshot for the module, updating the state to comply with the
# values specified in the snapshot data.
# @param {Object} snapshotData     - Data object representing the cache snapshot to load.
    loadSnapshot: (snapshotData) =>
