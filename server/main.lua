-----------------------------------[   FUNCTIONS   ]-----------------------------------
local function Debug(message)
    if Config.Debug then
        print(" ^4[DEBUG]: " .. message .. "^1")
        print("^4-----------------------------------------------------------------------------------------------^1")
    end
end

-----------------------------------[   COMMANDS   ]-----------------------------------
RegisterCommand('info', function(source, args)
    local nachrichten = {
        {text = "~h~Willkommen, ~n~im folgenden erhaltet ihr alle nötigen Infos:", title = "~h~~g~Scrap Challenge", subtitle = "📣     ~g~Informationen", char = "CHAR_GANGAPP"},
        {text = '~g~ESC ➡️ Infos ➡️ Benachrichtigung'},
        {text = '~g~/checkvehicle ~h~~w~(Überprüfe die aktuellen Reparaturkosten)'},
        {text = '~g~/starttimer ~h~~w~(Starte Scrap Challenge)'},
        {text = '~g~/stoptimer ~h~~w~(Stoppe Aktuelle Scrap Challenge)'},
        {text = '~g~/checktimer ~h~~w~(Überprüfe den aktuell eingestellten Timer)'},
        {text = '~g~/info ~h~~w~(Zeigt alle nötigen Informationen an)'},
        {text = '~g~/settimer ~o~[Zeit in Sekunden] ~h~~w~(Ändere die Scrap Challenge Zeit)'},
        {text = '~h~~r~Script erstellt von LeSiiN mit ❤️'}
    }
    
    -- Erste Benachrichtigung mit zusätzlicher Anzeige
    local startNachricht = nachrichten[1]
    TriggerClientEvent('ps-scrapchallenge:client:showCostNotify', source,
        startNachricht.text,
        startNachricht.title,
        startNachricht.subtitle,
        startNachricht.char,
        1,
        true,
        140
    )
    
    -- Wartezeit nach der ersten Benachrichtigung
    Wait(1000)
    
    -- Weitere Benachrichtigungen
    for i = 2, #nachrichten do
        local notify = nachrichten[i]
        TriggerClientEvent('ps-scrapchallenge:client:showNotify', source, notify.text, 140, true, true)
        Wait(1000) -- Wartezeit zwischen den Benachrichtigungen
    end
end)

RegisterCommand('starttimer', function(source, args)
    -- Startet den Timer für den Client
    TriggerClientEvent('ps-scrapchallenge:client:startTimer', source)
end)

RegisterCommand('stoptimer', function(source, args)
    -- Stoppt den Timer für den Client
    TriggerClientEvent('ps-scrapchallenge:client:stopTimer', source)
end)

-----------------------------------[   SERVER EVENTS   ]-----------------------------------
RegisterServerEvent('ps-scrapchallenge:server:calculateRepairCost', function(damageValues)
    local totalDamage = 0
    local repairCost  = 0
    local finalCost

    if type(damageValues) ~= "table" then
        Debug("Fehler: Ungültige Schadenswerte erhalten.")
        return
    end

    Debug("Reparaturkostenberechnung gestartet für Spieler " .. GetPlayerName(source) .. ".")

    -- Berechnet den Schaden und den Reparaturpreis
    for part, damage in pairs(damageValues) do
        -- Maximale Gesundheit des Fahrzeugteils abrufen, falls nicht definiert, ist sie 1000
        local maxHealth = Config.VehicleParts[part] or 1000
        
        -- Berechnet den Schaden für jedes Teil
        local damageAmount = maxHealth - damage
        totalDamage        = totalDamage + damageAmount

        -- Debugging-Ausgabe für jedes Fahrzeugteil
        Debug("Teil: "..part.." | Max Health: "..maxHealth.." | Schaden: "..damageAmount.." | Kumulativer Schaden: "..totalDamage)
    end

    -- Berechnet den Reparaturpreis (Schaden * Preis pro Punkt)
    repairCost = totalDamage * Config.DamagePricePerPoint

    -- Setzt repairCost auf 2 Nachkommastellen
    finalCost = tonumber(string.format("%.2f", repairCost))

    -- Debugging-Ausgabe für den Gesamtpreis
    Debug("Gesamtschaden: "..totalDamage.." | Preis pro Schadenspunkt: "..Config.DamagePricePerPoint.." | Endgültige Reparaturkosten: "..finalCost.. "€")

    -- Sendet die berechneten Reparaturkosten an den Client
    TriggerClientEvent('ps-scrapchallenge:client:showRepairCost', source, finalCost)
    Debug("Reparaturkosten wurden an Spieler " .. GetPlayerName(source) .. " gesendet: " .. finalCost.. "€")
end)