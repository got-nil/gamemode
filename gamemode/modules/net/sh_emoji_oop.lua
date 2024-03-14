---@diagnostic disable
-- Originally wanted to test if this was possible.
-- Now, I can't bring myself to remove it.

local 🚢 = GNIL.Thirdparty.middleclass("🚢", GNIL.Net.Classes.Message)
local 🏠 = GNIL.Net.Classes.Message

function 🚢:Initialize(...) 🏠.Initialize(self, ...) end
function 🚢:✏️📐(...)  return 🏠.WriteAngle(self, ...) end
function 🚢:✏️🎨(...)  return 🏠.WriteColor(self, ...) end
function 🚢:✏️🤸(...) return 🏠.WriteEntity(self, ...) end
function 🚢:✏️📍(...) return 🏠.WriteVector(self, ...) end
function 🚢:✏️🔢(...) return 🏠.WriteInt(self, ...) end
function 🚢:✏️📄(...) return 🏠.WriteString(self, ...) end

function 🚢:✉️(ply) return 🏠.Send(self, ply) end
function 🚢:📢() return 🏠.Broadcast(self) end
function 🚢:✉️🖥️() return 🏠.SendToServer(self) end

-- Reply interface.
function 🚢:↩️(callback) return 🏠.OnReply(self, callback) end
function 🚢:↩️⏱️(timeout) return 🏠.SetReplyTimeout(self, timeout) end

-- Error interface.
function 🚢:⚠️(callback) return 🏠.OnError(self, callback) end
function 🚢:⚠️⏱️(callback) return 🏠.OnTimeout(self, callback) end
function 🚢:⚠️🐌(callback) return 🏠.OnRatelimited(self, callback) end

-- Global interface.
🛠️ =        function(...) return 🚢:New(...) end
🌐 =        GNIL.Net
🌐.🛠️ =     function (...) return 🚢:New(...) end
🌐.📨 =     function(messageName, callback) return GNIL.Net.Receive(messageName, callback) end
🌐.📨📡 =   function(messageName, callback) return GNIL.Net.ReceiveChunked(messageName, callback) end
