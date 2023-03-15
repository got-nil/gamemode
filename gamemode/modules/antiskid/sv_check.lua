
-- SkidCheck class!
local Check = GNIL.Thirdparty.middleclass("SkidCheck")
function Check:Initialize(name, options)
    self.name = name
    
    -- Validate/restructure the options table.
    local success, out = GNIL.Validation.Structure(options, {
        ["net_message"] = {false, TYPE_BOOL}  -- Should a netmessage ID be created for the check to use?
    })
    if not success then
        error("Could not create SkidCheck with validation error: " .. out)
    end
    self.options = out

    -- If there is a netmessage associated, create a random net salt.
    -- This is the same string for all players, and is used to generate the
    -- message identifier hash (salt + player steamid).
    if self.options.net_message then
        self._net_salt = GNIL.Utils.Random(math.random(36, 42))
        self._net_id_len = math.random(8, 14)
    end
    self._commands = {}
end

-- Should be overwritten.
function Check:Send(ply) return false end               -- Send the actual check to the player.
function Check:Receive(len, ply) return false end       -- Recieve the NetworkMessage sent from player.
function Check:NoResponse(ply) return false end         -- The player did not send the NetworkMessage.

-- Generate a network identifier that should be sent to the Check reciever
-- to identify the current check. This is hashed with the players steam ID
-- to ensure that each ID is different across players.
function Check:GetNetIdentifier(ply_or_steamid64)
    if ply_or_steamid64:IsPlayer() then ply_or_steamid64 = ply_or_steamid64:SteamID64() end
    return string.sub(util.SHA256(self._net_salt .. ply_or_steamid64), 0, self._net_id_len) 
end

-- A string that can be concatenated with client code to generate
-- a GNIL NetworkMessage class with the AntiSkid message name and check
-- identifier auto written.
function Check:NetMessageString(ply)
    if not self.options.net_message then return "" end
    return string.format("GNIL.Net.NetworkMessage:New(%q):WriteString(%q)", GNIL.AntiSkid["_message_name"], self:GetNetIdentifier(ply))
end

-- Alias to ban a player for cheating.
function Check:Cheater(ply, reason)
    GNIL.log("SkidCheck: Cheater " .. ply:ToString() .. " found by '" .. self.name .. "'" .. (reason && ", with reason: " .. reason || ""), "success")
    GNIL.AntiSkid.Cheater(ply, self.name)
end

-- Create a callback command that should be ran to ban the cheater.
function Check:CreateBanCommand(ply)

    -- Remove the last concommand if there is one.
    if self._commands[sid] then
        concommand.Remove(self._commands[sid])
    end

    -- Create a new concommand and store it.
    local command = GNIL.Utils.Random(math.random(18, 24))
    self._commands[sid] = command

    -- Actually add the concommand.
    concommand.Add(command, function(caller)
        if sid != caller:SteamID64() then
            return
        else
            self:Cheater(caller, "Called the cheat command!")
            concommand.Remove(command)
        end
    end, nil, FCVAR_UNREGISTERED)
    return command
end

-- Expect a network response, call NoResponse if the player has not sent
-- the message within seconds provided. The check cna then handle missing
-- message behaviour itself!
function Check:ExpectNetResponse(ply, seconds)
    local sid = ply:SteamID64()

    -- Ensure that the player has a waiting for table, as there could be
    -- multiple checks waiting for the player to respond.
    if GNIL.AntiSkid["_waiting_for"][sid] == nil then
        GNIL.AntiSkid["_waiting_for"][sid] = {}
    end
    GNIL.AntiSkid["_waiting_for"][sid][self.name] = true

    -- Setup a timer to call NoResponse after x seconds if _waiting_for is
    -- still true (the net message hasnt been recieved from the player).
    timer.Simple(seconds or 10, function()
        if GNIL.AntiSkid["_waiting_for"][sid] and GNIL.AntiSkid["_waiting_for"][sid][self.name] then
            self:NoResponse(ply)
        end
    end)
end

-- Store the check class so it can be initialized by the detection files!
GNIL.AntiSkid.Check = Check