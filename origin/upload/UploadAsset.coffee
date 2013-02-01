# vmi.origin.upload.UploadAsset.coffee
# Vizme, Inc. (C)2012
# Scott Ernst

# import vmi.util.module.DisplayModule
# require vmi.shared.upload.FileUploader
# require vmi.util.file.SizeUtils
# require vmi.util.time.DataTimer

# ignore FileReader

# Upload asset display module.
class UploadAsset extends DisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module ID
    @ID = 'uploadAsset'

#___________________________________________________________________________________________________ constructor
    constructor: () ->
        super(UploadAsset.ID, "#p-uploadContainer")
        @_files           = []
        @_uploadIndex     = 0
        @_thumbLoaders    = []
        @_uploader        = null
        @_uploadsComplete = false
        @_assetIDs        = []
        @_fails           = 0
        @_successes       = 0
        @_processingTimer = new DataTimer(20000, 1, null, @_handleProcessingCheck)

#===================================================================================================
#                                                                                     P U B L I C

#___________________________________________________________________________________________________ initialize
    initialize: () =>
        if not super()
            return false

        add = VIZME.addEventListener
        add('ups-upload', @_handleBeginUpload)

        $('.p-fileSelector').bind('change', @_handleFileSelect)

        return true

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _uploadFile
    _uploadFile: (index) =>
        if index >= @_files.length
            return false

        @_uploadIndex = index
        fd  = @_files[index]
        dom = fd.dom
        dom.addClass('v-S-bck-m1')
        dom.find('p-fileFooter').show()
        dom.find('.p-uploadMessage').html('Uploading...')
        dom.find('.p-fileProgressBar').progressbar({value:0})

        u      = new FileUploader(fd.file, @_handleUploadComplete, @_handleUploadProgress)
        u.data = fd
        u.upload()
        return true

#___________________________________________________________________________________________________ _showComplete
    _showComplete: () =>
        $('#p-uploadContainer').children().hide()
        if @_successes > 0
            $('.p-uploadCompleteBox').show()
        else
            $('.p-uploadFailBox').show()
        $('.p-filesDisplay').show()

#___________________________________________________________________________________________________ _updateActionDisplay
    _updateActionDisplay: () =>
        if @_files.length == 0
            $('.p-filesDisplay').hide()
            $('.p-actionBox').hide()
            $('.p-selectionBox').show()
        else
            $('.p-filesDisplay').show()
            $('.p-actionBox').show()
            $('.p-selectionBox').hide()

#===================================================================================================
#                                                                                 H A N D L E R S

#___________________________________________________________________________________________________ _handleFileSelect
    _handleFileSelect: (event) =>
        files     = event.target.files # FileList object
        target    = $(event.currentTarget)
        container = $('.p-fileList')

        if not target.hasClass('p-fileAdder')
            @_files        = []
            @_thumbLoaders = []
            container.empty()

        if @_files.length == 0 and files.length == 0
            @_updateActionDisplay()
            return

        for f in files
            fext = f.name.split('.')
            if fext.length == 0
                fext = ''
            else
                fext = ArrayUtils.get(fext, -1).toUpperCase()

            if Types.isEmpty(f.type)
                n = if fext.length > 0 then fext else 'Unknown'
            else
                ftype = f.type.split('/')
                if ftype.length == 1
                    ftype = ftype[0].substr(0,1).toUpperCase() + ftype[0].substr(1)
                else
                    t = ftype[0].substr(0,1).toUpperCase() + ftype[0].substr(1)
                    ftype = ftype[1].toUpperCase() + ' (' + t + ')'

            item = $(PAGE.FILE_DISPLAY_DOM.
                     replace('#NAME#', escape(f.name)).
                     replace('#TYPE#', ftype).
                     replace('#SIZE#', SizeUtils.prettyPrint(f.size, 1)).
                     replace('#BC#', VIZME.exec.styles.getThemeColor(null, 'bck','bck').substr(1)).
                     replace('#FC#', VIZME.exec.styles.getThemeColor(null, 'fcl', 'fcl').substr(1)))
            container.append(item)

            item.find('.p-fileRemove').click(@_handleRemoveItem)

            thumbDOM = item.find('.p-fileThumb')
            thumbDOM.resize((event) ->
                me  = $(event.currentTarget)
                img = me.find('img')
                if img.length == 0
                    return

                scale = Math.min(96 / img.height(), 128 / img.width())
                if scale < 1
                    w = Math.round(scale*img.width())
                    h = Math.round(scale*img.height())
                    img.width(w)
                    img.height(h)
            )

            if f.type.match('image.*')
                thumbDOM.html(DOMUtils.getFillerElement(null, null, thumbDOM))
                reader        = new FileReader()
                reader.onload = @_handleImageLoaded
                @_thumbLoaders.push({fr:reader, dom:thumbDOM})
                reader.readAsDataURL(f)
            else
                url = URLUtils.getImageURL('/mimeThumb/' + encodeURIComponent(ftype + ' ' + fext))
                thumbDOM.html(PAGE.THUMB_DOM.replace('#URL#', url))

            @_files.push({file:f, dom:item})

        @_updateActionDisplay()
        VIZME.render(container)

#___________________________________________________________________________________________________ _handleImageLoaded
    _handleImageLoaded: (event) =>
        reader = event.target
        loader = null
        for tl in @_thumbLoaders
            if reader == tl.fr
                loader = tl
                break

        if Types.isNone(loader)
            return

        ArrayUtils.remove(loader, @_thumbLoaders)
        thumbDOM = loader.dom
        thumbDOM.html("<img src='#{reader.result}' class='p-imageThumb' />")
        thumbDOM.resize()

#___________________________________________________________________________________________________ _handleBeginUpload
    _handleBeginUpload: (event) =>
        $('.p-fileRemove').hide()
        $('.p-actionContainer').hide()
        $('.p-uploadingBox').show()
        $('.p-filesDisplayHeaderBox').hide()
        @_uploadFile(0)

#___________________________________________________________________________________________________ _handleUploadProgress
    _handleUploadProgress: (uploader) =>
        uploader.data.dom.find('.p-fileProgressBar').progressbar('value', uploader.progress())

#___________________________________________________________________________________________________ _handleUploadComplete
    _handleUploadComplete: (uploader) =>
        dom = uploader.data.dom
        dom.removeClass('v-S-bck-m1')
        dom.find('.p-fileProgressBar').hide()
        stat = dom.find('.p-uploadStatus')

        if uploader.success
            stat.find('.p-uploadMessage').html('Upload successful')
            stat.find('.p-checkIcon').show()
            VIZME.render(stat)
            file = uploader.data.file
            args = {uploadKey:uploader.key(), filename:file.name, contentType:file.type}
            VIZME.api('Asset', 'create', args, @_handleAssetCreated, uploader)
        else
            dom.addClass('v-S-bck-m3')
            stat.addClass('v-S-hgh')
            stat.css('font-size', '1.8em')
            stat.html('Upload Failed')
            @_fails++

        # Start next upload
        @_uploadIndex++
        if not @_uploadFile(@_uploadIndex)
            @_uploadsComplete = true

            # If they all fail show the failure complete display
            if @_fails >= @_files.length
                @_showComplete()

#___________________________________________________________________________________________________ _handleAssetCreated
    _handleAssetCreated: (request) =>
        dom = request.localData.data.dom
        if not request.success
            dom.find('p-uploadMessage').html('Invalid or corrupt file. Processing failed.')
            @_fails++

            # If they all fail show the failure complete display
            if @_files.length >= @_fails
                @_showComplete()
            return

        @_assetIDs.push(request.data.id)
        dom.attr('data-uploadid', request.data.id)
        dom.find('.p-procMessage').html('Processing uploaded file for deployment...')
        dom.find('.p-processStatus').show()

        # Begin monitoring processing states
        if not @_processingTimer.running()
            @_processingTimer.start()

#___________________________________________________________________________________________________ _handleProcessingCheck
    _handleProcessingCheck: (dt) =>
        args = {ids:@_assetIDs}
        VIZME.api('Asset', 'processingCheck', args, @_handleProcessingStates)

#___________________________________________________________________________________________________ _handleProcessingStates
    _handleProcessingStates: (request) =>
        if not request.success
            @_processingTimer.restart()
            return

        for n,v of request.data.states
            dom  = $("[data-uploadid=#{n}]")
            stat = dom.find('.p-processStatus')
            msg  = stat.find('.p-procMessage')
            msg.html(v.message)

            if v.error
                msg.addClass('v-S-hgh')
                dom.addClass('v-S-bck-m2')
                stat.find('.p-procLoader').hide()
                ArrayUtils.remove(@_assetIDs, n)
                @_fails++

            if v.complete
                stat.find('.p-procLoader').hide()
                stat.find('.p-checkIcon').show()
                VIZME.render(dom)
                ArrayUtils.remove(@_assetIDs, n)
                @_successes++

        # Handle upload and processing complete
        if @_assetIDs.length == 0 and @_uploadsComplete
            @_showComplete()
            return

        @_processingTimer.restart()

#___________________________________________________________________________________________________ _handleRemoveItem
    _handleRemoveItem: (event) =>
        target = $(event.currentTarget)
        root   = target.parents('.p-file')
        root.remove()
        for f in @_files
            if root[0] == f.dom[0]
                ArrayUtils.remove(@_files, f)
                break

        @_updateActionDisplay()

