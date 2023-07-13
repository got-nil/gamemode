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

            -- Remove the reciever callback directly from the internal
            -- callbacks table. Not the best solution, but its still
            -- technically "internal use" so its okay?
            GNIL.Net["_c"][k][i] = nil
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