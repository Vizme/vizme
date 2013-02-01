# inlineLoad-exec.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

#import vmi.load.vizmeDefinition

#___________________________________________________________________________________________________ window.onload
window.onload = () ->
    ### The beachhead loading script that synchronously activates the javascript libraries needed to
        render the page.
    ###

    $('.v-JSIL').each((index, element) ->
        me   = $(element)
        item = {s:element, i:[me.attr('id'), 0, me.attr('src')], t:me.attr('async')}
        VIZME.dispatchEvent('SCRIPT:loaded:' + item.i[0], item)
    )

    VIZME.SCRIPTS = true
    VIZME.dispatchEvent('SCRIPT:complete', null, true)

