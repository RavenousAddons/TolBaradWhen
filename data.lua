local _, ns = ...

ns.data = {
    defaults = {
        alertStart =  true,
        alert1Minute =  false,
        alert2Minutes =  true,
        alert5Minutes =  true,
        alert10Minutes =  true,
        alertCustomMinutes = 1,
        printText = true,
        sound = true,
        raidwarning = true,
        printWinsOnEnd = true,
        share = true,
        allowDebug = false,
        debug = false,
        timeFormat = 3,
        toggles = {},
        startTimestampWM = 0,
        startTimestamp = 0,
        controlWM = "alliance",
        control = "alliance",
    },
    characterDefaults = {
        gamesWM = 0,
        games = 0,
        winsWM = 0,
        wins = 0,
    },
    timers = {
        alert1Minute = 1,
        alert2Minutes = 2,
        alert5Minutes = 5,
        alert10Minutes = 10,
    },
    timeouts = {
        short = 10,
        medium = 20,
        long = 60,
    },
    toggles = {
        timerActiveWM = false,
        timerActive = false,
        recentlyOutputWM = false,
        recentlyOutput = false,
        recentlyReceivedStartWM = false,
        recentlyReceivedStart = false,
        recentlyRequestedStart = false,
        recentlySentStart = false,
        recentlyAnnouncedStart = false,
        recentlySentVersion = false,
        recentlyEnded = false,
        updateFound = false,
    },
    sounds = {
        present = 567399, -- alarmclockwarning2.ogg
        future = 567458, -- alarmclockwarning3.ogg
    },
    mapIDs = {
        main = 244, -- Tol Barad
        peninsula = 245, -- Tol Barad Peninsula
    },
    widgets = {
        active = {
            control = 701,
            timer = 682,
        },
        inactive = {
            control = 687,
            timer = 688,
        },
    },
    classColors = {
        deathknight = "c41e3a",
        demonhunter = "a330c9",
        druid = "ff7c0a",
        evoker = "33937f",
        hunter = "aad372",
        mage = "3fc7eb",
        monk = "00ff98",
        paladin = "f48cba",
        priest = "ffffff",
        rogue = "fff468",
        shaman = "0070dd",
        warlock = "8788ee",
        warrior = "c69b6d",
    },
    location = C_Map.GetBestMapForUnit("player"),
    partyMembers = 0,
    raidMembers = 0,
}
