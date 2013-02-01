# vmi.util.debug.lineDebugger.coffee
# Vizme, Inc. (C)2011
# Scott Ernst

window.___vmiDebugLines = []

#___________________________________________________________________________________________________ window.___vmiDebug
window.___vmiDebug = (pckg, clss, func, line) ->
    window.___vmiDebugLines.push([pckg, clss, func, line])

#___________________________________________________________________________________________________ window.vmiStackTrace
window.vmiStackTrace = (verbose =false) ->
    out  = ''
    prev = null
    for item in window.___vmiDebugLines

        # Skip entries in the same method unless verbose
        if prev and not verbose and prev[0] == item[0] and prev[1] == item[1] and prev[2] == item[2]
            continue

        if item[1] and item[2]
            out += "#{item[1]}.#{item[2]}"
        else if item[1]
            out += item[1]
        else if item[2]
            out += item[2]

        out += " on line #{item[3]}"
        if item[0]
            out += "in (#{item[0]})"

        out += "\n"
