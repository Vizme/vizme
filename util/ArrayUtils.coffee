# vmi.util.ArrayUtils.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# require vmi.util.Types
# require vmi.util.ObjectUtils

class ArrayUtils

#___________________________________________________________________________________________________ extend
    @extend: (src, append) ->
        ### Extends the src array with the append array and returns the src array, which has been
            modified with the appended items. If source is not an array it will be converting into
            an array as part of the extension operation and that new array returned.

            @@@param src:array
                The source array on which to append.

            @@@param apppend:array
                The array containing the items to append to the source array.

            @@@return array
                The src array, which has been modified to include the append array items.
        ###

        if not Types.isArray(src)
            src = [src]

        src.push.apply(src, append)
        return src

#___________________________________________________________________________________________________ combine
    @combine: (a, b) ->
        ###Combines to arrays or to other data types into an array.###

        out = []
        if Types.isArray(a)
            for x in a
                out.push(x)
        else
            out.push(a)

        if Types.isArray(b)
            for x in b
                out.push(x)
        else
            out.push(b)

        return out

#___________________________________________________________________________________________________ get
    @get: (src, index) ->
        l = src.length
        if index < 0
            return src[(l - (-1*index % l)) % l]
        else
            return src[index % l]

#___________________________________________________________________________________________________ contains
    @contains: (sourceArray, item) ->
        if Types.isEmpty(sourceArray)
            return false

        for i in sourceArray
            if item == i
                return true

        return false

#___________________________________________________________________________________________________ find
    @find: (sourceArray, item, startIndex =0) ->
        if Types.isEmpty(sourceArray)
            return -1

        index = 0
        for i in sourceArray
            if index < startIndex
                continue

            if item == i
                return index
            index++

        return -1

#___________________________________________________________________________________________________ diff
    @diff: (array1, array2) ->
        in2  = []
        diff = []

        for item in array1
            bIndex = ArrayUtils.find(array2, item)
            if bIndex == -1
                diff.push(item)
            else
                in2[bIndex] = true

        index = 0
        for item in array2
            if not in2[index]
                diff.push(item)
            index++

        return diff

#___________________________________________________________________________________________________ compare
    @compare: (a1, a2) ->
        if not Types.isArray(a1) or not Types.isArray(a2)
            return false

        if a1.length != a2.length
            return false

        if a1 == a2
            return true

        i = 0
        for v1 in a1
            v2 = a2[i]
            index++

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

#___________________________________________________________________________________________________ missing
    @missing: (needles, haystack) ->
        m = []
        for n in needles
            if not ArrayUtils.contains(haystack, n)
                m.push(n)

        return m

#___________________________________________________________________________________________________ remove
    @remove: (sourceArray, item, maxCount =0) ->
        count     = 0
        while count < 1000
            if maxCount > 0 and count > maxCount - 1
                return sourceArray

            index = ArrayUtils.find(sourceArray, item)
            if index == -1
                return sourceArray

            sourceArray = sourceArray.splice(index, 1)
            count++

        return sourceArray
