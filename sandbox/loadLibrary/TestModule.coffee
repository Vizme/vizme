# TestModule.coffee
# Vizme, Inc. (C)2011
# Scott Ernst

#require vmi.util.io.AJAXRequest
#require vmi.util.dom.DOMUtils

class TestModule

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'test'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        @_method = AJAXRequest.TEXT

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ id
# Unique module identifier.
    id: () =>
        return TestModule.ID

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the BottomBar module.
    initialize: () =>
        c = $('#container')
        c.append(DOMUtils.getFillerElement(null, 'testitem', c))

        req = new AJAXRequest('test', 'share.php', AJAXRequest.JSON, false)