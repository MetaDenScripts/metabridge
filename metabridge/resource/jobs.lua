MetaBridge = MetaBridge or {}

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end

    return value:match('^%s*(.-)%s*$') or ''
end

local function getFrameworkAdapter()
    local framework = MetaBridge.getFramework and MetaBridge.getFramework() or nil
    if not framework or type(BridgeAdapters) ~= 'table' then
        return nil, framework
    end

    return BridgeAdapters[framework], framework
end

local function normalizeJobGrades(job)
    local grades = {}
    if type(job) ~= 'table' or type(job.grades) ~= 'table' then
        return grades
    end

    local sourceGrades = job.grades
    local isSequentialArray = sourceGrades[1] ~= nil

    if isSequentialArray then
        for _, grade in ipairs(sourceGrades) do
            if type(grade) == 'table' and tonumber(grade.level) ~= nil then
                local level = tonumber(grade.level)
                grades[#grades + 1] = {
                    level = level,
                    name = trim(grade.name or grade.label) ~= '' and trim(grade.name or grade.label) or ('Grade %s'):format(level),
                    isBoss = grade.isBoss == true or grade.isboss == true,
                }
            end
        end
    else
        for level, grade in pairs(sourceGrades) do
            local numericLevel = tonumber(level)
            if numericLevel ~= nil then
                local gradeName = type(grade) == 'table' and trim(grade.name or grade.label) or ''
                grades[#grades + 1] = {
                    level = numericLevel,
                    name = gradeName ~= '' and gradeName or ('Grade %s'):format(numericLevel),
                    isBoss = type(grade) == 'table' and (grade.isBoss == true or grade.isboss == true) or false,
                }
            end
        end
    end

    table.sort(grades, function(left, right)
        return left.level < right.level
    end)

    return grades
end

function MetaBridge.getJobDefinitions()
    local adapter, framework = getFrameworkAdapter()
    if type(adapter) ~= 'table' or type(adapter.getJobDefinitions) ~= 'function' then
        BridgeShared.debug('server.jobs', 'Job definitions are unavailable for framework', {
            framework = framework
        })
        return nil
    end

    local definitions = adapter.getJobDefinitions()
    return type(definitions) == 'table' and definitions or nil
end

function MetaBridge.getJobMetadata(jobName, fallbackLabel)
    if type(jobName) ~= 'string' or jobName == '' then
        return nil
    end

    local definitions = MetaBridge.getJobDefinitions()
    local job = type(definitions) == 'table' and definitions[jobName] or nil

    return {
        name = jobName,
        label = type(job) == 'table' and job.label or (fallbackLabel or jobName),
        grades = normalizeJobGrades(job),
    }
end
