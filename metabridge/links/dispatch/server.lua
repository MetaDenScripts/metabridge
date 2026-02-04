local function shouldSendDispatch(data)
    if BridgeConfig and BridgeConfig.dispatch and BridgeConfig.dispatch.filterServer then
        return BridgeConfig.dispatch.filterServer(data) == true
    end

    return true
end

RegisterNetEvent('MetaBridge:dispatch:sendAlert', function(data)
    if not shouldSendDispatch(data) then
        return
    end

    TriggerClientEvent('MetaBridge:dispatch:clientAlert', -1, data)
end)
