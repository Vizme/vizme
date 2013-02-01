# vmi.origin.editors.site.SiteEditor.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.origin.editors.InteractiveEditor
# require vmi.api.enum.AttrEnum
# require vmi.util.ArrayUtils
# require vmi.util.Types
# require vmi.util.dom.DOMUtils
# require vmi.util.string.StringUtils

class SiteEditor extends InteractiveEditor

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'siteEditor'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(SiteEditor.ID, 'Website')

#===================================================================================================
#                                                                                   G E T / S E T

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Intializes the module.
    initialize: () =>
        $('#sitesets-cname').bind('v-textchange', @_handleCNAMEChange)

        $('.p-onButton').click(@_handleTogglePage)
        $('.p-offButton').click(@_handleTogglePage)
        $('.p-homeButton').click(@_handleSetHomePage)

        $('.p-page').each((index, element) ->
            me = $(this)
            if not Types.isSet(me.data('ldata'))
                me.data('ldata', {})
            me.data('ldata').refreshIndex = 0
        )

        $('.p-pagePath').bind('v-textmodified', @_handlePathChanged)

        return super()

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _updateRefreshedItem
    _updateRefreshedItem: (item, value) =>
        if item.hasClass('p-page')
            @_updatePageDisplay(item, value)
        else
            super(item, value)

#___________________________________________________________________________________________________ _updatePageDisplay
    _updatePageDisplay: (target, data) =>
        targetVData = target.data('vdata')

        homeBtn   = target.find('.p-homeButtonBox')
        pathInput = target.find('.p-pagePathBox')
        if data.inSite
            targetVData.inSite = true
            if Types.isSet(data.path)
                targetVData.path   = data.path
            else
                delete targetVData.path

            showButton = '.p-onButton'
            hideButton = '.p-offButton'
            remove     = 'v-S-bck-h'
            add        = 'v-S-bck-m1h'

            # If no home page is specified, make this one the home page, otherwise make it a
            # regular page
            if data.home
                VIZME.mod.ui_CON.setValue(target.find('.p-homeButton'), true)
                targetVData.home = true
                pathInput.hide()
            else
                VIZME.mod.ui_CON.setValue(target.find('.p-homeButton'), false)
                delete targetVData.home
                pathInput.show()
            homeBtn.show()

        else
            targetVData.inSite = false
            delete targetVData.home
            delete targetVData.path

            VIZME.mod.ui_CON.setValue(target.find('.p-homeButton'), false)

            hideButton = '.p-onButton'
            showButton = '.p-offButton'
            remove     = 'v-S-bck-m1h'
            add        = 'v-S-bck-h'

            homeBtn.hide()
            pathInput.hide()

        if data.path
            targetVData.path = data.path
            VIZME.mod.ui_CON.setValue(pathInput.find('.p-pagePath'), data.path)

        target.find(hideButton).hide()
        b = target.find(showButton)
        b.show().resize()
        target.removeClass(remove).addClass(add)

        bbox = target.find('.p-toggleBox')
        ibox = target.find('.p-infoBox')
        bbox.css({'height':'auto'})
        h = Math.max(bbox.height(), ibox.height())
        bbox.height(h)
        bbox.find('.p-toggleIcons').css('margin-top', Math.max(0, Math.round(0.5*(h - b.height()))))

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleSetHomePage
    _handleSetHomePage: (event) =>
        target = $(event.currentTarget)
        target.find('.p-pagePathBox').hide()

        btns   = $('.p-homeButton')
        oldBtn = btns.filter(':checked').not(target)

        uiCON  = VIZME.mod.ui_CON
        uiCON.setValues(btns, false)
        uiCON.setValue(target, true)

        # If checking the current button don't update. This works because clicking on the currently
        # checked button will uncheck it, leaving no buttons checked.
        if oldBtn.length == 0
            return

        # Update the old home page values to be a regular page
        oldPage        = oldBtn.parents('.p-page')
        oldPageVD      = oldPage.data('vdata')
        delete oldPageVD.home
        if oldPage.is(':visible')
            oldPage.find('.p-pagePathBox').show()
            oldPageVD.path = uiCON.getValue(oldPage.find('.p-pagePath'))

        # Update the new home page values to be a 'home' page
        newPage        = target.parents('.p-page')
        newPageVD      = newPage.data('vdata')
        newPageVD.home = true
        delete newPageVD.path
        newPage.find('.p-pagePathBox').hide()

        @_setDataStateChanged([oldPage, newPage])

#___________________________________________________________________________________________________ _handleTogglePage
    _handleTogglePage: (event) =>
        src = $(event.currentTarget)
        target  = src.parents('.p-page')
        data    = {}
        changed = [target]

        data.inSite = src.hasClass('p-offButton')
        data.home   = $('.p-homeButton:checked').filter(':visible').length == 0
        if data.inSite and not data.home
            data.path = VIZME.mod.ui_CON.getValue(target.find('.p-pagePath'))

        @_updatePageDisplay(target, data)

        # Update home page selection if the current home page was removed
        if not data.inSite and $('.p-homeButton:checked').length == 0
            homes = $('.p-homeButton:visible')
            if homes.length > 0
                newHome = $(homes[0])
                VIZME.mod.ui_CON.setValue(newHome, true)
                newHomePage = newHome.parents('.p-page')
                newHomePage.find('.p-pagePathBox').hide()
                vd          = newHomePage.data('vdata')
                vd.home     = true
                delete vd.path
                changed.push(newHomePage)

        @_setDataStateChanged(changed)

#___________________________________________________________________________________________________ _handleCNAMEChange
    _handleCNAMEChange: (event, value) =>
        if Types.isEmpty(value)
            value = PAGE.SITE_DOMAIN

        $('.p-cname').html(value)

#___________________________________________________________________________________________________ _handlePathChanged
    _handlePathChanged: (event) =>
        target = $(event.currentTarget)
        page   = target.parents('.p-page')
        page.data('vdata').path = VIZME.mod.ui_CON.getValue(target)

        @_setDataStateChanged(page)