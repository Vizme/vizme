# vmi.origin.home.Footer.coffee
# Vizme, Inc. (C)2010-2011
# Scott Ernst

# import vmi.util.module.DisplayModule
# require vmi.util.url.URLUtils

# Footer Module.
class Footer extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'footer'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(Footer.ID, '#v-footer')
        @modulesToHide(null)
        @_colWide    = 0
        @_colCount   = 0
        @_autoResize = true

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the BottomBar module.
    initialize: () =>
        footerCon = $('#v-footer')
        footerCon.show()

        if not super()
            return false

        for item in $('#v-footer-inner').children()
            @_colWide  = Math.max(@_colWide, $(item).width())
            @_colCount++

        $("#about-link").click(@_handleAboutClick)

        $("#feedback").click(@_handleOpenFeedback)
        $("#feedback-link").click(@_handleOpenFeedback)
        $("#contact-link").click(@_handleOpenContact)
        $("#eula-link").click(@_handleEulaClick)
        $("#privacy-link").click(@_handlePrivacyClick)

        return true

#___________________________________________________________________________________________________ dumpSnapshot
    dumpSnapshot: () =>
        return super()

#___________________________________________________________________________________________________ loadSnapshot
    loadSnapshot: (snapshotData) =>
        super(snapshotData)

#___________________________________________________________________________________________________ resize
    resize: () =>
        super()
        win       = $(window)
        w         = win.width()
        h         = 0
        colsWide  = @_colCount*@_colWide
        spacing   = Math.max(10, Math.min(Math.round((w - colsWide) / @_colCount), @_colWide))
        innerWide = colsWide + @_colCount*spacing + 2*@_colCount

        footerIn = $('#v-footer-inner')
        footerIn.width(Math.min(Math.max(20, w), innerWide))
        footerTop = footerIn.offset().top

        for item in footerIn.children()
            i = $(item)
            i.css('margin', "auto #{Math.floor(0.5*spacing)}px")
            i.width(@_colWide)
            h = Math.max(i.height(), h)

        fh = h
        for item in footerIn.children()
            i  = $(item)
            fh = Math.max(fh, h + Math.max(0, i.offset().top - footerTop))
            i.height(h)

        footerIn.height(fh + 10)

        footer = $('#v-footer')
        spacer = $('#v-footer-spacer')
        spacer.height(footer.height())

        if win.height() > spacer.position().top + footer.height()
            footer.css('position', 'fixed')
            footer.css('top', win.height() - footer.height())
        else
            footer.css('position', 'absolute')
            footer.css('top', spacer.position().top)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleEulaClick
    _handleEulaClick: (event) =>
        window.open(URLUtils.getURL('about/eula'), '_blank')

#___________________________________________________________________________________________________ _handlePrivacyClick
    _handlePrivacyClick: (event) =>
        window.open(URLUtils.getURL('about/privacy'), '_blank')

#___________________________________________________________________________________________________ _handleOpenContact
    _handleOpenContact: (event) =>
       VIZME.mod.frame.openFrame("#{URLUtils.getURL('supp/contact.php?x=1')}", {label:"Return"})

#___________________________________________________________________________________________________ _handleOpenFeedback
    _handleOpenFeedback: (event) =>
        VIZME.mod.frame.openFrame("#{URLUtils.getURL('supp/feedback.php?x=1')}", {label:"Return"})

#___________________________________________________________________________________________________ _handleAboutClick
    _handleAboutClick: (event) =>
        target = URLUtils.getURL('about.php')

        if PAGE.containerWidth < 910
            window.open(target, '_blank')
        else if VIZME.mod.frame
            VIZME.mod.frame.openFrame(target, {label:"Return"})
