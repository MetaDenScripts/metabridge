RegisterCommand('bridge_test', function(source)
    local framework = Bridge.getFramework()
    print(('[Bridge] Framework: %s'):format(framework or 'none'))

    if source == 0 then
        print('[Bridge] Run this command as a player to see player data.')
        return
    end

    local identifier = Bridge.getIdentifier(source)
    local job = Bridge.getJob(source)
    local cash = Bridge.getMoney(source, 'cash')

    print(('[Bridge] Identifier: %s'):format(identifier or 'n/a'))
    print(('[Bridge] Job: %s'):format(job and job.name or 'n/a'))
    print(('[Bridge] Cash: %s'):format(cash or 'n/a'))
end, false)
