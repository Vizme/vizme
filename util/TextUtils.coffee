# vmi.util.TextUtils.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.util.Types
# require vmi.util.string.StringUtils

class TextUtils

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ getCaretIndex
# Returns a list of CSS classes for the element of the given ID.
    @getCaretIndex: (target) ->
        i   = 0
        dom = target[0]
        
        #IE support
        if document.selection
            target.focus()
            sel = document.selection.createRange()
            sel.moveStart('character', -dom.value.length)
            i = sel.text.length

        # Other support
        else if dom.selectionStart || dom.selectionStart == '0'
            i = dom.selectionStart

        return i

#___________________________________________________________________________________________________ setCaretIndex
    @setCaretIndex: (target, i) ->
        dom = target[0]
        
        # IE support
        if dom.setSelectionRange
            target.focus()
            dom.setSelectionRange(i, i)

        # Other support
        else if dom.createTextRange
            r = dom.createTextRange()
            r.collapse(true)
            r.moveEnd('character', i)
            r.moveStart('character', i)
            r.select()
            
        return i
