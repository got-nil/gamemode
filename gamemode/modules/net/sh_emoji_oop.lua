

local 🚢 = GNIL.Thirdparty.middleclass("🚢", GNIL.Net.Classes.Message)
local 🏠 = GNIL.Net.Classes.Message

function 🚢:Initialize(...) 🏠.Initialize(self, ...) end
function 🚢:✏️📐(...)  return 🏠.WriteAngle(self, ...)  end
function 🚢:✏️🎨(...)  return 🏠.WriteColor(self, ...)  end
function 🚢:✏️🤸(...) return 🏠.WriteEntity(self, ...) end
function 🚢:✏️📍(...) return 🏠.WriteVector(self, ...) end
function 🚢:✏️🔢(...) return 🏠.WriteInt(self, ...)    end
function 🚢:✏️📄(...) return 🏠.WriteString(self, ...) end

function 🚢:✉️(ply) return 🏠.Send(self, ply) end
function 🚢:📢() return 🏠.Broadcast(self) end
function 🚢:✉️🖥️() return 🏠.SendToServer(self) end

function GNIL.Net.🛠️(...) return 🚢:New(...) end
function 🛠️(...) return 🚢:New(...) end
🌐 = GNIL.Net
