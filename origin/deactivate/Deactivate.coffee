# vmi.origin.deactivate.Deactivate.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.SubmissionDisplayModule
# import vmi.util.url.URLUtils

# Submits a contact request module.
class Deactivate extends SubmissionDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'deactivate'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(Deactivate.ID, '#deactivate-container', 'Login', 'deactivate', '#deactivate-box',
              '#deactivate-submit', '#deactivate-success-box', '#deactivate-complete')

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _createAPIRequestArgs
    _createAPIRequestArgs: (args) =>
        args      = {}
        args.code = PAGE.deactivateCode
        return args

#___________________________________________________________________________________________________ _showComplete
    _showComplete: () =>
        window.location = URLUtils.getURL(null, true)
