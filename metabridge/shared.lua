BridgeShared = BridgeShared or {}

function BridgeShared.getResourceState(resourceName)
    if GetResourceState then
        return GetResourceState(resourceName)
    end

    return 'missing'
end

function BridgeShared.isStarted(resourceName)
    return BridgeShared.getResourceState(resourceName) == 'started'
end

function BridgeShared.detectFramework()
    if BridgeShared.isStarted('qbx_core') then
        return 'qbox'
    end

    if BridgeShared.isStarted('qb-core') then
        return 'qbcore'
    end

    if BridgeShared.isStarted('es_extended') then
        return 'esx'
    end

    return nil
end
