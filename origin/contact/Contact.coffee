# vmi.origin.contact.Contact.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.SubmissionDisplayModule
# import vmi.util.url.URLUtils

# Submits a contact request module.
class Contact extends SubmissionDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'contact'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(Contact.ID, '#contact-container', 'Support', 'contact', '#contact-box',
              '#contact-submit', '#contact-success-box', '#contact-complete')

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _showComplete
    _showComplete: () =>
        window.close()
        window.location = URLUtils.getURL(null, true)