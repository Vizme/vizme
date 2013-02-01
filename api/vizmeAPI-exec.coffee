# vmi.api.vizmeAPI-exec.coffee
# Vizme, Inc. (C)2011-2012
# Scott Ernst

# import vmi.api.VizmeAPI

###This is the exec file used to compile the VIZME API.###
window.VIZME = new VizmeAPI()
window.VIZME.init(PAGE.requestCode, PAGE.apiArgs, null, PAGE.API_SCRIPT_PATH)
