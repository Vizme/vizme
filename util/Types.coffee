# vmi.util.Types
# Vizme, Inc. (C)2011-2012
# Scott Ernst

class Types

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ isInstance
# Determines whether or not the target is an instance of the specified class or class name.
    @isInstance: (target, classOrName) ->
        try
            if not Types.isObject(target)
                return false

            if Types.isString(classOrName)
                return target.constructor.name == classOrName
            else
                return target.constructor == classOrName
        catch err
            return false

#___________________________________________________________________________________________________ isFunction
# Determines if the target is of the function type.
    @isFunction: (target) ->
        return typeof(target) == 'function'

#___________________________________________________________________________________________________ isNumber
# Determines if the target is of the number type.
    @isNumber: (target) ->
        return typeof(target) == 'number'

#___________________________________________________________________________________________________ isBoolean
# Determines if the target is of the boolean type.
    @isBoolean: (target) ->
        return typeof(target) == 'boolean'

#___________________________________________________________________________________________________ isString
# Determines if the target is of the string type.
    @isString: (target) ->
        return typeof(target) == 'string'

#___________________________________________________________________________________________________ isObject
# Determines if the target is of the general object type.
    @isObject: (target) ->
        return typeof(target) == 'object' and not Types.isArray(target) and not Types.isNone(target)

#___________________________________________________________________________________________________ isArray
# Determines if the target is of the array type.
    @isArray: (target) ->
        return $.isArray(target)

#___________________________________________________________________________________________________ isError
# Determines if the target is an Error object.
    @isError: (target) ->
        return typeof(target) == 'object' and Types.isSet(target.stack) and Types.isSet(target.message)

#___________________________________________________________________________________________________ isSet
# Determines if the target is not undefined (but may be null).
    @isSet: (target) ->
        return typeof(target) != 'undefined'

#___________________________________________________________________________________________________ isNone
# Determines if the target is null or undefined.
    @isNone: (target) ->
        return not Types.isSet(target) or Types.isNull(target)

#___________________________________________________________________________________________________ isEmpty
# Determines if the target is undefined, empty, or has no attributes or members.
    @isEmpty: (target) ->
        if not Types.isSet(target) or target == null
            return true

        try
            if target.length == 0
                return true
        catch err

        if Types.isObject(target)
            for k,v of target
                return false

            return true

        return false

#___________________________________________________________________________________________________ isNull
    # Determines if the target is set to null, i.e. null but not undefined.
    @isNull: (target) ->
        return Types.isSet(target) and target == null
