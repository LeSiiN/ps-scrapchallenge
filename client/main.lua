-- ---------------------------------[   VARIABLEN   ]-----------------------------------
local timerActive      = false
local allowPedSpawning = false
local repairDamage     = {}
local savedRepairCost  = 0
local activeNPCs       = {} -- Liste der aktiven NPC-Peds
local activeVehicles   = {} -- Liste der aktiven NPC-Fahrzeuge
local npcBlips         = {} -- Tabelle für Blips der NPCs

-----------------------------------[   NOTIFICATION   ]-----------------------------------
RegisterNetEvent('ps-scrapchallenge:client:showCostNotify', function(message, sender, subject, textureDict, iconType, saveToBrief, color)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    ThefeedSetNextPostBackgroundColor(color)
    EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
    EndTextCommandThefeedPostTicker(false, saveToBrief)
end)

RegisterNetEvent('ps-scrapchallenge:client:showNotify', function(message, color, flash, saveToBrief)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    ThefeedSetNextPostBackgroundColor(color)
    EndTextCommandThefeedPostTicker(false, saveToBrief)
end)
-----------------------------------[   FUNCTIONS   ]-----------------------------------
local function Debug(message)
    if Config.Debug then
        print(" ^4[DEBUG]: " .. message .. "^1")
        print("^4-----------------------------------------------------------------------------------------------^1")
    end
end

local function fixVehicle(veh)
    SetVehicleFixed(veh)
    ResetVehicleWheels(veh, true)

    SetVehicleFuelLevel(veh, 100.0)
    DecorSetFloat(veh, '_FUEL_LEVEL', GetVehicleFuelLevel(veh))

    SetVehicleUndriveable(veh, false)
    SetVehicleEngineOn(veh, true, true, true)
end

local function loadModel(model)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    if not HasModelLoaded(model) then
        Debug("Fehler: Modell " .. model .. " konnte nicht geladen werden.")
        return false
    end
    return true
end

local function spawnNPC()
    local pedModel       = nil
    local spawnLocation  = GetEntityCoords(PlayerPedId()) + vector3(math.random(-20, -10), math.random(-10, 10), 0) -- Spawn in der Nähe des Spielers
    local chaserVehicles = {"baller", "adder", "sultan", "serrano", "gburrito", "kuruma", "patriot", "oracle2", "contender", "banshee", "exemplar", "f620", "trophytruck", "comet2"}
    local chaserVehicle  = chaserVehicles[math.random(1, #chaserVehicles)]  -- Zufälliges Fahrzeug aus der Liste auswählen

    local chaserPeds     = {"a_m_m_hillbilly_01", "s_m_y_cop_01", "a_m_m_business_01", "s_m_m_paramedic_01", "a_m_m_eastsa_01",  "s_f_y_ranger_01",  "s_m_y_sheriff_01", "a_m_m_farmer_01", "u_m_m_doa_01", "s_m_m_highsec_01", "a_m_m_tramp_01",  "s_m_y_dealer_01", "u_m_m_jesus_01"}
    local pedModel       = chaserPeds[math.random(1, #chaserPeds)]  -- Zufälliges pedModel aus der Liste auswählen

    -- Lade NPC- und Fahrzeugmodelle
    if not loadModel(pedModel) or not loadModel(chaserVehicle) then
        return
    end

    -- Überprüfen, ob der Spawnbereich frei ist
    if not IsPositionOccupied(spawnLocation.x, spawnLocation.y, spawnLocation.z, 5.0, false, true, false, false, false, 0, false) then
        npcVeh = CreateVehicle(chaserVehicle, spawnLocation.x, spawnLocation.y, spawnLocation.z, GetEntityHeading(PlayerPedId()), true, false)
        local netid = NetworkGetNetworkIdFromEntity(npcVeh)
        SetNetworkIdCanMigrate(netid, true)
        SetVehicleEngineOn(npcVeh, true, true, true)
        Wait(100)

        -- Erstelle NPC
        local npc = CreatePed(4, pedModel, spawnLocation.x, spawnLocation.y, spawnLocation.z, math.random(0, 360), true, true)

        if npc then
            -- Blip für den NPC erstellen
            local blip = AddBlipForEntity(npc)
            SetBlipSprite(blip, 1) -- Symboltyp (1 = Spieler, passe an deine Bedürfnisse an)
            SetBlipColour(blip, 1) -- Blip-Farbe (1 = Rot, passe nach Belieben an)
            SetBlipScale(blip, 0.8) -- Größe des Blips
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Verfolger") -- Name des Blips
            EndTextCommandSetBlipName(blip)

            -- Blip zur Tabelle hinzufügen
            npcBlips[npc] = blip
            
            Debug("NPC erfolgreich gespawnt bei " .. tostring(spawnLocation))
            SetPedIntoVehicle(npc, npcVeh, -1)  -- Der Fahrer ist an Position 0 (erste Position)

            -- NPC-Verhalten einstellen
            TaskCombatPed(npc, PlayerPedId(), 0, 16)
            SetPedRelationshipGroupHash(npc, GetHashKey("ENEMY"))
            SetVehicleEnginePowerMultiplier(npcVeh, 50.0)
            SetPedFleeAttributes(npc, 0, false)
            SetPedCombatAttributes(npc, 46, true)
            SetPedCombatAbility(npc, 100)
            SetPedCombatMovement(npc, 2)
            SetPedCombatRange(npc, 20)
            GiveWeaponToPed(npc, GetHashKey("WEAPON_PISTOL"), 250, false, true)
            SetPedKeepTask(npc, true)
            SetPedAsCop(npc, true)
            SetPedCanSwitchWeapon(npc, true)
            TaskVehicleDriveWander(npc, npcVeh, 60.0, 524860)
            TaskVehicleChase(npc, PlayerPedId())

            -- Füge NPC und Fahrzeug zur globalen Liste hinzu
            table.insert(activeNPCs, npc)
            table.insert(activeVehicles, npcVeh)

            TriggerEvent('ps-scrapchallenge:client:showNotify', "~r~Ein Verfolger wurde auf dich angesetzt!", 140, true, true)
        else
            Debug("Fehler: NPC konnte nicht erstellt werden.")
        end
    end

end

local function despawnAllNPCs()
    for _, npc in ipairs(activeNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    for _, chaserVehicle in ipairs(activeVehicles) do
        if DoesEntityExist(chaserVehicle) then
            DeleteEntity(chaserVehicle)
        end
    end

    for i, npc in ipairs(activeNPCs) do
        if DoesEntityExist(npc) then
            -- Blip entfernen
            if npcBlips[npc] then
                RemoveBlip(npcBlips[npc])
                npcBlips[npc] = nil
            end
    
            -- NPC löschen
            SetEntityAsNoLongerNeeded(npc)
            DeleteEntity(npc)
            activeNPCs[i] = nil
            Debug("NPC gelöscht: " .. tostring(npc))
        end
    end

    -- Listen zurücksetzen
    activeNPCs     = {}
    activeVehicles = {}
end

--- Überprüft das Fahrzeug und berechnet die Reparaturkosten.
local function checkVehicle(endOfChallenge)
    endOfChallenge = endOfChallenge or false

    Debug("checkVehicle aufgerufen, endOfChallenge: " .. tostring(endOfChallenge))
    
    if not timerActive and not endOfChallenge then
        Debug("Kein aktiver Timer")
        PlaySoundFrontend(-1, "ERROR", "HUD_AMMO_SHOP_SOUNDSET", true)
        TriggerEvent('ps-scrapchallenge:client:showNotify',
            '~r~Kein aktiver Timer! ~n~Chill mal du Snob. . .',
            140,
            true,
            true
        )
        return
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    Debug("Fahrzeug ID: " .. tostring(vehicle))

    if vehicle == 0 then
        Debug("Spieler ist nicht in einem Fahrzeug, es wird der letzte gespeicherte Preis angezeigt")
        TriggerEvent('ps-scrapchallenge:client:showCostNotify', 
            "Die Reparaturkosten vom letzten Fahrzeug betragen: ~h~~g~" .. savedRepairCost .. '~w~€',
            "~g~ ~h~Reparaturkosten",
            nil,
            "CHAR_LS_CUSTOMS",
            9,
            true,
            140
        )
        return
    end

    -- Fahrzeugzustand speichern
    repairDamage = {
        engine    = GetVehicleEngineHealth(vehicle),
        body      = GetVehicleBodyHealth(vehicle),
        fuel_tank = GetVehiclePetrolTankHealth(vehicle),
        windows   = 140,
        tyres     = 120,
        doors     = 100,
    }

    local tyreIndexes = {0, 1, 2, 3, 4, 5, 45, 47}

    -- Überprüfe Reifen
    for _, i in pairs(tyreIndexes) do
        local tyreBurst = IsVehicleTyreBurst(vehicle, i, false) == 1
    
        if tyreBurst then
            Debug("Tyres: Index " .. i .. ", Max Damage: " .. repairDamage.tyres .. ", Nach Abzug: " .. (repairDamage.tyres - 20))
            repairDamage.tyres = repairDamage.tyres - 20
        end
    end
    
    -- Überprüfe Fenster
    for i = 0, 7 do
        local windowStatus = IsVehicleWindowIntact(vehicle, i)
    
        if not windowStatus then
            Debug("Windows: Index " .. i .. ", Max Damage: " .. repairDamage.windows .. ", Nach Abzug: " .. (repairDamage.windows - 20))
            repairDamage.windows = repairDamage.windows - 20
        end
    end
    
    -- Überprüfe Türen
    for i = 0, 5 do
        local doorDamaged = IsVehicleDoorDamaged(vehicle, i)
    
        if doorDamaged then
            Debug("Doors: Index " .. i .. ", Max Damage: " .. repairDamage.doors .. ", Nach Abzug: " .. (repairDamage.doors - 20))
            repairDamage.doors = repairDamage.doors - 20
        end
    end

    Debug("Fahrzeugzustand gesammelt:")
    Debug("Engine: "    .. repairDamage.engine)
    Debug("Body: "      .. repairDamage.body)
    Debug("Fuel Tank: " .. repairDamage.fuel_tank)

    -- Reparaturkosten berechnen
    TriggerServerEvent('ps-scrapchallenge:server:calculateRepairCost', repairDamage)
end

-----------------------------------[   COMMANDS/KEYMAPPING   ]-----------------------------------
if Config.checkVehicleCommand and not Config.onlyShowRepairCostOnEnd then
    RegisterCommand('checkvehicle', function()
        Debug("Befehl 'checkvehicle' aufgerufen")
        checkVehicle()
    end, false)
end

RegisterCommand('settimer', function(source, args)
    local newDuration = tonumber(args[1])
    if newDuration then
        Config.TimerDuration = newDuration
        TriggerEvent('ps-scrapchallenge:client:showNotify',
            'Timer auf ~g~' ..newDuration.. " Sekunden ~w~gestellt.",
            140,
            true,
            true
        )
    end
end)

RegisterCommand('checktimer', function(source, args)
    TriggerEvent('ps-scrapchallenge:client:showNotify',
        'Timer ist auf ~g~' ..Config.TimerDuration.. " Sekunden ~w~eingestellt.",
        140,
        true,
        true
    )
end)

if Config.keyBind then
    Debug("Keymapping für 'checkVehicle' registriert")
    RegisterKeyMapping('checkVehicle', 'Überprüfe Kosten zum Reparieren ', 'keyboard', 'j')
end

-----------------------------------[   CLIENT EVENTS   ]-----------------------------------

--- Startet den Timer und gibt Countdown- und Timer-Nachrichten aus.
RegisterNetEvent('ps-scrapchallenge:client:startTimer', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    Debug("Event 'startTimer' empfangen")

    if timerActive then 
        Debug("Timer läuft bereits")
        PlaySoundFrontend(-1, "ERROR", "HUD_AMMO_SHOP_SOUNDSET", true)
        TriggerEvent('ps-scrapchallenge:client:showNotify',
            '~r~Der Timer läuft bereits!',
            140,
            true,
            true
        )
        return
    end

    timerActive = true
    FreezeEntityPosition(vehicle, true)
    Debug("Fahrzeug wurde gefreezt.")
    -- Countdown von 3 bis 1
    for i = 5, 1, -1 do
        if not timerActive then return end
        PlaySoundFrontend(-1, '3_2_1', 'HUD_MINI_GAME_SOUNDSET', true)
        TriggerEvent('ps-scrapchallenge:client:showNotify',
            'Der Timer startet in ~n~ ~h~~g~' .. i .. ' Sekunden~w~.',
            140,
            true,
            true
        )
        Wait(1000) -- eine Sekunde warten
    end

    allowPedSpawning = true

    -- Timer gestartet
    if timerActive then
        fixVehicle(vehicle)
        FreezeEntityPosition(vehicle, false)
        PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
        Debug("Timer gestartet mit Dauer: " .. Config.TimerDuration .. " Sekunden und Fahrzeug wurde unfreezt und gefixt.")
        TriggerEvent('ps-scrapchallenge:client:showNotify',
            'Der Timer wurde gestartet! ~n~Du hast ~h~~g~' .. Config.TimerDuration .. ' Sekunden~w~.',
            140,
            true,
            true
        )
    end

    -- Timer-Thread
    CreateThread(function()
        local remainingTime = Config.TimerDuration
    
        while remainingTime > 0 and timerActive do
            Wait(1000)
            remainingTime = remainingTime - 1
    
            -- Timer-Meldungen anzeigen
            for _, timer in ipairs(Config.Timer) do
                if remainingTime == timer.time then
                    Debug("Timer-Meldung: " .. timer.message)
                    TriggerEvent('ps-scrapchallenge:client:showNotify',
                        timer.message,
                        140,
                        true,
                        true
                    )
                    if not Config.onlyShowRepairCostOnEnd then
                        if remainingTime >= 10 then
                            Wait(500)
                            checkVehicle()
                        end
                    end
                end
            end
    
            -- Sound für die letzten 5 Sekunden
            if remainingTime <= 5 and remainingTime > 0 then
                PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
            end
        end
    
        if remainingTime == 0 then
            timerActive = false
            allowPedSpawning = false
            Debug("Timer abgelaufen")
    
            -- Nachricht anzeigen
            TriggerEvent('ps-scrapchallenge:client:showNotify',
                '~h~~r~Der Timer ist abgelaufen!',
                140,
                true,
                true
            )
    
            -- Sound abspielen, wenn Timer 0 erreicht
            PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
    
            -- Reparaturkosten berechnen
            Debug("Reparaturkosten nach Ablauf des Timers berechnen")
            checkVehicle(true)
            despawnAllNPCs()
        end
    end)    
end)

--- Stoppt den Timer und gibt eine Nachricht aus.
RegisterNetEvent('ps-scrapchallenge:client:stopTimer', function()
    Debug("Event 'stopTimer' empfangen")

    if not timerActive then
        Debug("Kein aktiver Timer beim Stoppen")
        PlaySoundFrontend(-1, "ERROR", "HUD_AMMO_SHOP_SOUNDSET", true)
        TriggerEvent('ps-scrapchallenge:client:showNotify',
            '~r~Kein aktiver Timer! ~n~Chill mal du Snob. . .',
            140,
            true,
            true
        )
        return
    end

    timerActive      = false
    allowPedSpawning = false
    Debug("Timer wurde gestoppt")
    TriggerEvent('ps-scrapchallenge:client:showNotify',
        '~r~Timer wurde gestoppt!',
        140,
        true,
        true
    )
    despawnAllNPCs()
end)

--- Zeigt die Reparaturkosten an.
RegisterNetEvent('ps-scrapchallenge:client:showRepairCost', function(repairCost)
    savedRepairCost = repairCost
    Debug("Reparaturkosten erhalten: " .. repairCost)
    TriggerEvent('ps-scrapchallenge:client:showCostNotify', 
        "Die Reparaturkosten betragen: ~h~~g~" .. repairCost .. '~w~€',
        "~h~Reparaturkosten",
        nil,
        "CHAR_LS_CUSTOMS",
        9,
        true,
        140
    )
end)

--Chat Thread für leichtere nutzung der Commands
CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/checkvehicle', 'Überprüfe die aktuellen Reparaturkosten')

    TriggerEvent('chat:addSuggestion', '/starttimer', 'Starte Scrap Challenge')

    TriggerEvent('chat:addSuggestion', '/stoptimer', 'Stoppe Aktuelle Scrap Challenge')

    TriggerEvent('chat:addSuggestion', '/checktimer', 'Überprüfe den aktuell eingestellten Timer')

    TriggerEvent('chat:addSuggestion', '/info', 'Zeigt alle nötigen Informationen an')

    TriggerEvent('chat:addSuggestion', '/settimer', 'Ändere die Scrap Challenge Zeit', {
        { name = 'Zeit', help = 'Länge der Challenge ( In Sekunden! )' }
    })
end)

if Config.chaserNPCs then
    CreateThread(function()
        while true do
            Wait(1000)
    
            if allowPedSpawning then
                Debug("Angriffs-Thread gestartet, da allowPedSpawning aktiv ist.")
    
                while allowPedSpawning do
                    Wait(math.random(30000,60000)) -- Angriffswelle alle 30-60 Sekunden
                    if not allowPedSpawning then Debug("Wollte NPC spawnen, wurde jedoch abgebrochen.") return end
                    spawnNPC()
                end
            end
        end
    end)
end

CreateThread(function()
    while true do
        Wait(1000) -- Alle 1 Sekunde aktualisieren
        for npc, blip in pairs(npcBlips) do
            if DoesEntityExist(npc) then
                if IsPedDeadOrDying(npc, true) then
                    -- Blip entfernen, wenn NPC stirbt
                    Debug("NPC gestorben, Blip wird entfernt: " .. tostring(npc))
                    RemoveBlip(blip)
                    npcBlips[npc] = nil

                    -- NPC entfernen
                    SetEntityAsNoLongerNeeded(npc)
                else
                    -- Blip-Position auf NPC aktualisieren
                    local npcCoords = GetEntityCoords(npc)
                    SetBlipCoords(blip, npcCoords.x, npcCoords.y, npcCoords.z)
                end
            else
                -- Blip entfernen, wenn NPC nicht mehr existiert
                Debug("NPC existiert nicht mehr, Blip wird entfernt.")
                RemoveBlip(blip)
                npcBlips[npc] = nil
            end
        end
    end
end)

-- AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(source), function(_, _, value)
--     if value then
--         Debug(GetPlayerName(source) " gejoint, spiele Info ab!")
--         ExecuteCommand("info")
--     end
-- end)