local _, ns = ...

ns.data = {
    defaults = {
        share = true,
        sound = true,
        raidwarning = true,
        debug = false,
        alertStart =  true,
        alert1Minute =  false,
        alert2Minutes =  true,
        alert5Minutes =  true,
        alert10Minutes =  true,
        alertCustomMinutes = 1,
        stopwatch = false,
    },
    timers = {
        alert1Minute = 1,
        alert2Minutes = 2,
        alert5Minutes = 5,
        alert10Minutes = 10,
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
        recentlyReceivedStartWM = false,
        recentlyReceivedStart = false,
        recentlyRequestedStart = false,
        recentlySentStart = false,
        recentlyAnnouncedStart = false,
        recentlyEnded = false,
        updateFound = false,
        stopwatch = false,
    },
    mapIDs = {
        244,
        245
    },
    location = C_Map.GetBestMapForUnit("player"),
    partyMembers = 0,
    raidMembers = 0,
}
