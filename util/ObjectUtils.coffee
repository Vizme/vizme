# vmi.util.ObjectUtils.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# require vmi.util.Types
# require vmi.util.ArrayUtils

class ObjectUtils

#___________________________________________________________________________________________________ get
    @get: (source, key, defaultValue) ->
        if not Types.isObject(source)
            return defaultValue

        if not Types.isSet(source[key])
            return defaultValue

        return source[key]

#___________________________________________________________________________________________________ compare
    @compare: (o1, o2) ->
        if o1 == o2
            return true

        if not Types.isObject(o1) or not Types.isObject(o2)
            return false

        if Object.keys(o1).length != Object.keys(o2).length
            return false

        for n,v1 of o1
            v2 = o2[n]

            # Handle Objects
            if Types.isObject(v1) and Types.isObject(v2)
                if v1 == v2
                    continue

                r = ObjectUtils.compare(v1, v2)
                if r
                    continue
                else
                    return false

            # Handle Arrays
            if Types.isArray(v1) and Types.isArray(v2)
                if v1 == v2
                    continue

                r = ArrayUtils.compare(v1, v2)
                if r
                    continue
                else
                    return false


            # Handle Other data types
            if v1 != v2
                return false

        return true