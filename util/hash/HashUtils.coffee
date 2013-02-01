# HashUtils.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.util.Types
# require vmi.util.string.StringUtils

class HashUtils

#===================================================================================================
#                                                                                       C L A S S

    @HEX_CHARS = '0123456789abcdef'

    @_CSIZE    = 8

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ sha256
    @sha256: (s) ->
        cls = HashUtils
        s   = cls._prep(s)
        return cls._binb2Hex(cls._coreSHA256(cls._str2Binb(s), cls._CSIZE*s.length))

#___________________________________________________________________________________________________ sha256hmac
    @sha256hmac: (key, data, digestType) ->
        cls  = HashUtils
        key  = cls._prep(key)
        data = cls._prep(data)
        bin  = cls._coreHmacSHA256(key, data)

        if Types.isString(digestType)
            digestType = digestType.toLowerCase()

            if digestType == 'str'
                return cls._binb2Str(bin)
            else if digestType == 'hex'
                return cls._binb2Hex(bin)

        return cls._binb2B64(bin)

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _coreSHA256
    @_coreSHA256: (m, l) ->
        cls   = HashUtils
        sfAdd = cls._sfAdd
        K     = new Array(0x428A2F98,0x71374491,0xB5C0FBCF,0xE9B5DBA5,0x3956C25B,0x59F111F1,
                          0x923F82A4,0xAB1C5ED5,0xD807AA98,0x12835B01,0x243185BE,0x550C7DC3,
                          0x72BE5D74,0x80DEB1FE,0x9BDC06A7,0xC19BF174,0xE49B69C1,0xEFBE4786,
                          0xFC19DC6,0x240CA1CC,0x2DE92C6F,0x4A7484AA,0x5CB0A9DC,0x76F988DA,
                          0x983E5152,0xA831C66D,0xB00327C8,0xBF597FC7,0xC6E00BF3,0xD5A79147,
                          0x6CA6351,0x14292967,0x27B70A85,0x2E1B2138,0x4D2C6DFC,0x53380D13,
                          0x650A7354,0x766A0ABB,0x81C2C92E,0x92722C85,0xA2BFE8A1,0xA81A664B,
                          0xC24B8B70,0xC76C51A3,0xD192E819,0xD6990624,0xF40E3585,0x106AA070,
                          0x19A4C116,0x1E376C08,0x2748774C,0x34B0BCB5,0x391C0CB3,0x4ED8AA4A,
                          0x5B9CCA4F,0x682E6FF3,0x748F82EE,0x78A5636F,0x84C87814,0x8CC70208,
                          0x90BEFFFA,0xA4506CEB,0xBEF9A3F7,0xC67178F2)
        HASH  = new Array(0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C,
                          0x1F83D9AB, 0x5BE0CD19)
        W     = new Array(64)

        # append padding
        m[l >> 5] |= 0x80 << (24 - l % 32)
        m[((l + 64 >> 9) << 4) + 15] = l

        i = 0
        while i < m.length
            a = HASH[0]
            b = HASH[1]
            c = HASH[2]
            d = HASH[3]
            e = HASH[4]
            f = HASH[5]
            g = HASH[6]
            h = HASH[7]

            for j in [0..63]
                if j < 16
                    W[j] = m[j + i]
                else
                    W[j] = sfAdd(sfAdd(sfAdd(cls._gamma1256(W[j - 2]), W[j - 7]),
                                       cls._gamma0256(W[j - 15])), W[j - 16])

                T1 = sfAdd(sfAdd(sfAdd(sfAdd(h, cls._sigma1256(e)), cls._ch(e, f, g)), K[j]), W[j])
                T2 = sfAdd(cls._sigma0256(a), cls._maj(a, b, c))
                h = g
                g = f
                f = e
                e = sfAdd(d, T1)
                d = c
                c = b
                b = a
                a = sfAdd(T1, T2)

            HASH[0] = sfAdd(a, HASH[0])
            HASH[1] = sfAdd(b, HASH[1])
            HASH[2] = sfAdd(c, HASH[2])
            HASH[3] = sfAdd(d, HASH[3])
            HASH[4] = sfAdd(e, HASH[4])
            HASH[5] = sfAdd(f, HASH[5])
            HASH[6] = sfAdd(g, HASH[6])
            HASH[7] = sfAdd(h, HASH[7])
            i += 16

        return HASH

#___________________________________________________________________________________________________ _str2Binb
    @_str2Binb: (s) ->
        cls  = HashUtils
        bin  = new Array()
        mask = (1 << cls._CSIZE) - 1

        i = 0
        while i < s.length*cls._CSIZE
            bin[i>>5] |= (s.charCodeAt(i / cls._CSIZE) & mask) << (24 - i%32)
            i += cls._CSIZE

        return bin

#___________________________________________________________________________________________________ _binb2Str
    @_binb2Str: (barray) ->
        cls  = HashUtils
        out  = ''
        mask = (1 << cls._CSIZE) - 1

        i = 0
        while i < 32*barray.length
            out += String.fromCharCode((barray[i>>5] >>> (24 - i%32)) & mask)
            i   += cls._CSIZE

        return out

#___________________________________________________________________________________________________ _binb2Hex
    @_binb2Hex: (barray) ->
        chars = HashUtils.HEX_CHARS
        out   = ''
        i     = 0
        while i < 4*barray.length
            out += chars.charAt((barray[i>>2] >> ((3 - i%4)*8+4)) & 0xF) +
                   chars.charAt((barray[i>>2] >> ((3 - i%4)*8  )) & 0xF)
            i++

        return out

#___________________________________________________________________________________________________ _binb2B64
    @_binb2B64: (barray) ->
        tab = StringUtils.B64_CHARS
        out = ""
        i   = 0
        while i < 4*barray.length
            triplet = (((barray[i   >> 2] >> 8 * (3 -  i   %4)) & 0xFF) << 16) |
                      (((barray[i + 1 >> 2] >> 8 * (3 - (i+1)%4)) & 0xFF) << 8 ) |
                      ((barray[i + 2 >> 2] >> 8 * (3 - (i+2)%4)) & 0xFF)

            for j in [0..3]
                if(8*i + 6*j > 32*barray.length)
                    # The original replacement of an = sign has been replaced with an underscore
                    # in accordance with the change in base 64 character set to make the base 64
                    # characters all web/filesystem safe. See StringUtils for details.
                    # out += '='
                    out += '_'
                else
                    out += tab.charAt((triplet >> 6*(3-j)) & 0x3F)

            i += 3

        return out

#___________________________________________________________________________________________________ _coreHmacSHA256
    @_coreHmacSHA256: (key, data) ->
        cls  = HashUtils
        bkey = cls._str2Binb(key)
        ipad = new Array(16)
        opad = new Array(16)

        for i in [0..15]
            ipad[i] = bkey[i] ^ 0x36363636
            opad[i] = bkey[i] ^ 0x5C5C5C5C

        hash = cls._coreSHA256(ipad.concat(cls._str2Binb(data)), 512 + data.length*cls._CSIZE)
        return cls._coreSHA256(opad.concat(hash), 512 + 256)

#___________________________________________________________________________________________________ _prep
    @_prep: (s) ->
        return if Types.isObject(s) then $(s).val() else s.toString()

#___________________________________________________________________________________________________ _S
    @_S: (X, n) ->
        return ( X >>> n ) | (X << (32 - n))

#___________________________________________________________________________________________________ _R
    @_R: (X, n) ->
        return ( X >>> n )

#___________________________________________________________________________________________________ _sfAdd
    @_sfAdd: (x, y) ->
        lsw = (x & 0xFFFF) + (y & 0xFFFF)
        msw = (x >> 16) + (y >> 16) + (lsw >> 16)
        return (msw << 16) | (lsw & 0xFFFF)

#___________________________________________________________________________________________________ _ch
    @_ch: (x, y, z) ->
        return ((x & y) ^ ((~x) & z))

#___________________________________________________________________________________________________ _maj
    @_maj: (x, y, z) ->
        return ((x & y) ^ (x & z) ^ (y & z))

#___________________________________________________________________________________________________ _sigma0256
    @_sigma0256: (x) ->
        S = HashUtils._S
        return (S(x, 2) ^ S(x, 13) ^ S(x, 22))

#___________________________________________________________________________________________________ _sigma1256
    @_sigma1256: (x) ->
        S = HashUtils._S
        return (S(x, 6) ^ S(x, 11) ^ S(x, 25))

#___________________________________________________________________________________________________ _gamma0256
    @_gamma0256: (x) ->
        cls = HashUtils
        S   = cls._S
        R   = cls._R
        return (S(x, 7) ^ S(x, 18) ^ R(x, 3))

#___________________________________________________________________________________________________ _gamma1256
    @_gamma1256: (x) ->
        cls = HashUtils
        S   = cls._S
        R   = cls._R
        return (S(x, 17) ^ S(x, 19) ^ R(x, 10))
