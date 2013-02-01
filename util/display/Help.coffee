# vmi.util.Help.coffee
# Vizme, Inc. (C)2010-2012
# Scott Ernst

# import vmi.util.module.Module
# require vmi.util.Types
# require vmi.util.dom.DOMUtils

# Module for managing help and support throughout the website.
class Help extends Module

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'help'

    @_PAD = 10
    @_CONTEXT_MIN_WIDE  = 220
    @_CONTEXT_MAX_WIDE  = 320
    @_CONTEXT_MIN_TALL  = 20
    @_CONTEXT_MAX_TALL  = 240

    @_CONTEXT_CLASS     = 'v-ctxHelpOverlay'
    @_CONTEXT_DOM       = '<div class="##CLASS## v-S-bckfront-m3 v-S-bck v-S-fclbor" data-v-ctxhlpid="##ID##">##FILL##</div>'
    @_CONTEXT_INNER_DOM = '<div class="v-ctxHelpInner"><div class="v-ctxHelpLabel v-S-fcl">##LBL##</div>' +
                          '<div class="v-ctxHelpMessage v-S-sft">##MSG##</div>' +
                          '<div class="v-ctxHelpSpacer"></div></div>'

    @_HELP_OVERLAY_DOM  = '<div class="v-helpOver v-S-bckfront-m3 v-SG-u128-bckm2 v-S-bckbor-m1" data-v-hlpid="#ID#">' +
                          '<div class="v-helpOverInner v-S-fcl">' +
                          '<div class="v-helpOverClose">&#9660; close</div>' +
                          '<div class="v-helpOverContent"></div>' +
                          '</div></div>'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(Help.ID)
        @_detailsClosing = false

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the Gui module.
    initialize: () =>
        return super()

#___________________________________________________________________________________________________ resize
    resize: () =>
        w = $(window).width()
        h = $(window).height()
        p = 2*Help._PAD

        #-------------------------------------------------------------------------------------------
        # CONTEXT OVERLAYS
        items = $('.' + Help._CONTEXT_CLASS)
        if items.length != 0
            lblClass = '.v-ctxHelpLabel'
            msgClass = '.v-ctxHelpMessage'

            items.find(lblClass + ',' + msgClass).css({'height':'auto', 'width':'auto'})

            items.each((index, element) ->
                me  = $(this)
                me.css({'height':'auto', 'width':'auto'})
                box = me.find('.v-ctxHelpInner')

                if box.length > 0
                    lbl = box.find(lblClass)
                    msg = box.find(msgClass)

                # Resize
                if box.length == 0
                    meW = Help.CONTEXT_MIN_WIDE
                else
                    meW = Math.min(Math.round((w - 50) / 2), Math.max(Help._CONTEXT_MIN_WIDE,
                    Math.min(lbl.width() + p, Help._CONTEXT_MAX_WIDE)))
                me.width(meW)

                if box.length > 0 and msg.length > 0
                    boxW = meW - p
                    if msg.width() > boxW
                        me.width(Math.min(Help.CONTEXT_MAX_WIDE + 40, msg.width() + p))
                    else
                        msg.width(boxW)
                meW = me.width()

                if box.length == 0
                    meH = Help._CONTEXT_MIN_TALL + 70
                else
                    meH = Math.min(Math.round((h - 50) / 2), Math.max(Help._CONTEXT_MIN_TALL,
                    Math.min(box.height() + 20, Help._CONTEXT_MAX_TALL)))
                me.height(meH)

                # Reposition
                pos = me.data('mouse')
                # Left versus right
                if (pos.x + meW) < (w - 35)
                    meX = pos.x + 15
                else
                    meX = pos.x - meW - 5
                me.css('left', meX + 'px')

                # Top versus bottom
                if (pos.y + meH) < (h - 25)
                    meY = pos.y + 5
                else
                    meY = pos.y - meH - 5
                me.css('top', meY + 'px')
            )

        #-------------------------------------------------------------------------------------------
        # DETAILS OVERLAY
        dom = $('.v-helpOver')
        if dom.length == 0
            return

        dom.stop(false, true)
        halfH = Math.max(240, Math.round(h/2))
        yPos  = if @_detailsClosing then h + 20 else Math.max(0, h - halfH)
        time  = Math.min(Math.abs(dom.offset().top - yPos), 1500)

        dom.css('left', 0)
        if w > 1000
            dom.width(970)
        else
            dom.css('width','100%')

        dom.height(halfH + 20)
        close   = dom.find('.v-helpOverClose')
        content = dom.find('.v-helpOverContent')
        content.width(Math.min(910, dom.width() - 60))
        content.height(halfH - 35 - close.height())
        dom.animate({top:yPos}, time, 'linear', @_handleDetailsAnimComplete)

#___________________________________________________________________________________________________ showContext
    showContext: (identifier, type) =>
        body = $('body')
        dom  = Help._CONTEXT_DOM.replace('##CLASS##', Help._CONTEXT_CLASS).
                                 replace('##ID##', identifier + '').
                                 replace('##FILL##', DOMUtils.getFillerElement(null, null, body))
        body.append(dom)
        dom = @_getContext(identifier)
        dom.data('mouse', $.extend({}, VIZME.mod.api.mouse()))
        @resize()

        VIZME.api('Help', 'context', {key:identifier, type:type}, @_handleContextResult, null,
                  type + '-' + identifier)

#___________________________________________________________________________________________________ showContextDetails
    showContextDetails: (identifier, type) =>
        cssOver = '.v-helpOver'
        $(cssOver).remove()

        dom = $(Help._HELP_OVERLAY_DOM.replace('#ID#', identifier + ''))
        dom.find('.v-helpOverClose').click(@_handleCloseDetails)
        dom.css('top',$(window).height() + 50)
        $('body').append(dom)
        dom.find('.v-helpOverContent').html(DOMUtils.getFillerElement(null, null, $(cssOver)))

        @_detailsClosing = false
        $(window).resize()
        #@resize()

        VIZME.api('Help', 'contextDetails', {key:identifier, type:type}, @_handleDetailsResult,
                  null, type + '-' + identifier)

#___________________________________________________________________________________________________ hideContext
    hideContext: (identifier) =>
        if Types.isNone(identifier)
            $('.' + Help._CONTEXT_CLASS).remove()

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _processResult
    _getContext: (dataID) =>
        return $('.' + Help._CONTEXT_CLASS + "[data-v-ctxhlpid='#{dataID}']")

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleContextResult
    _handleContextResult: (request) =>
        dom = @_getContext(request.data.data.id)
        if dom.length == 0
            return

        debug = request.data.data.debug
        if not debug
            debug = ''

        dom.html(Help._CONTEXT_INNER_DOM.replace('##LBL##', request.data.label).
                                         replace('##MSG##', request.data.message + debug))
        @resize()

#___________________________________________________________________________________________________ _handleDetailsResult
    _handleDetailsResult: (request) =>
        if not request.success
            return

        dom = $('.v-helpOver')
        if dom.length == 0
            return

        if request.data.id != dom.attr('data-v-hlpid')
            return

        dom.find('.v-helpOverContent').html(request.data.doms.dom)
        @resize()

#___________________________________________________________________________________________________ _handleCloseDetails
    _handleCloseDetails: (event) =>
        @_detailsClosing = true
        @resize()

#___________________________________________________________________________________________________ _handleDetailsAnimComplete
    _handleDetailsAnimComplete: () =>
        if @_detailsClosing
            $('.v-helpOver').remove()
