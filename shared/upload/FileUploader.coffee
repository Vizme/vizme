# FileUploader.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# require vmi.util.Types

# ignore XMLHttpRequest
# ignore FormData

class FileUploader

#===================================================================================================
#                                                                                       C L A S S

#___________________________________________________________________________________________________ constructor
# Creates an APIManager module instance.
    constructor: (file, completeCallback, progressCallback) ->
        @_file             = file
        @_completeCallback = completeCallback
        @_progressCallback = progressCallback
        @_uploading        = false
        @_progress         = 0
        @data              = null
        @meta              = null
        @success           = false

#===================================================================================================
#                                                                                   G E T / S E T

#___________________________________________________________________________________________________ GS: progress
    progress: () =>
        return @_progress

#___________________________________________________________________________________________________ GS: url
    key: () =>
        return if @meta then @meta.key else null

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ upload
    upload: () =>
        if @_uploading
            return
        @_uploading = true

        VIZME.api(
            'Upload',
            'create',
            {filename:@_file.name, contentType:@_file.type, size:@_file.size},
            @_handleUploadCreated
        )

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _executeUpload
    _executeUpload: () =>
        fd = new FormData()
        fd.append('key', @meta.key)
        fd.append('AWSAccessKeyId', @meta.awsid)
        fd.append('Policy', @meta.policy)
        fd.append('Signature', @meta.sig)
        fd.append('acl', 'private')
        fd.append('success_action_status', '200')
        fd.append('file', @_file)

        xhr = new XMLHttpRequest()
        xhr.upload.addEventListener("progress", @_handleProgress, false)
        xhr.addEventListener("load", @_handleComplete, false)
        xhr.addEventListener("error", @_handleFailed, false)
        xhr.addEventListener("abort", @_handleCanceled, false)

        xhr.open("POST", @meta['url'])
        xhr.send(fd)

#___________________________________________________________________________________________________ _executeProgress
    _executeProgress: () =>
        if Types.isFunction(@_progressCallback)
            @_progressCallback(this, @_progress)

#___________________________________________________________________________________________________ _executeComplete
    _executeComplete: () =>
        @_uploading = false
        if Types.isFunction(@_completeCallback)
            @_completeCallback(this)

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleUploadCreated
    _handleUploadCreated: (request) =>
        if not request.success
            @_executeComplete()
            return
        @meta = request.data
        @_executeUpload()

#___________________________________________________________________________________________________ _handleProgress
    _handleProgress: (event) =>
        @_progress = Math.round(100*event.loaded / event.total)
        @_executeProgress()

#___________________________________________________________________________________________________ _handleComplete
    _handleComplete: (event) =>
        xhr     = event.currentTarget
        success = xhr.status == 200
        if success
            @_progress = 100
            @success   = true
            @_executeProgress()

        @_executeComplete()

#___________________________________________________________________________________________________ _handleFailed
    _handleFailed: (event) =>
        @_executeComplete()

#___________________________________________________________________________________________________ _handleCanceled
    _handleCanceled: (event) =>
        @_executeComplete()
