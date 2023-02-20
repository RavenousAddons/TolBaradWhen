local _, ns = ...

ns.data = {
    defaults = {
        sound = true
    },
    location = C_Map.GetBestMapForUnit("player"),
    toggles = {
        timingWM = false,
        timing = false,
        recentlyOutputWM = false,
        recentlyOutput = false,
        recentlySentStart = false,
        recentlyReceivedStart = false,
        recentlyEnded = false
    },
    mapIDs = {
        244,
        245
    }
}
