# vmi.origin.restoreEmail.RestoreEmail.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.SubmissionDisplayModule
# require vmi.util.url.URLUtils

# Submits a contact request module.
class RestoreEmail extends SubmissionDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'restoreEmail'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(RestoreEmail.ID, '#restoreEmail-container', 'Login', 'restoreEmail', '#restoreEmail-box',
              '#restore-submit', '#restore-success-box', '#restore-complete')

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _createAPIRequestArgs
    _createAPIRequestArgs: (args) =>
        return {code:PAGE.restoreCode}

#___________________________________________________________________________________________________ _showComplete
    _showComplete: () =>
        window.location = URLUtils.getURL(null, true) + '#_.dmode=log'