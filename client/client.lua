local RSGCore = exports['rsg-core']:GetCoreObject()

----------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------
local npcs = {}
local horse = {}
local spawnbandits = false
local attackbandits = false
local calloffbandits = false
local cooldownSecondsRemaining = 0
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
    CreateThread(function()
        while cooldownSecondsRemaining > 0 do
            Wait(1000)
            cooldownSecondsRemaining = cooldownSecondsRemaining - 1
            if Config.Debug then
                print(cooldownSecondsRemaining)
            end
        end
    end)
end

----------------------------------------------------------------------------
-- Promp Hands Up
----------------------------------------------------------------------------
local function HandsUp()
CreateThread(
    function()
        local str = 'HandsUp'
        local wait = 0
        local HandsUpPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(HandsUpPrompt, RSGCore.Shared.Keybinds['X'])
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(HandsUpPrompt, str)
        PromptSetEnabled(HandsUpPrompt, true)
        PromptSetVisible(HandsUpPrompt, true)
        PromptSetHoldMode(HandsUpPrompt, true)
        PromptRegisterEnd(HandsUpPrompt)
    end)
end

-------------------------
-- FUNCTION STOP BANDITS
-------------------------
local function stopBandits()
	-- Wait(30000) -- 30 s for looting
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
    cooldownTimer()
    PromptDelete(HandsUpPrompt)
end

----------------------------------------------------------------------------
-- approach player And Rob
----------------------------------------------------------------------------

local function approachAndRob(playerPed, banditPed)
    local banditCoords = GetEntityCoords(banditPed)
    local playerCoords = GetEntityCoords(playerPed)

    -- Determine the direction from the bandit to the player
    local heading = GetEntityHeading(banditPed)
    local x, y, z = 0.0, 0.0, 0.0
    x = math.sin(math.rad(heading))
    y = math.cos(math.rad(heading))

    -- Calculate the position where the bandit should move towards the player
    local destination = vector3(playerCoords.x + x, playerCoords.y + y, playerCoords.z)

    -- Move the bandit towards the player
    TaskGoToCoordAnyMeans(banditPed, destination.x, destination.y, destination.z, 5.0, 0, 0, 786603, 0xbf800000)

    TriggerServerEvent('rsg-bandits:server:robplayer')
end

----------------------------------------------------------------------------
-- Function to check if the player raises their hands
----------------------------------------------------------------------------
local function checkHandsUp(playerPed, banditPed)
    local handsUpPromptActive = false

    -- Function to handle hands up prompt
    local function handsUpPromptHandler()
        handsUpPromptActive = true
        HandsUp()
        while handsUpPromptActive do
            Wait(0)
            if IsControlJustReleased(0, RSGCore.Shared.Keybinds['X']) then
                handsUpPromptActive = false
            end
        end
    end

    -- Start hands up prompt
    CreateThread(handsUpPromptHandler)

    if not attackbandits then
        Wait(100)
        if Config.Debug then
            print('Hands up')
            print('Pause Combat Npcs Bantids, dont dead player but bandits robbery')
        end
        local pauseDuration = 10000
        TaskPause(banditPed, pauseDuration)

        -- Check if the player pressed the hands up key
        if handsUpPromptActive then
            -- Player pressed hands up key, stop combat and approach the player
            TaskStandStill(banditPed, -1)

            -- Your code to approach the player and rob without killing
            approachAndRob(playerPed, banditPed)

        else
            -- Player didn't press hands up key, continue combat
            TaskCombatPed(banditPed, playerPed)
            if Config.Debug then
                print('Combat Npcs Bantids')
            end
            lib.notify({ title = ('Hands up, vermin or you dead!'), duration = 5000, type = 'inform' })
        end
    else
        TaskCombatPed(banditPed, playerPed)
        if Config.Debug then
            print('Combat Npcs Bantids')
        end
        lib.notify({ title = ('Hands up, vermin or you dead!'), duration = 5000, type = 'inform' })
    end
end

----------------------------------------------------------------------------
-- bandits Trigger
----------------------------------------------------------------------------
local function banditsTrigger(bandits)
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

        TaskCombatPed(npcs[k], PlayerPedId())

        Wait(1000)
        
        checkHandsUp(PlayerPedId(), npcs[k])

    end
    lib.notify({ title = ('You were ambushed!'), duration = 5000, type = 'inform' })
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
            if dis < Config.TriggerBandits and not spawnbandits then
                if Config.Debug then
                    print('Trigger bandits')
                end
                banditsTrigger(v.bandits)
            end
            if dis >= Config.CalloffBandits and spawnbandits then
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
        if IsPedDeadOrDying(PlayerPedId(), true) and spawnbandits then
            lib.notify({ title = ('looks like they got you'), duration = 5000, type = 'error' })
            Wait(5000)

            TriggerServerEvent('rsg-bandits:server:robplayer')
            lib.notify({ title = ('and you have been robbed'), duration = 5000, type = 'error' })
            stopBandits()
            break
        end
        if calloffbandits then
            stopBandits()
            lib.notify({ title = ('looks like you got away'), duration = 5000, type = 'error' })
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

    PromptDelete(HandsUpPrompt)

end)
