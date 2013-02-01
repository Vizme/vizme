# vmi.util.io.CookieUtils.coffee
# Vizme, Inc. (C)2011
# Scott Ernst

#require vmi.util.Types

# Static utilities class for reading and writing cookies.
class CookieUtils

#___________________________________________________________________________________________________ write
    ### Writes a Javascript cookie of the specified properties.

        name            - Name of the cookie to write.
        value           - Value of the cookie to write.
        daysToExpire    - Number of days until the cookie expires. If not set the cookie will expire
                          when the session is complete, i.e. the browser closed.
        path            - Path used for the cookie scope. If not set the default domain path will be
                          used. ###
    @write = (name, value, daysToExpire ='', path ='') ->
        if Types.isSet(daysToExpire)
            if daysToExpire >= 0
                date = new Date()
                date.setTime(date.getTime() + 1000*60*60*24*daysToExpire)
                expires = '; expires=' + date.toGMTString()
            else
                expires = '; expires=Thu, 01-Jan-1970 00:00:01 GMT'
        else
            expires = ''

        path            = '; path=' + path
        document.cookie = name + '=' + escape(value) + expires + path

        return true

#___________________________________________________________________________________________________ read
    ### Reads a Javascript cookie and returns its value.
        name            - Name of the cookie to read.
        return          - Value of the cookie or null if it is not set. ###
    @read = (name) ->
        cookies = document.cookie.split(';')
        for c in cookies
            parts = c.split('=')
            if (parts[0] == name)
                return unescape(parts[1])

        return null


#___________________________________________________________________________________________________ remove
    ### Removes the specified cookie from browser storage by setting it to an empty string.
        name            - Name of the cookie to read.
        return          - Whether or not the cookie was successfully removed. ###
    @remove = (name, path) ->
        try
            val = CookieUtils.read(name)
            if Types.isSet(val)
                CookieUtils.write(name, '', -1, path)
                return true
        catch err

        return false

