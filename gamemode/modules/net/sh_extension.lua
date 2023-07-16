local NetExtension = GNIL.Thirdparty.middleclass("NetExtension", GNIL.Classes.Extension)

function NetExtension:Initialize(moduleInstance)
    GNIL.Classes.Extension:Initialize(self, moduleInstance)

    if self._recievers == nil then
        self._recievers = {{}, {}}
    end
end

-- When the module is being unloaded, remove all associated recievers.
function NetExtension:OnUnload()
    self:RemoveReceivers()
end

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

function NetExtension:Receive(messageName, ...)
    self._recievers[1][messageName] = true
    GNIL.Net.Receive(messageName, ...)
end

function NetExtension:ReceiveChunked(messageName, ...)
    self._recievers[2][messageName] = true
    GNIL.Net.ReceiveChunked(messageName, ...)
end

GNIL.ModuleExtensions.Add("net", NetExtension)