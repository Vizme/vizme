# vmi.origin.support.request.userRequest.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.util.module.SubmissionDisplayModule

# Submits a contact request module.
class UserRequest extends SubmissionDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'userRequest'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(UserRequest.ID, '#request-container', 'Support', 'feedback', '#request-box',
              '#req-submit', '#request-success-box', '#req-complete', {KIND:PAGE.REQUEST_TYPE})

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _showComplete
    _showComplete: () =>
        window.close()
        window.location = URLUtils.getURL(null, true)