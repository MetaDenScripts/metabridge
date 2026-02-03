RegisterCommand('bridge_test', function(source)
    local framework = MetaBridge.getFramework()
    print(('[MetaBridge] Framework: %s'):format(framework or 'none'))

    if source == 0 then
        print('[MetaBridge] Run this command as a player to see player data.')
        return
    end

    local identifier = MetaBridge.getIdentifier(source)
    local job = MetaBridge.getJob(source)
    local cash = MetaBridge.getMoney(source, 'cash')

    print(('[MetaBridge] Identifier: %s'):format(identifier or 'n/a'))
    print(('[MetaBridge] Job: %s'):format(job and job.name or 'n/a'))
    print(('[MetaBridge] Cash: %s'):format(cash or 'n/a'))
end, false)
