Config = {}

-----------------------------------[   OPTIONEN   ]-----------------------------------

-------------------[   Debug Printet nützliche Dinge in die Console/F8   ]-------------------
Config.Debug = true 

-------------------[   checkVehicleCommand aktiviert den checkVehicle Command / keyBind aktiviert den KeyBind ( Eins von beiden muss an sein! )   ]-------------------
Config.checkVehicleCommand = true
Config.keyBind             = true

-------------------[   Repair Cost nur am schluss zeigen   ]-------------------
Config.onlyShowRepairCostOnEnd = true 

-------------------[   Timer in Sekunden   ]-------------------
Config.TimerDuration = 300

-------------------[   Mit Peds die einen Verfolgen?   ]-------------------
Config.chaserNPCs = false

-------------------[   Existierende Parts die Schaden erleiden können   ]-------------------
Config.VehicleParts = {
    engine    = 1000,       -- Motor
    body      = 1000,         -- Karosserie
    fuel_tank = 1000,    -- Tank
    windows   = 140,    -- Scheiben
    tyres     = 120,    -- Räder
    doors     = 100,    -- Türen
}

-------------------[   Chat Nachrichten mit der restlichen Zeit   ]-------------------
Config.Timer = {
    { time = 120, message = 'Noch ~h~~g~2 Minuten~w~!' },
    { time = 60, message  = 'Noch ~h~~g~1 Minute~w~!' },
    { time = 30, message  = 'Noch ~h~~g~30 Sekunden~w~!' },
    { time = 10, message  = 'Noch ~h~~g~10 Sekunden~w~!' },
    { time = 5, message   = 'Noch ~h~~g~5 Sekunden~w~!' },
    { time = 4, message   = 'Noch ~h~~g~4 Sekunden~w~!' },
    { time = 3, message   = 'Noch ~h~~r~3 Sekunden~w~!' },
    { time = 2, message   = 'Noch ~h~~r~2 Sekunden~w~!' },
    { time = 1, message   = 'Noch ~h~~r~1 Sekunde~w~!' }
}

-------------------[   Preis pro Schadenspunkt   ]-------------------
Config.DamagePricePerPoint = 8

--Erstmal danke fürs anschauen, ich hoffe dieses Script verbessert diese Challenge!
-- ESC -> INFO -> BENACHRICHTIGUNG ( um die nachrichten zu sehen falls verpasst )
--MfG LeSiiN aka Marvin