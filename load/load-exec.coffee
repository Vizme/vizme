# load-exec.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

#import vmi.load.vizmeDefinition

#___________________________________________________________________________________________________ window.onload
window.onload = () ->
    ### The beachhead loading script that asynchronously loads the javascript libraries needed to
        render the page.
    ###

    doc      = document
    head     = doc.getElementsByTagName('head')[0]
    progress = [10, 10]
    delta    = PAGE.SCRIPTS.delta
    items    = PAGE.SCRIPTS.items
    css      = PAGE.SCRIPTS.css
    index    = 0
    count    = 0
    allCount = 0
    for row in items
        allCount += row.length

    #-----------------------------------------------------------------------------------------------
    # COMPLETE
    #   Executed when all script loading completed. Triggers the loading of the independent, i.e.
    #   truly asynchronous scripts, if any exist.
    complete = () ->
        VIZME.SCRIPTS = true
        VIZME.dispatchEvent('SCRIPT:complete', null, true)

        async = PAGE.SCRIPTS.async
        if async.length
            loadRow(async)
        return

    #-----------------------------------------------------------------------------------------------
    # CALLBACK
    #   Executed when a script file has been loaded.
    callback = () ->
        VIZME.dispatchEvent('SCRIPT:loaded:' + this.i[0], this, true)
        if not this.t
            return

        progress[0] += delta
        progress[1] = Math.max(progress[0], progress[1])

        allCount--
        if this.i[1]
            count--

        if count > 0
            return

        if index < items.length
            load()
        else if allCount == 0
            complete()

        return

    #-----------------------------------------------------------------------------------------------
    # LOAD
    #   Loads script files asynchronously and on complete executes a callback. The loadRow function
    #   handles the actual load process, while load is used as a wrapper for standard includes.
    #   The independent (truly asynchronous) scripts are loaded using loadRow directly, which
    #   doesn't affect the counting toward completion of the script load process.
    loadRow = (row, sync) ->
        for item in row
            script         = doc.createElement('script')
            script.charset = 'utf-8'
            script.type    = 'text/javascript'
            script.id      = item[0]
            script.src     = item[2]
            if sync and not item[1]
                count--
            script.onload = callback.bind({s:script, i:item, t:sync})
            head.appendChild(script)
        return

    load = () ->
        row   = items[index]
        index++
        count = row.length
        loadRow(row, true)
        return

    #-----------------------------------------------------------------------------------------------
    # DISPLAY
    #   Animated display of the loading icon.
    lt = setInterval(() ->
        t = document.getElementsByClassName('v-API-pageProgress')
        if (!t.length)
            clearInterval(lt)
            lt = null
            return

        progress[1]++
        t[0].style.width = Math.min(100, progress[1]) + '%'
        return
    , 125)

    #-----------------------------------------------------------------------------------------------
    # CSS
    #   Begin loading of all of the linked CSS style sheets.
    if css and css.length > 0
        for cssUrl in css
            link      = doc.createElement('link')
            link.rel  = 'stylesheet'
            link.type = 'text/css'
            link.href = cssUrl
            head.appendChild(link)

    # Begin the load process
    if items.length == 0
        complete()
    else
        load()

    return
