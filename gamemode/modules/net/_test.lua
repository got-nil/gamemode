-- REMOVE THIS BEFORE PULL REQUEST, THIS IS JUST SO I DONT
-- LOSE THE TEST FILE FOR THE 4TH TIME BECAUSE I CLOSED VS
-- WEIRDLY.

local target = "client" -- CHANGE THIS TO 'server' OR 'client' OR NEITHER TO NOT SEND
local message_names = {"test1", "test2", "test3", "test4"}

if SERVER then
    GNIL.Net.AddNetworkStrings(unpack(message_names))
end

local function netReport(name, args)
    GNIL.log("Recieved net message '" .. name .."'", "success")
    for i = 1, #args do GNIL.log(args[i]) end

    GNIL.log({
        net.ReadString(),
        net.ReadBool()
    })
end

for _, v in ipairs(message_names) do
    GNIL.Net.Receive(v, function(...) netReport(v, {...}) end)
end

local function sendEm()
    for _, v in ipairs(message_names) do

        GNIL.Net.NetworkMessage:New(v)
            :WriteString("Hello there " .. v)
            :WriteBool(v == "test2")
        :Send(me)
        GNIL.log("Sent message '" .. v .. "'")
        
    end
end

if target == "server" and CLIENT then
    sendEm()
elseif target == "client" and SERVER then
    sendEm()
else
    GNIL.log("Invalid realm for given target.")
end

/*


local 📩 = 🌐.🛠️("test")

📩:✏️📄("This is the future of GMod Networking") -- string
📩:✏️🎨(me:GetColor()) -- color
📩:✏️📐(me:EyeAngles()) -- angle
📩:✏️📍(me:GetPos()) -- vector

📩:✉️🖥️() -- send the message to the server


*/