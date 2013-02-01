# vmi.origin.home.Introduction.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.DisplayModule

class Introduction extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module ID
    @ID = 'intro'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(Introduction.ID, "#introduction")
        @_isOpen = false

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the Introduction module.
    initialize: () =>
        if not super()
            return false

        VIZME.addEventListener('LOGIN:loggedOut', @_handleLogout)

        return true

#___________________________________________________________________________________________________ show
    show: () =>
        if (@_isOpen)
            return

        super()
        @_createSnapshot()

#___________________________________________________________________________________________________ dumpSnapshot
    dumpSnapshot: () =>
        return super()

#___________________________________________________________________________________________________ loadSnapshot
    loadSnapshot: (snapshotData) =>
        super(snapshotData)
        @resize()

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ hideMeImpl
    _hideMeImpl: () =>
        @_isOpen = false

#___________________________________________________________________________________________________ showMeImpl
    _showMeImpl: () =>
        @_isOpen = true
        @resize()

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleLogout
    _handleLogout: () =>
        @show()
