# vmi.origin.feedback.Feedback.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.util.module.SubmissionDisplayModule
# import vmi.util.url.URLUtils

# Submits a contact request module.
class Feedback extends SubmissionDisplayModule

#===================================================================================================
#                                                                                       C L A S S

    # Module identifier
    @ID = 'feedback'

#___________________________________________________________________________________________________ constructor
# Creates a new Login module instance.
    constructor: () ->
        super(Feedback.ID, '#feedback-container', 'Support', 'feedback', '#feedback-box',
              '#fdbk-submit', '#fdbk-success-box', '#fdbk-complete')

#===================================================================================================
#                                                                               P R O T E C T E D

#___________________________________________________________________________________________________ _showComplete
    _showComplete: () =>
        window.close()
        window.location = URLUtils.getURL(null, true)