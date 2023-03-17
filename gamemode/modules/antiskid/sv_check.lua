
-- SkidCheck class!
local Check = GNIL.Thirdparty.middleclass("SkidCheck")
function Check:Initialize(name, options)
    self.name = name
    
    -- Validate/restructure the options table.
    local success, out = GNIL.Validation.Structure(options or {}, {
        ["net_message"] = {false, TYPE_BOOL},   -- Should a netmessage ID be created for the check to use?
        ["whitelist"] = {false, TYPE_BOOL}      -- Is the check using a whitelist?
    })
    if not success then
        error("Could not create SkidCheck with validation error: " .. out)
    end
    self.options = out
    self._net_waiting_for = {}
    self._net_callbacks = {}
    self._commands = {}

    -- If there is a netmessage associated, create a random net salt.
    -- This is the same string for all players, and is used to generate the
    -- message identifier hash (salt + player steamid).
    if self.options.net_message then
        self._net_salt = GNIL.Utils.Random(math.random(36, 42))
        self._net_id_len = math.random(8, 14)
    end

    -- If the check uses a whitelist, create a whitelist manager instance.
    self.whitelist = self.options.whitelist && GNIL.AntiSkid.Whitelist:New(self) || nil
end

-- Should be overwritten.
function Check:Start(ply, callback) return false end    -- Start the check, call the callback with data once finished.
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
function Check:NetMessageString(ply, callback, expect_response, timeout)
    if not self.options.net_message then return "" end

    local using_callback, callback_id = isfunction(callback), ""
    if using_callback then
        callback_id = GNIL.Utils.Random(math.random(4, 8))
        self._net_callbacks[callback_id] = callback
    end

    -- Default to always expecting a response.
    if expect_response != false then
        local sid = ply:SteamID64()
        self._net_waiting_for[sid] = true

        -- Setup a timer to call NoResponse after x seconds if _waiting_for is
        -- still true (the net message hasnt been recieved from the player).
        timer.Simple(timeout or 10, function()
            if self._net_waiting_for[sid] then
                self:NoResponse(ply)
                callback(false, "Failed to respond to Net Message")
                self._net_waiting_for[sid] = false
            end
        end)
    end

    -- The actual network string output.
    --  CheckMessageName(string), PlayerNetId(string), IsUsingCallback(bool) [if IsUsingCallback: CallbackId(string)]
    local net_string = string.format("GNIL.Net.NetworkMessage:New(%q):WriteString(%q):WriteBool(%s)", GNIL.AntiSkid["_message_name"], self:GetNetIdentifier(ply), using_callback && "true" || "false")
    if using_callback then
        net_string = net_string .. string.format(":WriteString(%q)", callback_id)
    end
    return net_string
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

-- Ensure the antiskid data directory exists
GNIL.Utils.CreateDataPath("gnil/antiskid")

-- Store the check class so it can be initialized by the detection files!
GNIL.AntiSkid.Check = Check