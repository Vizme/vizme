# vmi.util.exec.HistoryManager.coffee
# Vizme, Inc. (C)2010-2012
# Scott Ernst

# import vmi.util.module.Module
# require vmi.util.Types
# require vmi.util.string.StringUtils
# require vmi.util.time.DataTimer

# Browser History Module. This module manages the cache snapshots for all other registered
# modules for use in browser navigation.
class HistoryManager extends Module

#===================================================================================================
#                                                                                       C L A S S

    @ID = 'history'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(HistoryManager.ID)

        # Stores the previous hash states for recall when the hash is changed.
        @_cache = {}

        # Set to true during a back operation to prevent back operations from caching new snapshots.
        @_backDisabled = false

        # The modules on which to cache and load snapshots when the hash changes.
        @_modules = {}

        # Next hash index. This is a monotonically increasing number as hash indices are not reused
        # during the lifetime of a site visit.
        @_hashIndex = 0

        # The most recent hash ID loaded by this module.
        @_hashID = ''

        # The most recent hash location snapshot loaded by this module.
        @_hashLocation = ''

        # Previous hash ID. Used for back operations.
        @_backHashID = null

        # The previously displayed hash.
        @_hashHistory = []

        # DataTimer used to submit repeat requests for the hash change when not correctly added to
        # the history.
        @_repeatTimer = null

        # Initial hash when the page was loaded.
        @_fullInitialHash = '';

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: initialHash
# Returns the full initial hash for the page when it was loaded.
    initialHash: () =>
        return @_fullInitialHash

#___________________________________________________________________________________________________ GS: currentHashID
# Returns the hash ID for for the current state.
    currentHashID: () =>
        return @_hashID

#___________________________________________________________________________________________________ GS: getInitialModuleHash
# Returns the initial hash param string for the specified module ID if it exists or an empty
# string otherwise.
    getInitialModuleHash: (moduleID) =>
        fh = @_fullInitialHash
        if Types.isEmpty(fh) or fh.indexOf('.') == -1
            return ''

        if fh.indexOf('+') == -1
            modules = [fh.substr(1)]
        else
            modules = @fh.split('+')

        for m in modules
            parts = m.split('.')
            if parts[0] == moduleID
                if parts[1].indexOf('&') == -1 and parts[1].indexOf('=') == -1
                    return parts[1]

                result = {}
                items = parts[1].split('&')
                for n in items
                    nameValue = n.split('=')
                    result[nameValue[0]] = nameValue[1]
                return result

        return ''

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
# Initializes the History module.
    initialize: () =>
        # Stores the initial hash for later reference.
        @_fullInitialHash = location.hash

        # Remove any initial hash, necessary for page reloading.
        if location.hash and StringUtils.startsWith(location.hash, 'vmh')
            location.hash = ''

        # Add event listener for changes in the hash tag.
        $(window).hashchange(@_handleHashChange)

        return true

#___________________________________________________________________________________________________ addModule
# Adds a module to the list of modules stored in the history cache.
    addModule: (module) =>
        @_modules[module.id()] = module

#___________________________________________________________________________________________________ removeModule
# Removes a module to the list of modules stored in the history cache.
    removeModule: (module) =>
        delete @_modules[module.id()]

#___________________________________________________________________________________________________ createSnapshot
# Creates the cache snapshot by iterating through the registered modules and collecting snapshots
# from each. The result is stored in the _cache parameter using the hash tag (without the leading
# pound sign).
    createSnapshot: () =>
        if @_backDisabled
            return

        if @_repeatTimer
            @_repeatTimer.stop()
        @_repeatTimer = null

        snapshot     = {}
        hashLocation = ''
        id           = null
        for mid, m of @_modules
            if m.hasOwnProperty('dumpSnapshot')
                snapshot[mid] = m.dumpSnapshot()

            if m.hasOwnProperty('hashLocation')
                loc = m.hashLocation();
                if loc
                    hashLocation += '+' + loc

        snapshot._page = {
            yoff:         window.pageYOffset,
            backHashID:   @_hashID,
            hashLocation: hashLocation
            backHashIndex: @_hashIndex
        }

        @_hashIndex++
        hashID          = 'vmh' + @_hashIndex
        @_cache[hashID] = snapshot

        # Update the hash
        @_hashHistory.push(@_hashID)
        @_backHashID   = @_hashID
        @_hashID       = hashID
        @_hashLocation = hashLocation

        currentHistoryLength = history.length
        @_setLocationHash(@_hashID, @_hashLocation)

        if currentHistoryLength == history.length and not @_compareHashes()
            VIZME.trace('Failed to register cache in browser history.')
            @_repeatTimer = new DataTimer(250, 0, [hashID, hashLocation], null, @_handleHashRetry)
            @_repeatTimer.start()
        else
            VIZME.trace('Cache snapshot: ' + @_getFullHash(), snapshot)

#___________________________________________________________________________________________________ reload
# Reloads the current hash state. Useful for cases where it may have been corrupted.
    reload: () =>
        @back(@_hashID)

#___________________________________________________________________________________________________ back
# Executes a simulated back operation if a previous snapshot exists. Since there is no direct
# access to the back button browser state this action is limited by the inability to make the
# initial state part of the browser's forward history, making it impossible to press the forward
# browser button to return to the initial state.
# param hashID - Specify a particular hash ID to return to. If null the back operation will go to
#                the previous hashID.
    back: (hashID =null) =>
        if Types.isEmpty(hashID)
            hashID = @_backHashID

        if not hashID
            return

        @_backDisabled = true
        @_loadSnapshot(hashID)
        @_setLocationHash()
        @_backDisabled = false

#___________________________________________________________________________________________________ onLogin
    onLogin: (profile) =>
        @_cleanseLoginProfileStates(DisplayModule.LOGIN_CHANGE)

#___________________________________________________________________________________________________ onLogout
    onLogout: (profile) =>
        @_cleanseLoginProfileStates(DisplayModule.LOGOUT_CHANGE)

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _cleanseLoginProfileStates
    _cleanseLoginProfileStates: () =>
        for cacheID, cacheObj of @_cache
            for mid, snapshot of @_cache
                if VIZME.mod[mid] and Types.isFunction(VIZME.mod[mid].cleanseSnapshot)
                    @_cache[mid] = VIZME.mod[mid].cleanseSnapshot(snapshot)

#___________________________________________________________________________________________________ _getFullHash
    _getFullHash: (hashID, hashLocation) =>
        hid = if hashID then hashID else @_hashID
        loc = if hashLocation then hashLocation else @_hashLocation
        return '#' + (if loc != null and loc.length > 0 then '!' else '') + hid + loc

#___________________________________________________________________________________________________ _compareHashes
    _compareHashes: (hashID, hashLocation) =>
        return location.hash == @_getFullHash(hashID, hashLocation)

#___________________________________________________________________________________________________ _setLocationHash
    _setLocationHash: (hashID, hashLocation) =>
        location.hash = @_getFullHash(hashID, hashLocation)

#___________________________________________________________________________________________________ _loadSnapshot
# Loads an existing history snapshot of the site for display as specified by the has argument.
# @param {String} hash     Hash ID for the snapshot to load.
    _loadSnapshot: (hashID) =>
        VIZME.trace("Changing hash: [#{@_hashID} -> #{hashID}]", @_cache[hashID])

        @_hashID = hashID

        # Load the specified hash snapshot
        snapshot = @_cache[hashID]

        if not snapshot
            return

        # Update the current hash value
        @_hashLocation = snapshot._page.hashLocation
        if @_hashLocation == null
            @_hashLocation = ''

        id = null
        for sid, s of snapshot
            # Load page properties differently.
            if sid == '_page'
                $.scrollTo(s.yoff)
                @_backHashID = s.backHashID
                continue

            if @_modules.hasOwnProperty(sid)
                 @_modules[sid].loadSnapshot(snapshot[sid])

        $(window).resize()

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleHashChange
# Responds to the hashchanged event and loads the newly set hash tag by recalling it from the
# _cache object and passing the pieces to each of the registered modules.
    _handleHashChange: () =>
        hash   = location.hash
        hashID = ''
        try
            hashID = hash.split('+')[0].replace('#','').replace('!','')
        catch err

        # Ignore the event if the hash is the current hash
        if hashID == @_hashID
            return

        @_hashHistory.push(hashID)
        @_backHashID = hashID
        @_loadSnapshot(hashID)

#___________________________________________________________________________________________________ _handleHashRetry
    _handleHashRetry: () =>
        if @_repeatTimer and @_repeatTimer.data()[0] != @_hashID and
        @_repeatTimer.data()[1] != @_hashLocation
            return

        VIZME.trace('Repeat hash history assignment.')

        data                 = @_repeatTimer.data()
        currentHistoryLength = history.length
        @_setLocationHash(data[0], data[1])

        # If the hash length has changed stop setting the hash
        if currentHistoryLength < history.length or @_compareHashes(data[0], data[1])
            @_repeatTimer.stop()
            @_repeatTimer = null
            VIZME.trace('Hash register attempt success.')
