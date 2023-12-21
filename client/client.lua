local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnbandits = false
local calloffbandits = false
local cooldownSecondsRemaining = 0
local npcs = {}
local horse = {}
local isLoggedIn = false

----------------------------------------------------------------------------
-- On Player Loaded
----------------------------------------------------------------------------
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
end)

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
-- bandits Trigger
----------------------------------------------------------------------------
local function banditsTrigger(bandits)
    spawnbandits = true
    for v,k in pairs(bandits) do
        local horsemodel = GetHashKey(Config.HorseModels[math.random(1,#Config.HorseModels)])
        local banditmodel = GetHashKey(Config.BanditsModel[math.random(1,#Config.BanditsModel)])
        local banditWeapon = Config.Weapons[math.random(1,#Config.Weapons)]
        RequestModel(banditmodel)
        if not HasModelLoaded(banditmodel) then RequestModel(banditmodel) end
        while not HasModelLoaded(banditmodel) do Wait(1) end
        Wait(100)
        -- create bandits
        npcs[v] = CreatePed(banditmodel, k, true, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, npcs[v], true)
        Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, npcs[v])
        -- give weapon to bandits
        GiveWeaponToPed(npcs[v], banditWeapon, 50, true, true, 1, false, 0.5, 1.0, 1.0, true, 0, 0)
        SetCurrentPedWeapon(npcs[v], banditWeapon, true)
        -- create horse sit bandits on horse
        RequestModel(horsemodel)
        if not HasModelLoaded(horsemodel) then RequestModel(horsemodel) end
        while not HasModelLoaded(horsemodel) do Wait(1) end
        Wait(100)
        horse[v] = CreatePed(horsemodel, k, true, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, horse[v], true)
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[v],0x20359E53,true,true,true) --saddle
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[v],0x508B80B9,true,true,true) --blanket
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[v],0xF0C30271,true,true,true) --bag
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[v],0x12F0DF9F,true,true,true) --bedroll
        Citizen.InvokeNative(0xD3A7B003ED343FD9, horse[v],0x67AF7302,true,true,true) --stirups
        Citizen.InvokeNative(0x028F76B6E78246EB, npcs[v], horse[v], -1)
        TaskCombatPed(npcs[v], PlayerPedId())
    end
end

----------------------------------------------------------------------------
-- Spawn
----------------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        for v,k in pairs(Config.Bandits) do
            local coords = GetEntityCoords(PlayerPedId())
            local coords3 = vector3(k.triggerPoint.x, k.triggerPoint.y, k.triggerPoint.z)
            local dis = #(coords - coords3)
            if dis < Config.TriggerBandits and not spawnbandits then
                --print('trigger bandits')
                banditsTrigger(k.bandits)
            end
            if dis >= Config.CalloffBandits and spawnbandits then
                --print('call off bandits')
                calloffbandits = true
            end
        end
    end
end)

CreateThread(function()
    npcs = {}
    horse = {}
    while true do
        Wait(1000)
        if IsPedDeadOrDying(PlayerPedId(), true) and spawnbandits then
            lib.notify({ title = ('looks like they got you'), duration = 5000, type = 'error' })
            Wait(5000)
            TriggerServerEvent('rsg-bandits:server:robplayer')
            lib.notify({ title = ('and you have been robbed'), duration = 5000, type = 'error' })
            for v,k in pairs(npcs) do
                DeleteEntity(k)
            end
            for v,k in pairs(horse) do
                DeleteEntity(k)
            end
            calloffbandits = false
            spawnbandits = false
            break
        end
        if calloffbandits then
            for v,k in pairs(npcs) do
                DeleteEntity(k)
            end
            for v,k in pairs(horse) do
                DeleteEntity(k)
            end
            calloffbandits = false
            spawnbandits = false
            lib.notify({ title = ('looks like you got away'), duration = 5000, type = 'error' })
            break
        end
    end
end)

----------------------------------------------------------------------------
-- delete bandits on resouce restart
----------------------------------------------------------------------------
AddEventHandler("onResourceStop",function(resourceName)
    for v,k in pairs(npcs) do
        DeleteEntity(k)
    end
    for v,k in pairs(horse) do
        DeleteEntity(k)
    end
end)
