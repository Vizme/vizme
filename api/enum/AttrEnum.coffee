# vmi.api.enum.AttrEnum.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

class AttrEnum
    # The data prefix used by all Vizme data tags. It acts as a namespace to prevent collisions with
    # other user-specified data tags.
    @PREFIX      = 'data-v-'

    # The identifier used by elements when they are submitted as part of a form or processed
    # submission to a server.
    @DATA_ID     = 'data-v-did'

    # The id specified for jump target navigation.
    @JUMP_ID     = 'data-v-jid'

    # Source id for jumpers that jump to JUMP_IDs.
    @JUMPER_ID   = 'data-v-jsrcid'

    # Attached to script head tags and contains unique identifier for that script.
    @SCRIPT_ID = 'data-v-scriptid'

    # Unique idenfitier for the object, used to identify it within the rendering API. This value is
    # assigned during the initial rendering process and shouldn't be set explicitly.
    @UID = 'data-v-uid'

    # The identifier of the Vizme style to use within the tag element.
    @THEME_ID    = 'data-v-tid'

    # An identifier to use for events (usually click) if no id attribute is specified. Unlike the
    # dom ID this id does not need to be unique.
    @EVENT_ID    = 'data-v-eid'

    # Render identifier for the tag in the format:
    # [Library ID]_[Renderer ID]:[Element ID (if applicable)]
    @RENDER_ID   = 'data-v-rid'

    # Specifies a link that is associated with the object. In button cases this makes the default
    # click event navigate to the specified link:
    @LINK        = 'data-v-lnk'

    # Specifies a URL to navigate to when clicked.
    @CLICKER     = 'data-v-clkr'

    # Contains the Base 64 index to a color scheme, or a JSON encoded dictionary of color schemes.
    @COLORS      = 'data-v-cols'

    # Initialization properties specific to the creation of a DOM item. These should only be used
    # in cases where the properties should not or cannot be specified in the SETTINGS attribute,
    # e.g. JQuery UI initialization objects.
    @INI         = 'data-v-ini'

    # Specifies the render type of the item. If this tag is omitted the LIBRARY value is used as the
    # render type as well as the library.
    @TYPE   = 'data-v-type'

    # Specifies the type of the user interface element.
    @UI_TYPE = 'data-v-uit'

    # A dictionary of events and global callbacks to dispatch when the specified is triggered.
    @EVENTS      = 'data-v-evt'

    # Settings stored in the doms.data('sets') property used for initialization, rendering, and
    # other aspects of interactivity.
    @SETTINGS    = 'data-v-sets'

    # Set on a DOM root that has been rendered by its Renderer at which point it is a
    # fully active part of the DOM.
    @RENDER      = 'data-v-render'

    # Stores data for form submission and replacement
    @DATA = 'data-v-data'

    # Data for check button states
    @CHECK_DATA = 'data-v-chk'

    # Icon properties for the element
    @ICON = 'data-v-icon'

    # Maximum width in pixels for a DOM element
    @MAX_WIDE = 'data-v-maxw'

    # Specifies a relationship where the element with the value targets the specified target id
    @TARGET = 'data-v-target'

    # Specifies membership in a radio button array
    @RADIO_ARRAY = 'data-v-radioArray'

    # Flag to force rendering action
    @FORCE = 'data-v-force'
