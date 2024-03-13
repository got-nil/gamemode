
---@class NetworkExtension: BaseExtension
local NetExtension = GNIL.Thirdparty.middleclass("NetExtension", GNIL.Classes.Extension)

function NetExtension:Initialize(moduleInstance)
    GNIL.Classes.Extension:Initialize(self, moduleInstance)

    if self._recievers == nil then
        self._recievers = {{}, {}}
    end
end

---When the module is being unloaded, remove all associated recievers.
function NetExtension:OnUnload()
    self:RemoveReceivers()
end

---Remove all associated network recievers.
function NetExtension:RemoveReceivers()
    for i = 1, 2 do
        for k, v in pairs(self._recievers[i]) do
            if not v then continue end
            if not GNIL.Net["_c"][k] then continue end

            -- Replace normal messages callbacks, or remove
            -- entirely for chuncked recievers. Auto replies
            -- with DISABLED error state.
            GNIL.Net["_c"][k][i] = Either(i == 1, GNIL.Net.Helpers.DisabledMessageReciever(k), nil)
        end
    end
end

---Add a network reciever by name.
---@param messageName any
---@param callback fun(len: integer, ply: Player, reply: NetworkReply): NetworkReply?
function NetExtension:Receive(messageName, callback)
    self._recievers[1][messageName] = true
    GNIL.Net.Receive(messageName, callback)
end

---Add a network chunked reciever by name.
---@param messageName any
---@param callback fun(len: integer, ply: Player, reply: NetworkReply): NetworkReply?
function NetExtension:ReceiveChunked(messageName, callback)
    self._recievers[2][messageName] = true
    GNIL.Net.ReceiveChunked(messageName, callback)
end

GNIL.Modules.Extensions.Add("net", NetExtension)