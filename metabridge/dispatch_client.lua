MetaBridgeClient = MetaBridgeClient or {}

local function resolveDispatch()
    if BridgeConfig and BridgeConfig.dispatch and BridgeConfig.dispatch.system then
        if BridgeShared and BridgeShared.normalizeDispatch then
            local normalized = BridgeShared.normalizeDispatch(BridgeConfig.dispatch.system)
            if normalized then
                return normalized
            end
        else
            return BridgeConfig.dispatch.system
        end
    end

    if BridgeShared and BridgeShared.detectDispatch then
        return BridgeShared.detectDispatch()
    end

    return 'standalone'
end

local function shouldDisplayDispatch(data)
    if BridgeConfig and BridgeConfig.dispatch and BridgeConfig.dispatch.filter then
        return BridgeConfig.dispatch.filter(data) == true
    end

    return true
end

local function createDispatchBlip(data)
    local blipData = data.blip or {}
    local coords = data.coords or GetEntityCoords(PlayerPedId())

    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, blipData.sprite or 58)
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, blipData.color or 1)
    SetBlipAlpha(blip, 255)
    SetBlipFlashes(blip, blipData.flash or false)
    SetBlipScale(blip, blipData.scale or 1.0)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipData.text or 'Dispatch Alert')
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, false)

    Citizen.SetTimeout(blipData.duration or 120000, function()
        RemoveBlip(blip)
    end)
end

local function notifyDispatch(message, subtitle)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(subtitle or '')
    EndTextCommandThefeedPostMessagetext('CHAR_CALL911', 'CHAR_CALL911', false, 0, message or '', '')
    EndTextCommandThefeedPostTicker(false, true)
end

local function sendStandalone(data)
    TriggerServerEvent('MetaBridge:dispatch:sendAlert', data)
end

local function sendPsDispatch(data)
    local function getGender(ped)
        if GetEntityModel(ped) == GetHashKey('mp_m_freemode_01') then
            return 'male'
        end
        if GetEntityModel(ped) == GetHashKey('mp_f_freemode_01') then
            return 'female'
        end
        return nil
    end

    local function getStreetAndZone(coords)
        local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
        local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
        return street .. ', ' .. zone
    end

    local coords = data.coords or GetEntityCoords(PlayerPedId())
    local dispatchData = {
        jobs = data.jobs or {},
        message = data.description or '',
        codeName = 'NONE',
        code = data.code or '10-35',
        icon = 'fas fa-question',
        priority = 2,
        coords = coords,
        gender = getGender(PlayerPedId()),
        street = getStreetAndZone(coords),
        name = data.message or nil,
        alertTime = 12,
        automaticGunfire = false,
        alert = {
            radius = 0,
            sprite = (data.blip and data.blip.sprite) or 1,
            color = (data.blip and data.blip.color) or 1,
            scale = (data.blip and data.blip.scale) or 0.5,
            length = 2,
            sound = 'Lose_1st',
            sound2 = 'GTAO_FM_Events_Soundset',
            flash = (data.blip and data.blip.flash) or false
        }
    }

    TriggerServerEvent('ps-dispatch:server:notify', dispatchData)
end

local function sendQsDispatch(data)
    TriggerServerEvent('qs-dispatch:server:CreateDispatchCall', {
        job = data.jobs or {},
        callLocation = data.coords or GetEntityCoords(PlayerPedId()),
        callCode = data.code,
        message = data.message or '',
        blip = {
            sprite = (data.blip and data.blip.sprite) or 58,
            scale = (data.blip and data.blip.scale) or 1.0,
            colour = (data.blip and data.blip.color) or 3,
            flashes = (data.blip and data.blip.flash) or false,
            text = (data.blip and data.blip.text) or 'Dispatch Alert',
            time = (data.blip and data.blip.duration) or 120000
        }
    })
end

local function sendRcoreDispatch(data)
    local dispatchData = {
        code = data.code or '10-35',
        default_priority = 'medium',
        coords = data.coords or GetEntityCoords(PlayerPedId()),
        job = data.jobs or {},
        text = data.message or '',
        type = 'alerts',
        blip_time = (data.blip and data.blip.duration) or 120000,
        blip = {
            sprite = (data.blip and data.blip.sprite) or 58,
            colour = (data.blip and data.blip.color) or 3,
            scale = (data.blip and data.blip.scale) or 1.0,
            text = (data.blip and data.blip.text) or 'Dispatch Alert',
            flashes = (data.blip and data.blip.flash) or false,
            radius = (data.blip and data.blip.radius) or 0
        }
    }
    TriggerServerEvent('rcore_dispatch:server:sendAlert', dispatchData)
end

local function sendCdDispatch(data)
    local dispatchData = exports['cd_dispatch']:GetPlayerInfo()
    TriggerServerEvent('cd_dispatch:AddNotification', {
        job_table = data.jobs or {},
        coords = data.coords or GetEntityCoords(PlayerPedId()),
        title = data.message or '',
        message = data.description or '',
        unique_id = dispatchData.unique_id,
        sound = 1,
        blip = {
            sprite = (data.blip and data.blip.sprite) or 58,
            scale = (data.blip and data.blip.scale) or 1.0,
            colour = (data.blip and data.blip.color) or 3,
            text = (data.blip and data.blip.text) or 'Dispatch Alert',
            time = 2,
            radius = 0
        }
    })
end

function MetaBridgeClient.sendDispatch(data)
    if BridgeConfig and BridgeConfig.dispatch and BridgeConfig.dispatch.send then
        return BridgeConfig.dispatch.send(data)
    end

    local system = resolveDispatch()
    if system == 'ps' then
        return sendPsDispatch(data)
    end

    if system == 'qs' then
        return sendQsDispatch(data)
    end

    if system == 'rcore' then
        return sendRcoreDispatch(data)
    end

    if system == 'cd' then
        return sendCdDispatch(data)
    end

    return sendStandalone(data)
end

RegisterNetEvent('MetaBridge:dispatch:clientAlert', function(data)
    if not shouldDisplayDispatch(data) then
        return
    end

    createDispatchBlip(data)
    notifyDispatch(data.message or '', data.description or '')
end)
