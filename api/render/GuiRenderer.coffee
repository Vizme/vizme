# vmi.api.render.GuiRenderer.coffee
# Vizme, Inc. (C)2011
# Scott Ernst

# require vmi.api.render.Renderer

# Absrtact base module for DOM rendered elements (e.g. entities or ui).
class GuiRenderer extends Renderer

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# Creates an APIManager module instance.
    constructor: (renderID) ->
        super('ui', renderID)

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#===================================================================================================
#                                                                               P R O T E C T E D

#===================================================================================================
#                                                                                 H A N D L E R S
