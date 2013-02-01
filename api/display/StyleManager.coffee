# vmi.api.display.StyleManager.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.api.enum.AttrEnum
# require vmi.util.ArrayUtils
# require vmi.util.ObjectUtils
# require vmi.util.Types
# require vmi.util.color.ColorMixer
# require vmi.util.string.StringUtils

# A class for creating and managing Vizme custom css styles.
class StyleManager

#===================================================================================================
#                                                                                       C L A S S

    @_ROOT_THEME_PREFIX   = 'v-STYLE-'
    @_STYLE_PREFIX        = 'v-S-'
    @_GRAD_STYLE_PREFIX   = 'v-SG-'
    @_BORDER_STYLE_PREFIX = 'v-SB-'
    @_BACK_CLASS          = 'background-color:#C#;'
    @_FOCAL_CLASS         = 'color:#C#;'
    @_ROOT_CLASS          = 'line-height:#LH#;word-spacing:#WS#;letter-spacing:#LS#px;font-family:#FF#;' # color:#C#;
    @_NORMAL_ROOT_CLASS   = 'color:#C#;'
    @_ACCENT_ROOT_CLASS   = 'color:#C#;'

    @defaultTheme         = null
    @defaultThemeSelector = null

    @_classDefs = [
        { types:['fcl', 'acc'],
        colors:['fcl', 'sft', 'lnk', 'hgh', 'fbn'],
        classes:{
            '#CN#':'color:#CV#; fill:#CV#;',
            '#CN#bor':'border-color:#CV#',
            '#CN#back':'background-color:#CV#'
        }},

        { types:['bck', 'fll'],
        colors:['bck', 'dod', 'brn', 'bor', 'bbn'],
        classes:{
            '#CN#':'background-color:#CV#',
            '#CN#bor':'border-color:#CV#',
            '#CN#front':'color:#CV#; fill:#CV#;'
        }}
    ]

    @_gradDefs = {
        bends:['bck', 'dod', 'brn']
        pairs:[['bck'], ['dod', 'brn']]
        sizes:[16,128],
        types:{
            'u':['x','top'],
            'd':['x','bottom'],
            'l':['y','left'],
            'r':['y','right']
        },
        classes:{
            '#N1##N2#':'background-color:##V1#; background-image:url("#IMG#grad/#TN#/#S#/#V1#/#V2#"); background-repeat:repeat-#T0#; background-position:#T1#;'
        }
    }

    @_jquiDefs = '''
#R# .ui-icon{width:16px;height:16px;background-image:url(#IMG#jqui/icons/256/#FCL#);}
#R# .ui-widget-content{ border:1px solid ##BOR#;background:##BCK# url(#IMG#jqui/flat/40x100/#BCK#) 50% 50% repeat-x;color:##SFT#;}
#R# .ui-widget-content a{color:##SFT#;}
#R# .ui-widget-content .ui-icon{background-image:url(#IMG#jqui/icons/256/#SFT#);}
#R# .ui-widget-header{border:1px solid ##BOR-M1#;background:##BCK-M1# url(#IMG#grad/gd/128/#BCK-M1#/~) 50% 50% repeat-x;color:##FCL#;font-weight:bold;}
#R# .ui-widget-header a{color:##FCL#;}
#R# .ui-widget-header .ui-icon{background-image:url(#IMG#jqui/icons/256/#FCL#);}
#R# .ui-state-default, #R# .ui-widget-content .ui-state-default, #R# .ui-widget-header .ui-state-default{border:1px solid ##FBN#;background:##BBN# url(#IMG#grad/gd/512/#BBN#/~) 50% 50% repeat-x;font-weight:normal;color:##FBN#;}
#R# .ui-state-default a, #R# .ui-state-default a:link, #R# .ui-state-default a:visited{color:##FBN#;text-decoration:none;}
#R# .ui-state-default .ui-icon{background-image:url(#IMG#jqui/icons/256/#FBN#);}
#R# .ui-state-hover, #R# .ui-widget-content .ui-state-hover, #R# .ui-widget-header .ui-state-hover, #R# .ui-state-focus, #R# .ui-widget-content .ui-state-focus, #R# .ui-widget-header .ui-state-focus{border:1px solid ##FBN-M1#;background:##BBN-M1# url(#IMG#grad/gd/512/#BBN-M1#/~) 50% 50% repeat-x;font-weight:normal;color:##FBN-M1#;}
#R# .ui-state-hover a, #R# .ui-state-hover a:hover{color:##FBN-M1#;text-decoration:none;}
#R# .ui-state-hover .ui-icon, #R# .ui-state-focus .ui-icon{background-image:url(#IMG#jqui/icons/256/#FBN-M1#);}
#R# .ui-state-active, #R# .ui-widget-content .ui-state-active, #R# .ui-widget-header .ui-state-active {border:1px solid ##FBN#;background:##FBN# url(#IMG#grad/gd/512/#FBN-M1#/~) 50% 50% repeat-x;font-weight:normal;color:##BBN#;}
#R# .ui-state-active a, #R# .ui-state-active a:link, #R# .ui-state-active a:visited{color:##BBN#;text-decoration:none;}
#R# .ui-state-active .ui-icon{background-image:url(#IMG#jqui/icons/256/#BBN#);}
#R# .ui-state-highlight, #R# .ui-widget-content .ui-state-highlight, #R# .ui-widget-header .ui-state-highlight{border: 1px solid ##HGH#;background:##BCK# url(#IMG#grad/gd/512/#BCK#/~) 50% 50% repeat-x;color:##HGH#;}
#R# .ui-state-highlight a, #R# .ui-widget-content .ui-state-highlight a, #R# .ui-widget-header .ui-state-highlight a{color:##HGH#;}
#R# .ui-state-highlight .ui-icon{background-image:url(#IMG#jqui/icons/256/#HGH#);}
#R# .ui-state-error, #R# .ui-widget-content .ui-state-error, #R# .ui-widget-header .ui-state-error{border: 1px solid #cd0a0a;background:#fff url(#IMG#grad/gd/128/fff/~) 50% bottom repeat-x;color:#cd0a0a;}
#R# .ui-state-error a, .ui-widget-content .ui-state-error a, #R# .ui-widget-header .ui-state-error a{color:#cd0a0a;}
#R# .ui-state-error-text, #R# .ui-widget-content .ui-state-error-text, #R# .ui-widget-header .ui-state-error-text{color:#cd0a0a;}
#R# .ui-state-error .ui-icon, #R# .ui-state-error-text .ui-icon{background-image:url(#IMG#jqui/icons/256/cd0a0a);}
        '''

    @_jqmblDefs = '''
#R# .ui-bar-v {border:1px solid ##~BOR#;background: ##~BCK#;color: ##~FCL#;font-weight:bold;text-shadow:0 -1px 1px ##~BCK-M2#;background-image:-webkit-gradient(linear,left top,left bottom,from(##~BCK-M2#),to(##~BCK#));background-image:-webkit-linear-gradient(##~BCK-M2#,##~BCK#);background-image:-moz-linear-gradient(##~BCK-M2#,##~BCK#);background-image:-ms-linear-gradient(##~BCK-M2#,##~BCK#);background-image:-o-linear-gradient(##~BCK-M2#,##~BCK#);background-image:linear-gradient(##~BCK-M2#,##~BCK#);}
#R# .ui-bar-v, #R# .ui-bar-v input, #R# .ui-bar-v select, #R# .ui-bar-v textarea, #R# .ui-bar-v button{font-family:#FF#;}
#R# .ui-bar-v .ui-link-inherit {color:##~FCL#;}
#R# .ui-bar-v a.ui-link{color: ##~LNK#;font-weight:bold;}
#R# .ui-bar-v a.ui-link:visited {color:##~LNK#;}
#R# .ui-bar-v a.ui-link:hover {color:##~LNK-M2#;}
#R# .ui-bar-v a.ui-link:active {color:##~LNK#;}
#R# .ui-body-v,#R# .ui-overlay-v{border: 1px solid ##BOR#;background: ##BCK#;color: ##FCL#;text-shadow:0 1px 1px ##BCK-M2#;font-weight:normal;background-image:-webkit-gradient(linear,left top,left bottom,from(##BCK-M2#),to(##BCK#));background-image:-webkit-linear-gradient(##BCK-M2#,##BCK#);background-image:-moz-linear-gradient(##BCK-M2#,##BCK#);background-image:-ms-linear-gradient(##BCK-M2#,##BCK#);background-image:-o-linear-gradient(##BCK-M2#,##BCK#);background-image:linear-gradient(##BCK-M2#,##BCK#);}
#R# .ui-overlay-v{background-image:none;border-width:0;}
#R# .ui-body-v, #R# .ui-body-v input, #R# .ui-body-v select, #R# .ui-body-v textarea, #R# .ui-body-v button{font-family:#FF#;}
#R# .ui-body-v .ui-link-inherit {color:##FCL#;}
#R# .ui-body-v .ui-link{color:##LNK#;font-weight:bold;}
#R# .ui-body-v .ui-link:visited{color:##LNK#;}
#R# .ui-body-v .ui-link:hover{color:#LNK-M2#;}
#R# .ui-body-v .ui-link:active{color:##LNK#;}
#R# .ui-btn-up-v {border:1px solid ##BBN-M1#;background:##BBN#;font-weight:bold;color:##FBN#;text-shadow:0 1px 1px ##BBN#;background-image:-webkit-gradient(linear,left top,left bottom,from(##BBN-M2#),to(##BBN#));background-image:-webkit-linear-gradient(##BBN-M2#,##BBN#);background-image:-moz-linear-gradient(##BBN-M2#,##BBN#);background-image:-ms-linear-gradient(##BBN-M2#,##BBN#);background-image:-o-linear-gradient(##BBN-M2#,##BBN#);background-image:linear-gradient(##BBN-M2#,##BBN#);}
#R# .ui-btn-up-v:visited, #R# .ui-btn-up-v a.ui-link-inherit {color:##FBN#;}
#R# .ui-btn-hover-v {border:1px solid ##BBN-M2#;background##BBN-M1#;font-weight:bold;color:##FBN#;text-shadow:0 1px 1px ##BBN-M1#;background-image:-webkit-gradient(linear,left top,left bottom,from(##BBN#),to(##BBN-M1#));background-image:-webkit-linear-gradient(##BBN#,##BBN-M1#);background-image:-moz-linear-gradient(##BBN#,##BBN-M1#);background-image:-ms-linear-gradient(##BBN#,##BBN-M1#);background-image:-o-linear-gradient(##BBN#,##BBN-M1#);background-image:linear-gradient(##BBN#,##BBN-M1#);}
#R# .ui-btn-hover-v:visited, #R# .ui-btn-hover-v:hover, #R# .ui-btn-hover-v a.ui-link-inherit{color:##FBN-M1#;}
#R# .ui-btn-down-v{border:1px solid ##~BBN-M1#;background:##~BBN#;font-weight:bold;color:##~FBN#;text-shadow:0 1px 1px ##~BBN#;background-image:-webkit-gradient(linear,left top,left bottom,from(##~BBN-M2#),to(##~BBN#));background-image:-webkit-linear-gradient(##~BBN-M2#,##~BBN#);background-image:-moz-linear-gradient(##~BBN-M2#,##~BBN#);background-image:-ms-linear-gradient(##~BBN-M2#,##~BBN#);background-image:-o-linear-gradient(##~BBN-M2#,##~BBN#);background-image:linear-gradient(##~BBN-M2#,##~BBN#);}
#R# .ui-btn-down-v:visited, #R# .ui-btn-down-v:hover, #R# .ui-btn-down-v a.ui-link-inherit{color:##~FCL#;}
#R# .ui-btn-up-v, #R# .ui-btn-hover-v, #R# .ui-btn-down-v{font-family:#FF#;text-decoration: none;}
        '''

    @_borderClasses       = {}
    @_borderTagIndex      = 0

    @_globalScales        = [1.0, 1.0]
    @_currentScale        = 1.0
    @_themeIDs            = []
    @_themeUIDs           = []
    @_loadingThemes       = []
    @themes               = {}
    @_defaultTheme        = null
    @_currentTheme        = null
    @_styleBody           = false

#___________________________________________________________________________________________________ constructor
# Creates a new StyleManager instance.
    constructor: () ->
        @cls = StyleManager

        @_createBorderClass('a', 1, 'so')
        @_createBorderClass('a', 1, 'so', 's')
        @_createBorderClass('a', 1, 'so', 'm')
        @_createBorderClass('a', 1, 'dot')
        @_createBorderClass('a', 1, 'dot', 's')
        @_createBorderClass('a', 1, 'dot', 'm')

        @registerBorderClassesInDOM()

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ globalScale
    globalScale: () =>
        return @cls._currentScale

#___________________________________________________________________________________________________ existingThemes
    existingThemes: () =>
        ###Returns the list of theme IDs and theme UIDs that have already been loaded, created, and
        are ready for use.###
        s = @cls._themeIDs + @cls._themeUIDs
        if Types.isString(s)
            return [s]

#___________________________________________________________________________________________________ loadingThemes
    loadingThemes: () =>
        ###Returns the list of styles (uids/ids) that are currently in the loading process but not
        yet created.###
        return @cls._loadingThemes.concat()

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ getDOMTheme
    getDOMColors: (target) =>
        s = @getDOMTheme(target)

        accent  = false
        parent  = target
        while parent and parent.length > 0
            if parent.hasClass('v-STY-ACCENT')
                accent = true
                break
            else if parent.hasClass('v-STY-NORMAL')
                break

            parent = parent.parent()

        c = s.cols
        if accent
            b = {dod:c.flldod, brn:c.fllbrn, bor:c.fllbor, bck:c.fllbck, bbn:c.fllbbn}
            f = {fcl:c.accfcl, hgh:c.acchgh, lnk:c.acclnk, sft:c.accsft, fbn:c.accfbn}
        else
            b = {dod:c.bckdod, brn:c.bckbrn, bor:c.bckbor, bck:c.bckbck, bbn:c.bckbbn}
            f = {fcl:c.fclfcl, hgh:c.fclhgh, lnk:c.fcllnk, sft:c.fclsft, fbn:c.fclfbn}

        return {front:f, back:b}

#___________________________________________________________________________________________________ getDOMTheme
    getDOMTheme: (target) =>
        ### Recurse through parents to find the currently applied theme. ###
        parent  = target
        while parent and parent.length > 0
            sid = parent.attr(AttrEnum.THEME_ID)
            if Types.isSet(sid)
                sid = @cls._ROOT_THEME_PREFIX + sid.substr(1)
                s   = @cls.styles[sid]
                if s
                    return s

            parent = parent.parent()

        return @cls._defaultTheme

#___________________________________________________________________________________________________ getThemeColor
    getThemeColor: (themeID, bundleID, colorID) =>
        if themeID
            theme = @cls.themes[@cls._ROOT_THEME_PREFIX + themeID]
            if not theme
                theme = @cls._defaultTheme
        else
            theme = @cls._defaultTheme

        return theme.cols[bundleID + colorID]

#___________________________________________________________________________________________________ exists
    exists: (theme) =>
        ###Determines whether or not the specified theme (name/uid/id) is already loaded and
        available for use.

        @@@param theme:string
            The theme name/uid/id to check.

        @@@return boolean
            Whether or not the theme already exists.
        ###

        if Types.isEmpty(theme)
            return false

        sid = @cleanIdentifiers(theme)
        if theme.substr(0,1) == '@'
            return ArrayUtils.contains(@cls._themeIDs, sid)

        return ArrayUtils.contains(@cls._themeUIDs, sid)

#___________________________________________________________________________________________________ isLoading
    isLoading: (theme) =>
        ###Determines whether or not the specified theme (name/uid/id) is already in the loading
        process by another load request.

        @@@param theme:string
            The theme name/uid/id to check.

        @@@returns boolean
            Whether or not the theme exists in the loading state.
        ###

        if Types.isEmpty(theme)
            return false

        sid = @cleanIdentifiers(theme)
        return ArrayUtils.contains(@cls._loadingThemes, sid)

#___________________________________________________________________________________________________ cleanIdentifiers
    cleanIdentifiers: (nameOrIDs) =>
        ###Converts the theme name/uid/id input (string or array of strings) into properly formatted
        uid or ids.

        @@@param nameOrIDs:string,array
            The name/uid/id of the theme to convert or a list of name/uid/ids to convert.

        @@@return string,array
            Either a string or an array of strings for the converted theme identifiers.
        ###
        if Types.isEmpty(nameOrIDs)
            return nameOrIDs

        sids = if Types.isString(nameOrIDs) then [nameOrIDs] else nameOrIDs
        res  = []
        for sid in sids
            if sid.substr(0,1) == '@'
                res.push(sid)
            else if sid.substr(0,3) == '%40'
                res.push('@' + sid.substr(3))
            else
                res.push(sid.replace(/[^A-Za-z0-9_-]+/g, '').toLowerCase())
        if Types.isString(nameOrIDs)
            return res[0]

        return res

#___________________________________________________________________________________________________ setThemeLoading
    setThemeLoading: (themes) =>
        ###Sets the theme name(s)/uid(s)/id(s) to their "loading" state.

        @@@param themes:string,array
            The theme(s) name/uid/id(s) to place in the loading state.

        @@@return boolean
            True if the themes were marked as loading, false if the process failed.
        ###
        if Types.isEmpty(themes)
            return false

        if Types.isString(themes)
            themes = [themes]

        sids = @cleanIdentifiers(themes)
        for s in sids
            if not ArrayUtils.contains(@cls._loadingThemes, s)
                @cls._loadingThemes.push(s)

        return true

#___________________________________________________________________________________________________ loadThemes
    loadThemes: (themes, callback, data) =>
        ###Executes a load operation for the specified theme name/uid/id (either a single string or
        list of strings).

        @@@param themes:string,array
            Either a single theme name/uid/id or a list of theme name/uid/ids to load.

        @@@param callback:function -default=null
            A function to exectue when the themes have been loaded and are ready for use. The
            callback signature is callback(data, request).

        @@@param data:object -default=null
            Data to pass back in the first argument of the callback.

        @@@return boolean
            Returns true if a load operation was initiated, or false if the theme(s) were already
            loaded. In either case the callback will be executed.
        ###

        # Skip if themes is empty or invalid
        if Types.isEmpty(themes)
            if Types.isFunction(callback)
                callback(data)
            return false

        # Converts names to uids and makes sure ids conform to the proper prefix '@'
        themes = @cleanIdentifiers(themes)
        if Types.isString(themes)
            themes = [themes]

        # Only load themes that have not already been loaded
        loads = []
        skips = @loadingThemes()
        for s in themes
            if @exists(s) or @isLoading(s)
                continue

            loads.push(s)
            @cls._loadingThemes.push(s)

        # If everything has been loaded already, skip the load process
        if loads.length == 0
            if Types.isFunction(callback)
                callback(data)
            return false

        VIZME.api('Theme', 'get', {themes:loads, skip:skips}, @_handleThemeLoaded,
                  {data:data, cb:callback})
        return true

#___________________________________________________________________________________________________ getThemeIDs
    getThemeIDs: (rootDOM, unloadedOnly) =>
        ###Searches through the rootDOM looking for any specified themes in the data-v-sid attrs.

        @@@param rootDOM:object -default=$('body')
            The rootDOM in which to search for themes. If empty or invalid the body will be searched
            instead.

        @@@param unloadedOnly:boolean -default=false
            Whether or not the results should contain only unloaded themes or if all themes within
            the rootDOM should be returned regardless of their load state.

        @@@return array
            The list of clean theme identifiers (uids/ids) that were found in the rootDOM.
        ###

        if Types.isNone(rootDOM)
            rootDOM = $('body')
        rootDOM = $(rootDOM)

        # Get all tags with a data-v-sid attribute
        styleTags = rootDOM.find("[#{AttrEnum.THEME_ID}]")
        if styleTags.length == 0
            return []

        themes      = []
        existingIDs = @cls._themeIDs
        styleTags.each((index, element) ->
            me  = $(this)
            sid = me.attr(AttrEnum.THEME_ID)
            if not unloadedOnly or not ArrayUtils.contains(existingIDs, sid)
                themes.push(sid)
        )

        return @cleanIdentifiers(themes)

#___________________________________________________________________________________________________ createDefaultTheme
    createDefaultTheme: (data, styleBody) =>
        ###Creates the default theme from the specified theme data.

        @@@param data:object
            The theme data returned from the server to load as the default theme.

        @@@param styleBody:boolen -default=false
            Whether or not the default theme should be applied to the body. The false case is needed
            for embedding in pages that have their own theme information. The true case is used
            internally by Vizme for rendering VizmeML pages and related.
        ###

        res = @createTheme(data)
        cleanID = data.id.substr(1).replace(/~/g, '-')
        d   = @cls._ROOT_THEME_PREFIX + cleanID
        ds  = '.' + d
        @cls.defaultTheme         = d
        @cls.defaultThemeSelector = ds
        @cls._defaultTheme        = data

        @_styleBody = styleBody
        if styleBody
            @_currentTheme = cleanID
            $('body').addClass(d + ' ' + d + '-BNRM ' + d + '-FNRM')
            @refreshFontSizes()
        return

#___________________________________________________________________________________________________ createTheme
    createTheme: (data) =>
        if not @_setThemeLoaded(data)
            return null

        sid        = data.id.substr(1)
        sidClean   = sid.replace(/~/g, '-')
        styleTagID = 'v-STYLETAG-' + sidClean
        if $('.' + styleTagID).length != 0
            return null

        themeClass              = @cls._ROOT_THEME_PREFIX + sidClean
        styleRoot               = '\n.' + themeClass
        data['class']           = themeClass
        @cls.themes[themeClass] = data

        # Create the theme's style tag
        s = "<style id='#{styleTagID}' #{AttrEnum.THEME_ID}='#{sid}'>" + styleRoot +
            (" {#{@cls._ROOT_CLASS}}").replace('#C#', data.cols.fclfcl).
            replace('#FS#', data.fs).replace('#FF#', data.ff).replace('#WS#', data.ws).
            replace('#LH#', data.lns).replace('#LS#', data.lttrs)

        s += "#{styleRoot} .v-STY-NORMAL {#{@cls._NORMAL_ROOT_CLASS.replace('#C#', data.cols.fclfcl)}}"
        s += "#{styleRoot} .v-STY-ACCENT {#{@cls._ACCENT_ROOT_CLASS.replace('#C#', data.cols.accfcl)}}"

        s += "#{styleRoot}-BNRM {#{@cls._BACK_CLASS.replace('#C#', data.cols.bckbck)}}"
        s += "#{styleRoot}-BACC {#{@cls._BACK_CLASS.replace('#C#', data.cols.fllbck)}}"
        s += "#{styleRoot}-FNRM {#{@cls._FOCAL_CLASS.replace('#C#', data.cols.fclfcl)}}"
        s += "#{styleRoot}-FACC {#{@cls._FOCAL_CLASS.replace('#C#', data.cols.accfcl)}}"

        #-------------------------------------------------------------------------------------------
        # SINGLE CLASS DEFINITIONS
        # Create a bare hex color palette with color bends
        palette   = {cols:{}, accs:{}}
        for n,v of data.cols
            p     = if StringUtils.startsWith(n, ['acc','fll']) then palette.accs else palette.cols
            cn    = n.substr(3).toUpperCase()
            cm    = new ColorMixer(v)
            p[cn] = cm.bareHex()

            i = 1
            for cb in cm.getBendShifts('bhex', 3, 10)
                p[cn + '-M' + i] = cb
                i++

        singleSources = []
        idents        = PAGE.SCRIPTS.idents
        if idents.indexOf('jqui') != -1
            singleSources.push(@cls._jquiDefs)
        if idents.indexOf('jqmbl') != -1
            singleSources.push(@cls._jqmblDefs)

        for singleSource in singleSources
            snorm = @_replace(singleSource, null, 'FF', data.ff)
            sacc  = snorm
            for cn,cnorm of palette.cols
                can  = '~' + cn
                cacc = palette.accs[cn]
                snorm = @_replace(@_replace(snorm, null, cn, cnorm), null, can, cacc)
                sacc  = @_replace(@_replace(sacc, null, cn, cacc), null, can, cnorm)

            snorm = @_replace(snorm, null, 'IMG', URLUtils.getImageURL())
            sacc  = @_replace(sacc, null, 'IMG', URLUtils.getImageURL())

            s += '\n' + @_replace(snorm, null, 'R', styleRoot.substr(1))
            s += '\n' + @_replace(snorm, null, 'R', styleRoot.substr(1) + ' .v-STY-NORMAL')
            s += '\n' + @_replace(sacc, null,  'R', styleRoot.substr(1) + ' .v-STY-ACCENT')

        #-------------------------------------------------------------------------------------------
        # GRADIENTS
        # Create a bare hex color palette with color bends
        palette = {cols:{}, accs:{}}
        for n,v of data.cols
            cm = new ColorMixer(v)
            cn = n.substr(3)
            c  = {base:cm, val:cm.bareHex(), cols:{}}

            i = 1
            for cb in cm.getBendShifts('bhex', 3, 5)
                c.cols['m' + i] = cb
                i++

            p = if StringUtils.startsWith(n, ['acc','fll']) then palette.accs else palette.cols
            p[cn] = c

        gdef  = @cls._gradDefs
        gsize = gdef.sizes[0]
        while gsize <= gdef.sizes[1]
            for tn,tv of gdef.types
                for n,v of gdef.classes
                    sn  = '.' + @cls._GRAD_STYLE_PREFIX + tn + gsize + '-' + n
                    sv  = @_replace(v,  null, 'IMG', URLUtils.getImageURL())
                    sv  = @_replace(sv, null, 'TN', tn)
                    sv  = @_replace(sv, null, 'S', gsize + '')
                    sv  = @_replace(sv, null, 'T0', tv[0])
                    sv  = @_replace(sv, null, 'T1', tv[1])

                    # Bend Colors
                    for nc1 in gdef.bends
                        vc1  = palette.cols[nc1]
                        avc1 = palette.accs[nc1]
                        lsn  = @_replace(sn, null, 'N1', nc1)

                        for nc2,vc2 of vc1.cols
                            lsn2 = @_replace(lsn, null, 'N2', nc2)

                            lsv = @_replace(sv, null, 'V1', vc1.val)
                            lsv = @_replace(lsv, null, 'V2', vc2)
                            s  += styleRoot + ' ' + lsn2 + '{' + lsv + '}'
                            s  += styleRoot + ' .v-STY-NORMAL ' + lsn2 + '{' + lsv + '}'

                            avc2 = avc1.cols[nc2]
                            lsv  = @_replace(sv, null, 'V1', avc1.val)
                            lsv  = @_replace(lsv, null, 'V2', avc2)
                            s   += styleRoot + ' .v-STY-ACCENT ' + lsn2 + '{' + lsv + '}'


                    # Paired Colors
                    for nc1 in gdef.pairs[0]
                        vc1  = palette.cols[nc1]
                        avc1 = palette.accs[nc1]
                        lsn  = @_replace(sn, null, 'N1', nc1)

                        for nc2 in gdef.pairs[1]
                            if nc1 == nc2
                                continue

                            lsn2 = @_replace(lsn, null, 'N2', nc2)

                            vc2 = palette.cols[nc2]
                            lsv = @_replace(sv, null, 'V1', vc1.val)
                            lsv = @_replace(lsv, null, 'V2', vc2.val)
                            s  += styleRoot + ' ' + lsn2 + '{' + lsv + '}'
                            s  += styleRoot + ' .v-STY-NORMAL ' + lsn2 + '{' + lsv + '}'

                            avc2 = palette.accs[nc2]
                            lsv  = @_replace(sv, null, 'V1', avc1.val)
                            lsv  = @_replace(lsv, null, 'V2', avc2.val)
                            s   += styleRoot + ' .v-STY-ACCENT ' + lsn2 + '{' + lsv + '}'
            gsize = 2*gsize

        #-------------------------------------------------------------------------------------------
        # BASIC THEMES
        # Create an HSL color palette with color bends
        palette = {}
        for n,v of data.cols
            cm         = new ColorMixer(v)
            c          = {base:cm.rawHsl(), up:[], dwn:[]}
            c.dwn      = cm.getDownShifts('hsl', 3, 5)
            c.up       = cm.getUpShifts('hsl', 3, 5)
            c.col      = cm.hsl()
            palette[n] = c

        for def in @cls._classDefs
            for n,v of def.classes
                for t in def.types
                    for baseID in def.colors
                        palette[t + 'cv'] = palette[t + baseID]
                        sn    = '.' + @cls._STYLE_PREFIX + n.replace('#CN#', baseID)
                        sv    = v
                        svt   = v
                        svd1  = v
                        svd2  = v
                        svd3  = v
                        svu1  = v
                        svu2  = v
                        svu3  = v
                        for cid in def.colors.concat(['cv'])
                            c    = palette[t + cid]
                            sv   = @_replace(sv,   t, cid, c.col)
                            svd1 = @_replace(svd1, t, cid, c.dwn[0])
                            svd2 = @_replace(svd2, t, cid, c.dwn[1])
                            svd3 = @_replace(svd3, t, cid, c.dwn[2])
                            svu1 = @_replace(svu1, t, cid, c.up[0])
                            svu2 = @_replace(svu2, t, cid, c.up[1])
                            svu3 = @_replace(svu3, t, cid, c.up[2])
                            svt  = @_replace(svt,  t, cid, 'transparent')
                        if c.base[2] > 60
                            svm1 = svd1
                            svm2 = svd2
                            svm3 = svd3
                        else
                            svm1 = svu1
                            svm2 = svu2
                            svm3 = svu3

                        cg = [['',         sv],                             # base
                              ['-d1',      svd1],                           # darker 1
                              ['-d2',      svd2],                           # darker 2
                              ['-d3',      svd3],                           # darker 3
                              ['-u1',      svu1],                           # lighter 1
                              ['-u2',      svu2],                           # lighter 2
                              ['-u3',      svu3],                           # lighter 3
                              ['-m1',      svm1],                           # shift 1
                              ['-m2',      svm2],                           # shift 2
                              ['-m3',      svm3],                           # shift 3

                              ['-h',       sv],   ['-h:hover',       svm1], # base hover
                              ['-bh',      sv],   ['-bh:hover',      svm3], # big hover

                              ['-trans',   svt],  ['-trans:hover',   sv],   # transparent hover
                              ['-m1trans', svt],  ['-m1trans:hover', svm1], # shift 1 transparent hover
                              ['-mbtrans', svt],  ['-mbtrans:hover', svm3], # shift big transparent hover

                              ['-m1h',     svm1], ['-m1h:hover',     svm2], # shift 1 hover
                              ['-m2h',     svm2], ['-m2h:hover',     svm3], # shift 2 hover

                              ['-d1h',     svd1], ['-d1h:hover',     svd2], # darker 1 hover
                              ['-d2h',     svd2], ['-d2h:hover',     svd3], # darker 2 hover

                              ['-u1h',     svu1], ['-u1h:hover',     svu2], # lighter 1 hover
                              ['-u2h',     svu2], ['-u2h:hover',     svu3], # lighter 2 hover
                        ]

                        for item in cg
                            base = "#{sn + item[0]} {#{item[1]}}"
                            if def.types[0] == t
                                s  += styleRoot + ' ' + base + styleRoot + ' .v-STY-NORMAL ' + base
                            else
                                s  += styleRoot + ' .v-STY-ACCENT ' + base

        for n,v of @cls._borderClasses
            s += @_populateBorderClass(n, themeClass)

        s += '\n</style>'
        $('head').append(s)
        @_refreshThemeFontSize(themeClass)
        return true

#___________________________________________________________________________________________________ registerBorderClassesInDOM
    registerBorderClassesInDOM: (rootDOM) =>
        rootDOM = if rootDOM then $(rootDOM) else $('body')
        bcs     = []

        rootDOM.find("[class^=#{@cls._BORDER_STYLE_PREFIX}]").each((index, element) ->
            cs = $(this).attr('class')
            if not cs
                return
            for c in cs.split(' ')
                c = c.replace(' ','').replace('\n','').replace('\t','')
                if StringUtils.startsWith(c, @cls._BORDER_STYLE_PREFIX)
                    bcs.append(c)
        )

        if bcs.length > 0
            @registerBorderClasses(bcs)

#___________________________________________________________________________________________________ registerBorderClasses
    registerBorderClasses: (names, rootTheme) =>
        res = []
        sty = "<style id='v-BSTYLETAG-#{@cls._borderTagIndex}'>"
        @cls._borderTagIndex++

        if Types.isString(names)
            r = @_registerBorderClass(names)
            if r
                res.push(r)
        else
            for n in names
                r = @_registerBorderClass(n)
                if r
                    res.push(r)

        if res.length == 0
            return false

        for r in res
            sty += @_populateBorderClass(r)

        sty += '\n</style>'
        $('head').append(sty)
        return true

#___________________________________________________________________________________________________ setGlobalFontScale
    setGlobalFontScale: (value, resize) =>
        if !Types.isEmpty(value)
            if Types.isArray(value)
                @cls._globalScales = value
            else
                @cls._globalScales = [value, value]

        win   = $(window)
        gss   = @cls._globalScales
        scale = if win.height() > win.width() then gss[1] else gss[0]
        if @cls._currentScale == scale
            return

        @cls._currentScale = scale
        @refreshFontSizes()

        if !Types.isSet(resize) or resize
            VIZME.resize()

#___________________________________________________________________________________________________ refreshFontSizes
    refreshFontSizes: (themes, rootDOM) =>
        if Types.isString(themes)
            @_refreshThemeFontSize(themes, rootDOM)
        else if Types.isArray(themes)
            for s in themes
                @_refreshThemeFontSize(s, rootDOM)
        else
            for n,v of @cls.themes
                @_refreshThemeFontSize(n, rootDOM)

#___________________________________________________________________________________________________ setTheme
    setTheme: (themeID) =>
        if not @_styleBody
            return false

        cleanID = themeID.replace(/~/g, '-').replace('@', '')
        old = @cls._ROOT_THEME_PREFIX + @_currentTheme
        d   = @cls._ROOT_THEME_PREFIX + cleanID

        $('body').removeClass(old + ' ' + old + '-BNRM ' + old + '-FNRM')
        $('body').addClass(d + ' ' + d + '-BNRM ' + d + '-FNRM')
        @_currentTheme = cleanID
        return true

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _setThemeLoaded
    _setThemeLoaded: (styleData) =>
        ArrayUtils.remove(@cls._loadingThemes, styleData.id)
        ArrayUtils.remove(@cls._loadingThemes, styleData.uid)

        if ArrayUtils.contains(@cls._themeIDs, styleData.id)
            return false

        @cls._themeIDs.push(styleData.id)
        @cls._themeUIDs.push(styleData.uid)
        return true

#___________________________________________________________________________________________________ _replace
    _replace: (src, keyPrefix, key, value) =>
        v   = src.replace(@_getValueRegEx(key), value)
        if not Types.isEmpty(keyPrefix)
            v = v.replace(@_getValueRegEx(keyPrefix + key), value)
        return v

#___________________________________________________________________________________________________ _getValueRegEx
    _getValueRegEx: (value) =>
        return new RegExp('#' + value.toUpperCase() + '#','g')

#___________________________________________________________________________________________________ _refreshThemeFontSize
    _refreshThemeFontSize: (themeClass, rootDOM) =>
        rootDOM = if rootDOM then $(rootDOM) else $('body')

        if not StringUtils.startsWith(themeClass, @cls._ROOT_THEME_PREFIX)
            themeClass = @cls._ROOT_THEME_PREFIX + themeClass

        fs = 10*@cls._currentScale*@cls.themes[themeClass].fs

        refresh = (me) ->
            currentFS = 1.0*me.css('font-size').replace('px','')
            if currentFS == fs
                return

            parentFS = 1.0*me.parent().css('font-size').replace('px','')
            me.css('font-size', fs/parentFS + 'em')


        # Refresh root elements
        rootDOM.each((index, element) ->
            me = $(this)
            if me.hasClass(themeClass)
                refresh(me)
        )

        # Find sub elements and refresh as well
        rootDOM.find(themeClass).each((index, element) ->
            refresh($(this))
        )

#___________________________________________________________________________________________________ _registerBorderClass
    _registerBorderClass: (name) =>
        c   = name.replace(@cls._BORDER_STYLE_PREFIX, '').split('-')
        r   = if c[4] then c[4].replace('_','.') else null
        return @_createBorderClass(c[0], c[1].replace('_', '.'), c[2], r, c[3])

#___________________________________________________________________________________________________ _createBorderClass
    _createBorderClass: (sides, width, style, roundness, color) =>
        cname = @cls._BORDER_STYLE_PREFIX
        vals  = {}

        # Handle hover
        hover = sides.indexOf('h') != -1

        # Handle sides
        if sides.indexOf('a') != -1
            cname      += 'a-'
            vals.border = ''
        else
            if sides.indexOf('t') != -1
                vals['border-top'] = ''
                cname +=  't'

            if sides.indexOf('r') != -1
                vals['border-right'] = ''
                cname +=  'r'

            if sides.indexOf('b') != -1
                vals['border-bottom'] = ''
                cname +=  'b'

            if sides.indexOf('l') != -1
                vals['border-left'] = ''
                cname +=  'l'

            cname += '-'

        # Handle width
        width = (width + '').replace('px','')
        cname += width.replace('.','_') + '-'
        @_addBorderProp(width + 'px', vals)

        # Handle style
        switch style
            when 'dotted','dot'
                pn = 'dot'
                pv = 'dotted'
            when 'dashed','dash'
                pn = 'dash'
                pv = 'dashed'
            when 'double', 'two'
                pn = 'two'
                pv = 'double'
            when 'dot-dash','ddash'
                pn = 'ddash'
                pv = 'dot-dash'
            when 'dot-dot-dash','dddash'
                pn = 'dddash'
                pv = 'dot-dot-dash'
            else
                pn = 'so'
                pv = 'solid'

        cname += pn + '-'
        @_addBorderProp(pv, vals)

        # Handle color
        pn = '#CN#'
        pv = '#CV#'
        cname += pn
        @_addBorderProp(pv, vals)

        # Handle Roundness
        if not Types.isNone(roundness)
            switch roundness
                when 'small','s'
                    pn = 's'
                    pv = '0.25em'
                when 'medium','med','m'
                    pn = 'm'
                    pv = '0.5em'
                when 'large','l'
                    pn = 'l'
                    pv = '1.0em'
                else
                    pn = roundness.replace('.','_')
                    pv = roundness
                    if pv.indexOf('em') == -1 and pv.indexOf('px') == -1
                        v = 1.0*pv
                        pv += if v > 1 and round(v) == v then 'px' else 'em'

            cname += '-' + pn
            vals['border-radius'] = pv

        out = ''
        for n,v of vals
            out += n + ':' + v + ';'

        @cls._borderClasses[cname] = out
        return cname

#___________________________________________________________________________________________________ _populateBorderClass
    _populateBorderClass: (name, rootTheme) =>
        value = @cls._borderClasses[name]

        if not value
            return ''

        s     = ''
        roots = []
        if Types.isString(rootTheme)
            roots.push(rootTheme)
        else
            for n,v of @cls.themes
                roots.push(n)

        for n in roots
            styleRoot  = '\n.' + n + ' .'
            data       = @cls.themes[n]

            for col, val of data.cols
                cn = name.replace('#CN#', col)
                cv = value.replace(/#CV#/g, val)
                s += styleRoot + cn + ' {'+ cv + '}'

        return s

#___________________________________________________________________________________________________ _addBorderProp
    _addBorderProp: (value, borders) =>
        for n,v of borders
            borders[n] += value + ' '

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleThemeLoaded
    _handleThemeLoaded: (request) =>
        callback = request.localData.cb
        cbData   = request.localData.data

        if not request.success
            VIZME.trace('Theme.get failure:', request)
            if Types.isFunction(callback)
                callback(cbData, request)
            return

        for s in request.data.themes
            @createTheme(s)

        if Types.isFunction(callback)
            callback(cbData, request)
        return
