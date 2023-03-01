local _, ns = ...

ns.data = {
    defaults = {
        sound = true,
        raidwarning = true,
        debug = false,
        alertStart =  true,
        alert1Minute =  false,
        alert2Minutes =  true,
        alert10Minutes =  true,
    },
    timeouts = {
        short = 10,
        long = 60,
    },
    toggles = {
        timingWM = false,
        timing = false,
        recentlyOutputWM = false,
        recentlyOutput = false,
        recentlySentStart = false,
        recentlyReceivedStartWM = false,
        recentlyReceivedStart = false,
        recentlyEnded = false,
        updateFound = false,
    },
    mapIDs = {
        244,
        245
    },
    location = C_Map.GetBestMapForUnit("player"),
    partyMembers = 0,
    raidMembers = 0,
}
