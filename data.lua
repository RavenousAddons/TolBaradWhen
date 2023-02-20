local _, ns = ...

ns.data = {
    defaults = {
        sound = true
    },
    timeouts = {
        short = 10,
        long = 60
    },
    toggles = {
        timingWM = false,
        timing = false,
        recentlyOutputWM = false,
        recentlyOutput = false,
        recentlySentStart = false,
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
