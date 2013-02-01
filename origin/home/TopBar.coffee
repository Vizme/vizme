# vmi.origin.home.TopBar.coffee
# Vizme, Inc. (C)2010-2012
# Scott Ernst

# import vmi.util.module.DisplayModule
# require vmi.util.Types
# require vmi.util.string.StringUtils
# require vmi.util.flash.FlashUtils
# require vmi.util.url.URLUtils

# The TopBar module represents the statically placed command bar for the main site and includes
# navigation, status, and other control user-interface elements.
class TopBar extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'topBar'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(TopBar.ID, '.v-NVB')
        @modulesToHide(null)

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the TopBar module.
    initialize: () =>
        if not super()
            return false

        @_handleResize()

        $(".v-NVB-logo").click(@_handleLogoClick)
        $("#register-link").click(@_handleRegisterClick)
        $("#login-link").click(@_handleLoginClick)
        $("#account-actions-name").click(@_handleAccountClick)
        $("#logout-link").click(@_handleLogoutClick)

        return true

#___________________________________________________________________________________________________ showAccountLogin
# Displays the login/register state for the user account box.
    showAccountLogin: () =>
        $("#account-actions-loading").hide()
        $("#account-actions-welcome").hide()
        $("#account-actions-login").show()

#___________________________________________________________________________________________________ showAccountWelcome
# Displays welcome/logout state for the user account box.
# @param {String} username     - Name to display as the logged in user.
    showAccountWelcome: (username) =>
        username ?= APIManager.profile.name
        $("#account-actions-loading").hide()
        $("#account-actions-login").hide()
        $("#account-actions-welcome").show()
        $("#account-actions-name").text(StringUtils.capitalizeFirstLetter(username))

#___________________________________________________________________________________________________ resize
    resize: () =>
#        topCon = $('.v-NVB')
#        h = 32
#        for item in $('div', topCon)
#            h = Math.max(h, $(item).height() + $(item).offset().top)
#        topCon.height(h)

#___________________________________________________________________________________________________ dumpSnapshot
# Creates a cache snapshot for storage in the history module.
    dumpSnapshot: () =>
        return super()

#___________________________________________________________________________________________________ loadSnapshot
# Loads a previously created cache snapshot for the module, updating the state to comply with the
# values specified in the snapshot data.
# @param {Object} snapshotData     - Data object representing the cache snapshot to load.
    loadSnapshot: (snapshotData) =>
        super(snapshotData)

#___________________________________________________________________________________________________ onLogin
    onLogin: (profile) =>
        @showAccountWelcome(profile['dname'])

#___________________________________________________________________________________________________ onLogout
    onLogout: () =>
        @showAccountLogin()

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleResize
    _handleResize: () =>
        $("#sdata-display").hide()

#___________________________________________________________________________________________________ _handleLogoClick
    _handleLogoClick: (event) =>
        if VIZME.mod.intro
            VIZME.mod.intro.show()
        else
            window.open($('.v-NVB-logo').attr('data-href'), '_blank')

#___________________________________________________________________________________________________ _handleRegisterClick
    _handleRegisterClick: (event) =>
        VIZME.mod.login.show(Login.REGISTER_MODE, null)

#___________________________________________________________________________________________________ _handleLoginClick
    _handleLoginClick: (event) =>
        VIZME.mod.login.show(Login.LOGIN_MODE, null)

#___________________________________________________________________________________________________ _handleAccountClick
    _handleAccountClick: (event) =>
        VIZME.mod.profile.openHome()

#___________________________________________________________________________________________________ _handleLogoutClick
    _handleLogoutClick: (event) =>
        VIZME.mod.login.show(Login.LOGOUT_MODE, null)
