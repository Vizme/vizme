# vmi.origin.home.home-lib.coffee
# Vizme, Inc. (C)2010-2012
# Scott Ernst

# targets vmi.api.VizmeAPI

# require vmi.util.exec.PageManager
# require vmi.util.display.FriendlyFrame
# require vmi.util.display.Help
# require vmi.util.display.Response
# require vmi.util.dom.DOMUtils
# require vmi.origin.home.Login
# require vmi.origin.home.Profile
# require vmi.origin.home.Introduction
# require vmi.origin.home.TopBar

#___________________________________________________________________________________________________ init
libraryInit = () ->
    pm  = new PageManager('#container', 400, 5000, 0)
    pm.focalModuleIDs(['topBar', 'footer'])

    pm.loadModule(Help,          false)
    pm.loadModule(FriendlyFrame, true)
    pm.loadModule(TopBar,        true)
    pm.loadModule(Login,         true)
    pm.loadModule(Introduction,  true)
    pm.loadModule(Profile,       true)
    pm.loadModule(Response,      true)

    pm.checkVizMeWarning()
    settings = pm.history.getInitialModuleHash('_')
    if not Types.isObject(settings)
        settings = {}

    loggedIn = VIZME.mod.profile.loggedIn()
    if loggedIn
        VIZME.mod.topBar.showAccountWelcome()
    else
        VIZME.mod.topBar.showAccountLogin()

    if loggedIn
        VIZME.mod.profile.openHome()
    else if settings.dmode == 'log'
        VIZME.mod.login.show(Login.LOGIN_MODE)
    else if settings.dmode == 'reg'
        VIZME.mod.login.show(Login.REGISTER_MODE)
    else
        VIZME.mod.intro.show()

    pm.initializeComplete()
