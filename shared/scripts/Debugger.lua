local Debugger = {}

Debugger.prefix = "Logger | " 
Debugger.Path = ".\\Mods\\shared\\"

---@param message string
function Debugger.log(message)
    print(message .."\n")
    local file = io.open(Debugger.Path .. "Logs.txt", "a")
    if not file then
        file = io.open(Debugger.Path .. "Logs.txt", "w")
    end
    if file then
        local time = os.date("[%H:%M:%S]")
        file:write(time .. " " .. message .."\n")
        file:close()
    end
end

--This code is poorly optimized and should be done in future versions, but works well for debugging purposes

---@param array table
---@param depth number
---@return string
function Debugger.arrayToString(array, depth)
    depth = depth or 0
    local logString = "\n" 
    local getMessage = Debugger.getMessage  
    
    for key, value in pairs(array) do
        local depthCharacters = string.rep("-----", depth)
        logString = logString .. depthCharacters .. "-> Key: " .. getMessage(key)
        
        if type(value) == "table" then
            logString = logString .. Debugger.arrayToString(value, depth + 1)
        else
            logString = logString .. " | Value: " .. getMessage(value) .. "\n"
        end
    end

    return logString
end

---@param target string|number|boolean|table|UObject|FString|FName|FText
---@return string
function Debugger.getMessage(target)
    if type(target) == "string" then
        return target
    elseif type(target) == "number" or type(target) == "boolean" then
        return tostring(target)
    elseif type(target) == "table" then
        return Debugger.arrayToString(target, 0)
    elseif type(target) == "userdata" then
        local _ue4ssType = target:type()
        if _ue4ssType == "FString" or _ue4ssType == "FName" or _ue4ssType == "FText" then
            return _ue4ssType .. " " .. target:ToString()
        elseif target:IsValid() then
            if _ue4ssType == "TArray" then
                return target:type()
            else
                return target:GetFullName()
            end
        else
            return "nil"
        end
    else
        return "nil"
    end
end

---@param target any
function Debugger.print(target)
    print(Debugger.getMessage(target))
end

return Debugger