
local EmojiNetworkMessage = GNIL.Thirdparty.middleclass("EmojiNetworkMessage", GNIL.Net.NetworkMessage)

function EmojiNetworkMessage:Initialize(...)
    GNIL.Net.NetworkMessage.Initialize(self, ...)
end

function EmojiNetworkMessage:✏️📐(...)  return GNIL.Net.NetworkMessage.WriteAngle(self, ...)  end
function EmojiNetworkMessage:✏️🎨(...)  return GNIL.Net.NetworkMessage.WriteColor(self, ...)  end
function EmojiNetworkMessage:✏️🤸(...) return GNIL.Net.NetworkMessage.WriteEntity(self, ...) end
function EmojiNetworkMessage:✏️📍(...) return GNIL.Net.NetworkMessage.WriteVector(self, ...) end
function EmojiNetworkMessage:✏️🔢(...)    return GNIL.Net.NetworkMessage.WriteInt(self, ...)    end
function EmojiNetworkMessage:✏️📄(...) return GNIL.Net.NetworkMessage.WriteString(self, ...) end

function EmojiNetworkMessage:✉️(ply) return GNIL.Net.NetworkMessage.Send(self, ply) end
function EmojiNetworkMessage:📢() return GNIL.Net.NetworkMessage.Broadcast(self) end
function EmojiNetworkMessage:✉️🖥️() return GNIL.Net.NetworkMessage.SendToServer(self) end

function GNIL.Net.🛠️(...) return EmojiNetworkMessage:New(...) end
function 🛠️(...) return EmojiNetworkMessage:New(...) end
🌐 = GNIL.Net
