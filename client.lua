local spawnedBotPeds = {}
local botStates = {}

local function tableContains(list, value)
    if type(list) ~= 'table' then return false end
    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
end

local function requestModelSync(model)
    local modelHash = (type(model) == 'number') and model or joaat(model)
    lib.requestModel(modelHash, 5000)
    return modelHash
end

local function spawnBot(botIndex, botConfig)
    local modelHash = requestModelSync(botConfig.model)
    local coords = botConfig.coords

    local ped = CreatePed(0, modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Idle scenario to look like a medic
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)

    spawnedBotPeds[botIndex] = ped
    botStates[botIndex] = { origin = vec4(coords.x, coords.y, coords.z, coords.w), busy = false }
    return ped
end

local SCENARIO_PROP_MODELS = {
    'prop_amb_clipboard_01',
    'p_cs_clipboard',
    'prop_notepad_01',
    'p_notepad_01_s',
    'prop_pencil_01',
    'prop_ld_health_pack',
    'prop_ld_syringe_01'
}

local function clearScenarioPropsAroundPed(ped)
    if not DoesEntityExist(ped) then return end
    local coords = GetEntityCoords(ped)
    for i = 1, #SCENARIO_PROP_MODELS do
        local model = SCENARIO_PROP_MODELS[i]
        local hash = (type(model) == 'number') and model or joaat(model)
        local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.5, hash, false, false, false)
        while obj and obj ~= 0 do
            SetEntityAsMissionEntity(obj, true, true)
            DeleteObject(obj)
            obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.5, hash, false, false, false)
        end
    end
end

local function waitForArrival(ped, dest, tolerance, timeoutMs)
    local started = GetGameTimer()
    while DoesEntityExist(ped) do
        local p = GetEntityCoords(ped)
        local dist = #(p - vector3(dest.x, dest.y, dest.z))
        if dist <= (tolerance or 1.2) then return true end
        if timeoutMs and (GetGameTimer() - started) > timeoutMs then return false end
        Wait(100)
    end
    return false
end

local function goToCoord(ped, dest, speed)
    ClearPedTasks(ped)
    clearScenarioPropsAroundPed(ped)
    FreezeEntityPosition(ped, false)
    TaskGoToCoordAnyMeans(ped, dest.x, dest.y, dest.z, speed or 2.0, 0, false, 786603, 0.0)
end

local function faceEntity(ped, target)
    TaskTurnPedToFaceEntity(ped, target, 1000)
    Wait(1000)
end

local function playAnim(ped, dict, clip, durationMs)
    if not lib.requestAnimDict(dict, 5000) then return end
    TaskPlayAnim(ped, dict, clip, 2.0, 2.0, -1, 1, 0.0, false, false, false)
    if durationMs and durationMs > 0 then
        Wait(durationMs)
    end
    StopAnimTask(ped, dict, clip, 1.0)
end

local function attemptRevive(botIndex)
    local ped = PlayerPedId()
    local isDead = (type(IsDead) == 'function' and IsDead()) or IsEntityDead(ped)
    local botPed = spawnedBotPeds[botIndex]
    if not DoesEntityExist(botPed) then
        lib.notify({ title = 'Médico', description = 'El doctor no está disponible.', type = 'error' })
        return
    end

    local state = botStates[botIndex]
    if state and state.busy then
        lib.notify({ title = 'Médico', description = 'El doctor está ocupado, espera un momento.', type = 'warning' })
        return
    end

    local ok, reason, secondsToRevive = lib.callback.await('biyei_revivebot:canRevive', false, botIndex)
    if not ok then
        lib.notify({ title = 'Médico', description = reason or 'Acción no permitida.', type = 'error' })
        return
    end

    local durationMs = math.floor((secondsToRevive or 10) * 1000)

    if state then state.busy = true end

    -- Doctor camina hacia el jugador
    local playerCoords = GetEntityCoords(ped)
    goToCoord(botPed, { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z }, 2.0)
    waitForArrival(botPed, { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z }, 1.6, 10000)
    faceEntity(botPed, ped)

    -- Comenzar tratamiento con progressbar mientras el doctor anima
    CreateThread(function()
        if isDead then
            playAnim(botPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', durationMs)
        else
            playAnim(botPed, 'amb@medic@standing@tendtodead@base', 'base', durationMs)
        end
    end)

    local progressOk = lib.progressCircle({
        duration = durationMs,
        position = 'bottom',
        label = isDead and 'Reanimando...' or 'Curando...',
        useWhileDead = true,
        canCancel = false,
        disable = { move = true, car = true, combat = true }
    })

    if progressOk then
        if isDead then
            if Config and Config.EventRevive then
                TriggerEvent(Config.EventRevive)
                TriggerServerEvent(Config.EventRevive)
            end
            Wait(250)
            if IsEntityDead(ped) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, true)
                ClearPedBloodDamage(ped)
                SetEntityHealth(ped, GetEntityMaxHealth(ped))
            end
            lib.notify({ title = 'Médico', description = 'Has sido reanimado.', type = 'success' })
        else
            local maxHealth = GetEntityMaxHealth(ped)
            SetEntityHealth(ped, maxHealth)
            ClearPedBloodDamage(ped)
            lib.notify({ title = 'Médico', description = 'Has sido curado.', type = 'success' })
        end
    end

    -- Volver a origen
    if state and state.origin then
        goToCoord(botPed, { x = state.origin.x, y = state.origin.y, z = state.origin.z }, 2.0)
        waitForArrival(botPed, { x = state.origin.x, y = state.origin.y, z = state.origin.z }, 1.6, 12000)
        ClearPedTasks(botPed)
        clearScenarioPropsAroundPed(botPed)
        SetEntityHeading(botPed, state.origin.w or GetEntityHeading(botPed))
        TaskStartScenarioInPlace(botPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
        FreezeEntityPosition(botPed, true)
    end

    if state then state.busy = false end
end

local function addTargetInteraction(ped, botIndex)
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'biyei_revive_' .. tostring(botIndex),
                icon = 'fa-solid fa-notes-medical',
                label = 'Revivir',
                distance = 2.0,
                onSelect = function()
                    attemptRevive(botIndex)
                end
            }
        })
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    label = 'Revivir',
                    icon = 'fa-solid fa-notes-medical',
                    action = function()
                        attemptRevive(botIndex)
                    end
                }
            },
            distance = 2.0
        })
    else
        print('[biyei_revivebot] Config.Target inválido: ' .. tostring(Config.Target))
    end
end

local textUiShownFor = nil

local function startTextUiLoop(ped, botIndex)
    CreateThread(function()
        local showKey = 38 -- INPUT_PICKUP (E)
        while DoesEntityExist(ped) do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local pedCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - pedCoords)

            if distance <= 2.0 then
                if textUiShownFor ~= botIndex then
                    textUiShownFor = botIndex
                    lib.showTextUI('[E] Hablar con médico')
                end

                if IsControlJustReleased(0, showKey) then
                    attemptRevive(botIndex)
                end
            else
                if textUiShownFor == botIndex then
                    lib.hideTextUI()
                    textUiShownFor = nil
                end
            end

            Wait(0)
        end

        if textUiShownFor == botIndex then
            lib.hideTextUI()
            textUiShownFor = nil
        end
    end)
end

CreateThread(function()
    if not Config or not Config.Bots then return end

    for index = 1, #Config.Bots do
        local bot = Config.Bots[index]
        local ped = spawnBot(index, bot)

        if Config.UseTarget then
            addTargetInteraction(ped, index)
        else
            startTextUiLoop(ped, index)
        end
    end
end)


IsDead = function()
    if LocalPlayer.state.isDead then
        return true
    end
    if IsEntityDead(PlayerPedId()) then
        return true
    end
    return false
end
