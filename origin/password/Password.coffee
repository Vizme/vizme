# vmi.origin.password.Password.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.SubmissionDisplayModule
# require vmi.api.io.APIRequest
# require vmi.util.url.URLUtils
# require vmi.util.hash.HashUtils

# Module for changing a user's password.
class Password extends SubmissionDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'password'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(
            Password.ID,
            '#password-container',
            'Login',
            'changePassword',
            '#password-box',
            '#password-submit',
            '#password-success-box',
            '#password-complete'
        )

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _createAPIRequestArgs
    _createAPIRequestArgs: (args) =>
        existing = $('#password-old')
        password = $('#password-enter')
        confirm  = $('#password-confirm')

        args = {
            code:PAGE.passCode,
            pass:HashUtils.sha256(encodeURIComponent(password.val())),
            passLength:password.val().length,
            confirm:HashUtils.sha256(encodeURIComponent(confirm.val())),
            confirmLength:confirm.val().length
        }

        if existing.length > 0
            args.existing = APIRequest.getProtectedPasswordHash(existing.val())

        return args

#___________________________________________________________________________________________________ _showComplete
    _showComplete: () =>
        # Handles the case where the window was opened from another window
        if window.name == 'vizme-newPassword' and APIManager.profile
            window.close()
            return

        window.location = URLUtils.getURL(null, true) + '#_.dmode=log'
