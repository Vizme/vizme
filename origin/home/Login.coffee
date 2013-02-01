# vmi.origin.home.Login.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst and Eric David Wills

# import vmi.util.module.ContainerDisplayModule
# require vmi.api.io.APIRequest
# require vmi.util.Types
# require vmi.util.dom.DOMUtils
# require vmi.util.hash.HashUtils
# require vmi.util.url.URLUtils

# General Vizme Login (register) module.
class Login extends ContainerDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'login'

    # Enumeration for login display mode
    @LOGIN_MODE = 'log'

    # Enumeration for registration display mode
    @REGISTER_MODE = 'reg'

    # Enumeration for account activation display mode
    @ACTIVATE_MODE = 'act'

    # Enumeration for email display mode (either new password or new activation code)
    @EMAIL_MODE = 'eml'

    # Enumeration for logout display mode
    @LOGOUT_MODE = 'out'

    @_ERROR_CLASS = 'v-CONBOX-EmptyInputError'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(Login.ID, "#login-container")

        @_initialHashID  = null
        @_mode           = null
        @_emailCallback  = null
        @_callback       = null
        @_loginData      = null
        @_validationData = null

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: loading
# Profile data.
    loading: () =>
        return $('#login-loading').length > 0 and $('#login-loading').is(':visible')

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the Login module for use.
    initialize: () =>
        if not super()
            return false

        # Adds secure API calls to the VIZME object
        VIZME.apiSecure = @loginValidatedRequest

        # Initially hide all login boxes
        @children().hide()

        #c = $(@_target)
        #DOMProcessor.process(c)

        $('#login-createaccount').data('mode', Login.REGISTER_MODE)

        # Add events
        $('.loginInputText').keyup(@_handleKeyUp)
        $('#login-createaccount').click(@_handleSwitchMode)
        $('#login-forgotpass').click(@_handleForgotPasswordClick)

        $('#login-submit').click(@_handleLoginClick)
        $('#register-submit').click(@_handleRegisterClick)
        $('#activation-resend').click(@_handleResendCodeClick)
        $('#email-submit').click(@_handleEmailClick)
        $('#validation-submit').click(@_handlePasswordValidateClick)
        $('#validation-cancel').click(@_handleCancelValidation)
        $('#logout-yes-button').click(@_handleLogoutClick)
        $('#logout-no-button').click(@_handleCancelLogoutClick)

        b = $('#activation-ok')
        b.data('mode', Login.LOGIN_MODE)
        b.click(@_handleSwitchMode)

#___________________________________________________________________________________________________ resize
# Resizes the module.
    resize: () =>
        c = $(@_target)
        c.width(Math.min(400, Math.max(0, $(window).width() - 20)))

#___________________________________________________________________________________________________ dumpSnapshot
# Creates a cache snapshot of the module for storage in the history module to support browser
# back and forward actions.
    dumpSnapshot: () =>
        snap      = super()
        snap.mode = @_mode
        snap.cb   = @_callback
        return snap

#___________________________________________________________________________________________________ loadSnapshot
# Loads a previously created cache snapshot for the module, updating the state to comply with the
# values specified in the snapshot data.
# @param {Object} snapshotData     - Data object representing the cache snapshot to load.
    loadSnapshot: (snapshotData) =>
        super(snapshotData)

        if not snapshotData.vis
            return

        if Types.isNull(snapshotData.mode)
            @_showNoShow()
        else
            @_switchMode(snapshotData.mode, snapshotData.cb)

#___________________________________________________________________________________________________ cleanseSnapshot
# Cleanses a snapshot data object, which is invoked after a significant state change, e.g. logout.
    cleanseSnapshot: (snapshotData, modeID) =>
        sd = super(snapshotData, changeID)
        if sd.vis
            sd.mode = null
            sd.cb   = null
        return sd

#___________________________________________________________________________________________________ show
# Displays the login display.
# register - Enumerated display mode for the module display. Default (null) opens as login
# validation - If true, the login is assumed to be a validation operation, i.e. validate before
#              proceeding with some action.
# callback - Callback executed when the operation is complete. Function signature is
#            callback(this, result).
    show: (mode, callback, validationData) =>
        if @loading()
            return

        @_validationData = validationData
        alreadyVisible   = @visible()
        currentMode      = @_mode
        @_callback       = callback
        @_mode           = if not Types.isNull(mode) then mode else Login.LOGIN_MODE
        if VIZME.mod.history and not alreadyVisible
            @_initialHashID = VIZME.mod.history.currentHashID()

        if not URLUtils.isSecure()
            window.location = URLUtils.getURL(null, true) + '#_.dmode=' + @_mode
            return

        super()
        @_switchMode(@_mode)

        if @_validationData
            return

        # Create snapshot if not a validation request
        if not alreadyVisible or currentMode != @_mode
            @_createSnapshot(true)

#___________________________________________________________________________________________________ loginValidatedRequest
    loginValidatedRequest: (category, identifier, args, callback, localData) =>
        @show(Login.LOGIN_MODE, callback, {cat:category, id:identifier, args:args, local:localData})

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _clearInputFields
    _clearInputFields: () =>
        $('.loginInputText').val('')

#___________________________________________________________________________________________________ _hideMeImpl
# Method executed when hiding the module.
    _hideMeImpl: () =>
        @_clearInputFields()
        if @visible()
            @_refresh()

#___________________________________________________________________________________________________ _showError
# Displays the specified error and focuses on the target.
# @param errorData   - Error object as returned by request.data.
# @param target      - Target object that is the focus of the error.
# @param showMessage - Display as a message result instead of an error.
    _showError: (errorData, showMessage =false, target =null) =>
        @_refresh()

        $('.loginInputText').removeClass(Login._ERROR_CLASS)

        if target
            target.select()
            target.focus()

        super(errorData, showMessage)

#___________________________________________________________________________________________________ _clearError
# Clears the display of any errors.
    _clearError: () =>
        $(@_target + ' .v-CONBOX-header').show()
        $('.loginInputText').removeClass(Login._ERROR_CLASS)

        super()

#___________________________________________________________________________________________________ _checkValidField
# Determines if the specified target field contains valid text. If not, the error is displayed.
# @param target - Object to check for valid text.
#
# @return boolean - Whether or not the field was valid.
    _checkValidField: (target) =>
        if Types.isEmpty(target.val())
            target.addClass(Login._ERROR_CLASS)
            return false

        return true

#___________________________________________________________________________________________________ _refresh
# Refreshes the display, hiding loading and resetting the display for the current mode.
    _refresh: () =>
        @_switchMode()

#___________________________________________________________________________________________________ _switchMode
# Switches between displaying the register and login modes.
# mode - Display mode to switch to. If no mode is specified it will refresh the current mode display.
    _switchMode: (mode) =>
        if not Types.isNone(mode)
            @_mode = mode

        if Types.isNone(@_mode)
            @_mode = Login.LOGIN_MODE

        target = null
        msgBox = null

        switch @_mode
            when Login.REGISTER_MODE
                box    = $('#register-box')
                msgBox = $('#p-register-message')
                target = $('#register-user')
            when Login.ACTIVATE_MODE
                box    = $('#activation-box')
            when Login.EMAIL_MODE
                box    = $('#email-box')
                target = $('#email-input')
            when Login.LOGOUT_MODE
                box    = $('#logout-box')
                target = $('#logout-yes-button')
            else
                if VIZME.mod.profile.loggedIn()
                    box    = $('#validation-box')
                    msgBox = $('#p-validation-message')
                    target = $('#validation-input')
                else
                    box    = $('#login-box')
                    msgBox = $('#p-login-message')
                    target = $('#login-email')

        @_clearError()
        @_hideLoading()

        for b in @children()
            b = $(b)
            if b.attr('id') == box.attr('id')
                b.show()
            else
                b.hide()

        if msgBox and msgBox.length > 0
            msgBox.show()

        if not Types.isNull(target)
            target.select()
            target.focus()

        VIZME.resize()

#___________________________________________________________________________________________________ _executeComplete
# Called after a login or register action is complete this redirects the result to the correct
# display location as well as executing the callback if it exists.
    _executeComplete: (result) =>
        # Clear all text fields to prevent snopping data from history
        $('.loginInputText').val('')

        @_loginData      = null
        @_validationData = null

        if Types.isFunction(@_callback)
            @_callback(result)
            @_callback = null
            return

        switch @_mode
            when Login.LOGIN_MODE
                VIZME.exec.dispatchEvent({data:'LOGIN:loggedIn'})
            when Login.LOGOUT_MODE
                if result
                    VIZME.exec.dispatchEvent({data:'LOGIN:loggedOut'})
                else
                    VIZME.mod.profile.show()

        @_clearInputFields()
        @_hideLoading()

#___________________________________________________________________________________________________ _sendPassword
# Sends a new password to the specified email address.
# @param address - Email address for the account that requires the new password.
    _sendPassword: (address) =>
        @_showLoading()

        VIZME.trace('Sending new password to: ' + address)

        VIZME.api('Login', 'newPassword', {email:address}, @_handlePasswordSent)

#___________________________________________________________________________________________________ _resendActivation
    _resendActivation: (address) =>
        @_showLoading()

        VIZME.trace('Resending activation email to: ' + address)

        VIZME.api('Login', 'resendActivation', {email:address}, @_handleActivationResent)

#___________________________________________________________________________________________________ _sendValidationRequest
    _sendValidationRequest: (password) =>
        @_showLoading()

        v             = @_validationData
        noV           = Types.isNull(v)
        args          = if noV then {} else v.args
        cat           = if noV then 'Login' else v.cat
        id            = if noV then 'validate' else v.id
        local         = if noV then null else v.local
        hash          = APIRequest.getProtectedPasswordHash(password)
        req           = new APIRequest(cat, id, {'valid':hash})
        req.localData = local
        req.request(args, @_handleValidationResult)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleSwitchMode
# Switches the mode based on user request.
    _handleSwitchMode: (event) =>
        oldMode = @_mode
        newMode = $(event.currentTarget).data('mode')
        @_switchMode(newMode)

        # Cache a snapshot on a mode switch if the mode actually changes
        if oldMode != newMode
            @_createSnapshot(true)

#___________________________________________________________________________________________________ _handleKeyUp
# Exexcuted whenever a key up event occurs in a login input text field.
    _handleKeyUp: (event) =>
        $(event.currentTarget).removeClass(Login._ERROR_CLASS)
        kc = event.keyCode

        if kc != 13
            return

        switch @_mode
            when Login.REGISTER_MODE then @_handleRegisterClick()
            when Login.ACTIVATE_MODE then return
            when Login.EMAIL_MODE
                if Types.isFunction(@_emailCallback)
                    @_emailCallback()
            else
                if $('#validation-box').is(':visible')
                    @_handlePasswordValidateClick()
                else
                    @_handleLoginClick()

#___________________________________________________________________________________________________ _handleLoginClick
# Executed when user submits a login request.
    _handleLoginClick: (event) =>
        # Check for valid email address
        email = $('#login-email')
        if not @_checkValidField(email, 3)
            return

        # Check for valid password
        password = $('#login-password')
        if not @_checkValidField(password, 6)
            return

        remember = $('#login-remember').is(':checked')

        @_showLoading()

        hash = APIRequest.getProtectedPasswordHash(password.val())
        VIZME.api('Login', 'create', {email:email.val(), remember:remember, password:hash},
                  @_handleLoginResult)

#___________________________________________________________________________________________________ _handleLoginResult
    _handleLoginResult: (request) =>
        if not request.success
            if request.data.error == 'REG' or request.data.error == 'INA'
                @_switchMode(Login.ACTIVATE_MODE)
                return

            @_showError(request.data)
            return

        APIManager.profile   = request.data.profile
        APIRequest.loginID   = request.data.loginID
        APIRequest.loginCode = request.data.loginCode

        if not Types.isEmpty(@_validationData)
            @_sendValidationRequest($('#login-password').val())
        else
            @_executeComplete(request)

#___________________________________________________________________________________________________ _handleRegisterClick
# Executed on a registration submission click.
    _handleRegisterClick: (event) =>
        # Check for valid user name
        name = $('#register-user')
        if not @_checkValidField(name)
            return

        # Check for valid email address
        email = $('#register-email')
        if not @_checkValidField(email)
            return

        # Check for valid password
        password  = $('#register-password')
        if not @_checkValidField(password)
            return

        # Check for valid code if necessary
        code = $('#register-code')
        if code.length > 0
            if not @_checkValidField(code)
                return
        else
            code = null

        @_showLoading()

        args            = {}
        args.name       = name.val()
        args.email      = email.val()
        args.password   = HashUtils.sha256(password.val())
        args.passLength = password.val().length
        if not Types.isNull(code)
            args.code   = code.val()
        VIZME.api('Login', 'register', args, @_handleRegisterResult)

#___________________________________________________________________________________________________ _handleRegisterResult
    _handleRegisterResult: (request) =>
        if not request.success
            @_showError(request.data)
            return

        email = $('#register-email')
        e = email.val()
        @_clearInputFields()
        email.val(e)
        @_switchMode(Login.ACTIVATE_MODE)

#___________________________________________________________________________________________________ _handleResendCodeClick
# Requests a new activation code be sent.
    _handleResendCodeClick: (event) =>
        for email in [$('#email-input'), $('#login-email')]
            if @_checkValidField(email)
                @_resendActivation(email.val())
                return

        @_emailCallback = @_handleResendCodeClick
        @_switchMode(Login.EMAIL_MODE)

#___________________________________________________________________________________________________ _handleActivationResent
    _handleActivationResent: (request) =>
        if not request.success
            @_showError(request.data)
            return

        @_showError(request.data, true)


#___________________________________________________________________________________________________ _handleForgotPasswordClick
# Requests a new password.
    _handleForgotPasswordClick: (event) =>
        email = $('#email-input')
        if @_checkValidField(email)
            @_sendPassword(email.val())
            return

        @_emailCallback = @_handleForgotPasswordClick
        @_switchMode(Login.EMAIL_MODE)

#___________________________________________________________________________________________________ _handlePasswordSent
    _handlePasswordSent: (request) =>
        if not request.success
            @_showError(request.data)
            return

        @_switchMode(Login.LOGIN_MODE)
        @_showError(request.data, true, $('#login-email'))

#___________________________________________________________________________________________________ _handleEmailClick
# Activates an email-based request (new password or new activation code).
    _handleEmailClick: (event) =>
        email = $('#email-input')
        if not @_checkValidField(email)
            return

        @_showLoading()

        if Types.isFunction(@_emailCallback)
            @_emailCallback(event)
            email.val('')

#___________________________________________________________________________________________________ _handleLogoutClick
# Processes a logout request.
    _handleLogoutClick: (event) =>
        @_validationData = null

        # Logout call to server deactivates the current login code to prevent false login
        # session activity.
        VIZME.api('Login', 'logout', {}, null)

        if VIZME.mod.profile
            VIZME.mod.profile.logout()

        @_executeComplete(true)

#___________________________________________________________________________________________________ _handleCancelLogoutClick
# Cancels a logout request.
    _handleCancelLogoutClick: (event) =>
        @_executeComplete(false)

#___________________________________________________________________________________________________ _handlePasswordValidateClick
# Initiates a password validated request.
    _handlePasswordValidateClick: (event) =>
        password = $('#validation-input')
        if not @_checkValidField(password)
            return

        @_sendValidationRequest(password.val())

#___________________________________________________________________________________________________ _handleCancelValidation
    _handleCancelValidation: (event) =>
        VIZME.mod.profile.show()

#___________________________________________________________________________________________________ _handleValidationResult
    _handleValidationResult: (request) =>
        if not request.success and request.data.error == 'NOTVALID'
            @_showError(request.data)
            return

        @_validationData = null
        @_executeComplete(request)

