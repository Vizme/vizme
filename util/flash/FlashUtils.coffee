# vmi.util.FlashUtils.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# require vmi.util.Types

# Flash related utility functions
class FlashUtils

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ checkFlashVersion
# Determines whether or not the installed Flash version meets the specified minimum requirements.
# Requires the swfobject Javascript library. If that library is not available then the check returns
# false with installed version 0.0.
# @param {Object} major        - Minimum allowed major revision
# @param {Object} minor        - Minimum allowed minor revision
# @param {Function} callback   - Callback executed with the results of the test. Function
#                                signature is: callback(success, installedMajor, installedMinor)
    @checkFlashVersion: (major, minor) ->
        major = if Types.isSet(major) then major else VIZME.CONFIG.FLASH_MAJOR
        minor = if Types.isSet(minor) then minor else VIZME.CONFIG.FLASH_MINOR

        if Types.isSet(swfobject)
            v       = swfobject.getFlashPlayerVersion()
            success = v.major > major || (v.major == major && v.minor >= minor)
        else
            v       = {major:0, minor:0}
            success = false

        return [success, v.major, v.minor]
