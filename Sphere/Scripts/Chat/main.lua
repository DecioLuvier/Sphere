local Logger = require("libs/Logger")
local Player = require("scripts/Player")
local System = require("scripts/System")
local manager = require("Chat/config")
local commands = manager["commands"]

---@param message FPalChatMessage
local function FormatChatMessage(message)
    local sender = message.Sender:ToString()
    local messageType = message.Category
    local message = message.Message:ToString()
    local messageTypeText = "None"

    if messageType == 1 then
        messageTypeText = "Global"
    elseif messageType == 2 then
        messageTypeText = "Guild"
    elseif messageType == 3 then
        messageTypeText = "Say"
    end
    return string.format("[%s] %s: %s", messageTypeText, sender, message)
end

---@param Command string
---@return string[]
local function GetArguments(Command)
    local Arguments = {}
    for argument in Command:gmatch("%S+") do
        table.insert(Arguments, argument)
    end
    return Arguments
end

---@param Command string
---@return boolean
local function IsNonSphereCommand(Command)
    local allNonSphereCommand = SphereGlobal.database.Configs.NonSphereCommands

    for i = 1, #allNonSphereCommand  do
        if string.lower(Command) == string.lower(allNonSphereCommand[i]) then 
            return true
        end
    end
    return false 
end

---@param player APlayerController
---@param ChatMessage FPalChatMessage
local function ListenChatMessage(player, ChatMessage)
    local messageText = ChatMessage.Message:ToString()

    if SphereGlobal.database.Configs.ShowGameChatOnConsole then
        Logger.print(FormatChatMessage(ChatMessage))
    else
        Logger.Log(FormatChatMessage(ChatMessage))
    end

    if string.match(messageText, "^/") then
        local commandString = string.sub(messageText, 2)
        local commandArgs = GetArguments(commandString)

        if commandArgs[1] then
            local selectedCommand = commandArgs[1]

            if not IsNonSphereCommand(selectedCommand) then
                ChatMessage.SenderPlayerUId["A"] = -1  
                ChatMessage.ReceiverPlayerUId["A"] = -1

                if commands[selectedCommand] then

                    if Player.GetPermissionName(player) == commands[selectedCommand].permissionLevel then
                        commands[selectedCommand].execute(player, commandArgs)
                    else
                        System.SendSystemToPlayer(player, "Denied access")
                    end
                else
                    System.SendSystemToPlayer(player, "Command Not Found")
                end
            end
        end
    end
end

RegisterHook("/Script/Pal.PalPlayerState:EnterChat_Receive", function(self, ChatMessage)
    local PalPlayerState = self:get() ---@type APalPlayerState
    local ChatMessage = ChatMessage:get() ---@type FPalChatMessage
    local palPlayerController = PalPlayerState:GetPlayerController()
    
    if SphereGlobal.database.Configs.AllPlayersAdmin then
        palPlayerController.bAdmin = true
    end
    ListenChatMessage(palPlayerController, ChatMessage)
    self:get().ChatCounter = 0 --Remove chat restriction
end)

RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", function(self)
    if SphereGlobal.database.Configs.BroadcastJoin then
        local palPlayerCharacter = self:get() ---@type APalPlayerCharacter
        local palPlayerController =  palPlayerCharacter:GetPalPlayerController()
        local playerName = Player.GetName(palPlayerController)
        local playerEnterMessage = string.format("%s joined the game!", playerName)
        System.SendSystemAnnounce(playerEnterMessage)
    end
end)

RegisterHook("/Script/Pal.PalPlayerController:OnDestroyPawn", function(self)
    if SphereGlobal.database.Configs.BroadcastExit then
        local palPlayerController = self:get() ---@type APalPlayerController
        local playerName = Player.GetName(palPlayerController)
        local playerLeaveMessage = string.format("%s disconnected.", playerName)
        System.SendSystemAnnounce(playerLeaveMessage)
    end
end)


local Monster = require("scripts/Monster")
local Pals = require("enums/Pals")
local Npcs = require("enums/Npcs")

RegisterHook("/Game/Pal/Blueprint/Component/DamageReaction/BP_AIADamageReaction.BP_AIADamageReaction_C:OnDead", function(argument1, argument2)
    local deadInfo = argument2:get() ---@type FPalDeadInfo

    local victimType = System.GetInstanceType(deadInfo.SelfActor)
    local killerType = System.GetInstanceType(deadInfo.LastAttacker)

    if (victimType == "Player") or (victimType == "Player" and killerType == "Player") then

        local victimName = nil
        if victimType == "Player" then
            victimName = Player.GetName(deadInfo.SelfActor:GetPalPlayerController())
        else 
            local debugName = Monster.GetDebugName(deadInfo.SelfActor)

            if victimType == "WildNPC" then
                victimName = Npcs[debugName]
            else
                victimName = Pals[debugName]
            end
        end

        if deadInfo.DeadType == 1 then
            local killerName = nil
            if killerType == "Player" then
                killerName = Player.GetName(deadInfo.LastAttacker:GetPalPlayerController())
            else 
                local debugName = Monster.GetDebugName(deadInfo.LastAttacker)
    
                if killerType == "WildNPC" then
                    killerName = Npcs[debugName]
                else
                    killerName = Pals[debugName]
                end
            end
            System.SendSystemAnnounce(string.format("%s was killed by %s", victimName, killerName))
        elseif deadInfo.DeadType == 2 then
            System.SendSystemAnnounce(string.format("%s perished himself", victimName))
        elseif deadInfo.DeadType == 3 then
            System.SendSystemAnnounce(string.format("%s died to extreme weather", victimName))
        elseif deadInfo.DeadType == 4 or deadInfo.DeadType == 9 then
            System.SendSystemAnnounce(string.format("%s hit the ground too hard", victimName))
        elseif deadInfo.DeadType == 5 then
            System.SendSystemAnnounce(string.format("%s poisoned to death", victimName))
        elseif deadInfo.DeadType == 6 then
            System.SendSystemAnnounce(string.format("%s burned to death", victimName))
        elseif deadInfo.DeadType == 7 then
            System.SendSystemAnnounce(string.format("%s drowned", victimName))
        elseif deadInfo.DeadType == 8 then
            System.SendSystemAnnounce(string.format("%s died in a tower boss", victimName))
        end
    end
end)