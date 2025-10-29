local Framework = 'standalone'
local QBCore = nil
local ESX = nil

local function detectFramework()
    if Config and (Config.Framework == 'qbcore' or Config.Framework == 'auto') then
        if GetResourceState('qb-core') == 'started' then
            Framework = 'qbcore'
            QBCore = exports['qb-core']:GetCoreObject()
            return
        end
    end

    if Config and (Config.Framework == 'esx' or Config.Framework == 'auto') then
        if GetResourceState('es_extended') == 'started' then
            Framework = 'esx'
            if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
                ESX = exports['es_extended']:getSharedObject()
            elseif ESX == nil and type(_G.ESX) == 'table' then
                ESX = _G.ESX
            end
            return
        end
    end

    Framework = 'standalone'
end

detectFramework()

local function getPlayerJobName(src)
    if Framework == 'qbcore' and QBCore then
        local player = QBCore.Functions.GetPlayer(src)
        if player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name
        end
    elseif Framework == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then
            return xPlayer.job.name
        end
    end
    return nil
end

local function getPlayerCitizenId(src)
    if Framework == 'qbcore' and QBCore then
        local player = QBCore.Functions.GetPlayer(src)
        if player and player.PlayerData then
            return player.PlayerData.citizenid
        end
    elseif Framework == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.identifier
        end
    end
    -- Fallback to license identifier
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if id:find('license:') == 1 then
            return id
        end
    end
    return identifiers and identifiers[1] or ('player:' .. tostring(src))
end

local function tableContains(list, value)
    if type(list) ~= 'table' then return false end
    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
end

local function countOnlineMedics()
    local medics = 0
    local players = GetPlayers()
    for i = 1, #players do
        local src = tonumber(players[i])
        local jobName = getPlayerJobName(src)
        if jobName and tableContains(Config.MedicsJobs or {}, jobName) then
            medics = medics + 1
        end
    end
    return medics
end

local function isPlayerAllowedForBot(src, bot)
    -- jobs filter
    if bot.jobs ~= false and type(bot.jobs) == 'table' then
        local jobName = getPlayerJobName(src)
        if not jobName or not tableContains(bot.jobs, jobName) then
            return false, 'Tu empleo no puede usar este servicio.'
        end
    end

    -- citizenid filter
    if bot.citizenid ~= false and type(bot.citizenid) == 'table' then
        local cid = getPlayerCitizenId(src)
        if not cid or not tableContains(bot.citizenid, cid) then
            return false, 'No estás autorizado para usar este servicio.'
        end
    end

    -- medics availability: allow only if online medics are less than required min
    local medicsOnline = countOnlineMedics()
    local minMedics = tonumber(bot.minMedics or 0) or 0
    if medicsOnline >= minMedics and minMedics > 0 then
        return false, 'Hay personal médico disponible. Llama a emergencias.'
    end

    return true, nil
end

lib.callback.register('biyei_revivebot:canRevive', function(source, botIndex)
    if not Config or not Config.Bots then
        return false, 'Configuración no válida', 10
    end
    local bot = Config.Bots[botIndex]
    if not bot then
        return false, 'Bot no encontrado', 10
    end

    local allowed, reason = isPlayerAllowedForBot(source, bot)
    if not allowed then
        return false, reason, bot.secondsToRevive or 10
    end

    return true, nil, bot.secondsToRevive or 10
end)


