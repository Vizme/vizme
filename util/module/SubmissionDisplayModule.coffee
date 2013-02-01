# vmi.util.module.SubmissionDisplayModule.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.ContainerDisplayModule
# require vmi.util.Types
# require vmi.util.dom.DOMUtils
# require vmi.util.url.URLUtils

# Restore a profile's email address module.
class SubmissionDisplayModule extends ContainerDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    @_ERROR_CLASS = 'v-CONBOX-EmptyInputError'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: (id, target, apiSubmitCategory, apiSubmitID, submissionBox, submitButton, successBox, successButton, additionalParams) ->
        super(id, target)
        @_submissionBox    = submissionBox
        @_submitButton     = submitButton
        @_successBox       = successBox
        @_successButton    = successButton
        @_submitCategory   = apiSubmitCategory
        @_submitID         = apiSubmitID
        @_extraParams      = additionalParams

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the Login module for use.
    initialize: () =>
        if not super()
            return false

        self = this
        VIZME.addEventListener('API:ready', () ->
            if self._submissionBox
                s = $(self._submissionBox)
                VIZME.render(s)
                VIZME.mod.ui_CON.addKeyUpHandler(s, self._handleKeyUp)

            if self._successBox
                s = $(self._successBox)
                VIZME.render(s)
                VIZME.mod.ui_CON.addKeyUpHandler(s, self._handleKeyUp)

            if self._submitButton
                $(self._submitButton).click(self._handleSubmit)

            if self._successButton
                $(self._successButton).click(self._handleComplete)

            self.children().hide()
            $(self._submissionBox).show()
        )

        return true

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _allowSubmission
    _allowSubmission: () =>
        return VIZME.mod.ui_CON.getEmptyFields(@_submissionBox, true).length == 0

#___________________________________________________________________________________________________ _createAPIRequestArgs
    _createAPIRequestArgs: (args) =>
        if Types.isNone(args)
            args = VIZME.mod.ui_CON.getControlValues($(@_submissionBox))
        else
            args['form'] = VIZME.mod.ui_CON.getControlValues($(@_submissionBox))
        return args

#___________________________________________________________________________________________________ _submit
    _submit: (args) =>
        if @_extraParams
            for n,v of @_extraParams
                args[n] = v

        VIZME.api(@_submitCategory, @_submitID, args, @_handleResult)

#___________________________________________________________________________________________________ _showSuccess
    _showSuccess: (request) =>
        @_showError(request.data, true)
        $(@_submissionBox).hide()
        $(@_successBox).show()

#___________________________________________________________________________________________________ _showComplete
    _showComplete: () =>
        # Handles the case where the window was opened from another window
        if window.name.substr(0, 6) == 'vizme-'
            window.close()

        window.location = URLUtils.getURL(null, true)

#___________________________________________________________________________________________________ _checkValidField
# Determines if the specified target field contains valid text. If not, the error is displayed.
# @param target - Object to check for valid text.
#
# @return boolean - Whether or not the field was valid.
    _checkValidField: (target) =>
        if Types.isEmpty(target.val())
            target.addClass(SubmissionDisplayModule._ERROR_CLASS)
            @_hideLoading()
            return false

        return true


#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleKeyUp
# Exexcuted whenever a key up event occurs in a login input text field.
    _handleKeyUp: (event) =>
        VIZME.mod.ui_CON.clearErrors(@me())

        target = $(event.currentTarget)
        if target.is('textarea')
            return

        kc = event.keyCode

        if kc != 13
            return

        @_handleSubmit(event)

#___________________________________________________________________________________________________ _handleSubmit
    _handleSubmit: (event) =>
        if not @_allowSubmission()
            return

        @_showLoading()
        @_submit(@_createAPIRequestArgs())

#___________________________________________________________________________________________________ _handleResult
    _handleResult: (request) =>
        if not request.success
            @_showError(request.data)
            return

        @_showSuccess(request)

#___________________________________________________________________________________________________ _handleComplete
    _handleComplete: (event) =>
        if @_successBox
            $(@_successBox).hide()

        @_showComplete()
