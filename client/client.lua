local RSGCore = exports['rsg-core']:GetCoreObject()

----------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------
local npcs = {}
local horse = {}
local spawnbandits = false
local calloffbandits = false
local cooldownSecondsRemaining = 0

----------------------------------------------------------------------------
-- cooldown timer
----------------------------------------------------------------------------
local function cooldownTimer()
    cooldownSecondsRemaining = Config.Cooldown
    Citizen.CreateThread(function()
        while cooldownSecondsRemaining > 0 do
            Wait(1000)
            cooldownSecondsRemaining = cooldownSecondsRemaining - 1
            print(cooldownSecondsRemaining)
        end
    end)
end

----------------------------------------------------------------------------
-- FUNCTION STOP BANDITS
----------------------------------------------------------------------------
local function stopBandits()
    for k, v in pairs(npcs) do
        DeleteEntity(v)
        Wait(500)
    end
    for k, v in pairs(horse) do
        DeleteEntity(v)
        Wait(500)
    end
    calloffbandits = false
    spawnbandits = false
    ClearPedTasks(PlayerPedId())
end

----------------------------------------------------------------------------
-- bandits Trigger
----------------------------------------------------------------------------
local function banditsTrigger(bandits)
    stopBandits()
    spawnbandits = true
    for k, v in pairs(bandits) do
        local horsemodel = GetHashKey(Config.HorseModels[math.random(1, #Config.HorseModels)])
        local banditmodel = GetHashKey(Config.BanditsModel[math.random(1, #Config.BanditsModel)])
        local banditWeapon = Config.Weapons[math.random(1, #Config.Weapons)]

        RequestModel(banditmodel)
        if not HasModelLoaded(banditmodel) then RequestModel(banditmodel) end
        while not HasModelLoaded(banditmodel) do Wait(1) end

        Wait(100)
        -- create bandits
        npcs[k] = CreatePed(banditmodel, v, true, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, npcs[k], true)
        Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, npcs[k])

        -- give weapon to bandits
        GiveWeaponToPed(npcs[k], banditWeapon, 50, true, true, 1, false, 0.5, 1.0, 1.0, true, 0, 0)
        SetCurrentPedWeapon(npcs[k], banditWeapon, true)

        -- create horse sit bandits on horse
        RequestModel(horsemodel)
        if not HasModelLoaded(horsemodel) then RequestModel(horsemodel) end
        while not HasModelLoaded(horsemodel) do Wait(1) end
        Wait(100)
        
        -- create horse
        horse[k] = CreatePed(horsemodel, v, true, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, horse[k], true)
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[k],0x20359E53,true,true,true) --saddle
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[k],0x508B80B9,true,true,true) --blanket
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[k],0xF0C30271,true,true,true) --bag
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[k],0x12F0DF9F,true,true,true) --bedroll
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[k],0x67AF7302,true,true,true) --stirups
        Citizen.InvokeNative(0x028F76B6E78246EB, npcs[k], horse[k], -1)
        
        -- attacker bandits
        TaskCombatPed(npcs[k], PlayerPedId())
    end
end

----------------------------------------------------------------------------
-- Spawn
----------------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        for k, v in pairs(Config.Bandits) do
            local coords = GetEntityCoords(PlayerPedId())
            local coords3 = vector3(v.triggerPoint.x, v.triggerPoint.y, v.triggerPoint.z)
            local dis = #(coords - coords3)
            if dis < Config.TriggerBandits and spawnbandits == false then
                if Config.Debug then
                    print('Trigger bandits')
                end
                banditsTrigger(v.bandits) 
                lib.notify({ title = ('You were ambushed!'), duration = 5000, type = 'inform' })
            end
            if dis >= Config.CalloffBandits and spawnbandits == true then
                calloffbandits = true
            end
        end
    end
end)

----------------------------------------------------------------------------
-- Check for Player Death and Calloff Bandits
----------------------------------------------------------------------------
CreateThread(function()
    npcs = {}
    horse = {}
    while true do
        Wait(1000)
        if IsPedDeadOrDying(PlayerPedId(), true) and spawnbandits == true then
            if Config.Debug then
                print('robbery player')
            end

            TriggerServerEvent('rsg-bandits:server:robplayer')
                
            lib.notify({ title = ('You have been robbed'), duration = 5000, type = 'error' })
            stopBandits()
            cooldownTimer()
            break
        end
        if calloffbandits == true then
            lib.notify({ title = ('looks like you got away'), duration = 5000, type = 'error' })
            stopBandits()
            break
        end
    end
end)

----------------------------------------------------------------------------
-- delete bandits on resouce restart
----------------------------------------------------------------------------
AddEventHandler("onResourceStop",function(resourceName)
    for k, v in pairs(npcs) do
        DeleteEntity(v)
    end
    for k, v in pairs(horse) do
        DeleteEntity(v)
    end
end)
