
# GNIL Network Abstraction Layer
This module is just your standard NAL (Network Abstraction Layer). An interface to client server networking with some cool features such as write buffering, message queuing, reusable network messages and data chunking.

**Messages sent using the GNIL Net module must be recieved using the GNIL Net module. You cannot use standard `net.Start` with `GNIL.Net.Receive` and vice versa. However, you can use `net.Read...()` within a GNIL receiver.**

This documentation was created by morgverd, and therefore I've used the PHP format for type specification. As you will notice, arguments are formatted as `datatype argumentname`. If the datatype starts with a `?` such as `?string` then the argument is optional and can be `nil`. Some functions also specify their return value at the end, following the same format as arguments (with a colon seperator).

## Base Documentation
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `GNIL.Net.AddNetworkString(string string)` - Pool a message name before using it to send. <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `GNIL.Net.AddNetworkStrings(vararg strings)` - Same as above, but supports multiple string args. <br/>

![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `GNIL.Net.NetworkIDToString(int id): ?string` - Same usage as [util.NetworkIDToString](https://wiki.facepunch.com/gmod/util.AddNetworkString). <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `GNIL.Net.NetworkStringToID(string string): int` - Same usage as [util.NetworkStringToID](https://wiki.facepunch.com/gmod/util.NetworkStringToID). <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `GNIL.Net.Receive(string messageName, callable fn)` - Same usage as [net.Receive](https://wiki.facepunch.com/gmod/net.Receive). <br/>
![Client](https://cdn.morgverd.com/static/github/gmod/realms/client.png) `GNIL.Net.ReceiveChunked(string messageName, callable fn)` - See [chunking](#chunking) for more info. <br/>

![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `GNIL.Net.Create(string messageName, callable fn):` [NetworkMessage](#networkmessage). <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `GNIL.Net.Start(string messageName, ?boolean unreliable)` - Start/Open a stream with pooled name.  <br/>

![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) ![Internal](https://cdn.morgverd.com/static/github/gmod/realms/internal.png) `GNIL.Net._SyncNetworkIDs(?Entity ply)` - Sync the network ids between server and client. <br/>

The following functions accept a [NetworkMessage](#networkmessage) instance that will be used to start and write the message data. If the NetworkMessage is not provided, then an open stream should already be open (using `GNIL.Net.Start(messageName, unreliable)`.  <br/>

![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) `GNIL.Net.Send(Entity ply, ?NetworkMessage _nm, ?boolean _allowqueue)` - Send a netmessage. <br/>
![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) `GNIL.Net.Broadcast(?NetworkMessage _nm)` - Broadcast a netmessage to all connected players. <br/>


## <a name="networkmessage"></a>Network Message

A NetworkMessage instance is created using the `GNIL.Net.Create(messageName, fn)` constructor function (above). It allows for written data to be buffered, meaning that the network stream is not actually opened until the message is being sent.  This allows the NetworkMessage to be reusable across mutliple users which could be used for cache/optimisation.

**Buffer writters**, The following are the exact same as you would use with `net.Whatever()`. All the arguments are the exact same, so the [official documentation](https://wiki.facepunch.com/gmod/~search:net.Write) applies. Please note that **`net.WriteTable` DOES NOT EXIST**, as it promotes poor network design. **All writers return self, allowing for method chaining**.

![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteAngle(Angle angle)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteBit(boolean boolean)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteBool(boolean boolean)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteColor(table Color, boolean writeAlpha = true)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteData(string binary, int length)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteDouble(number double)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteEntity(Entity entity)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteFloat(number float)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteInt(number integer, number bitCount)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteMatrix(VMatrix matrix)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteString(string string)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteType(any ent)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteUInt(number unsignedInteger, number bitCount)` <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:WriteVector(Vector vector)` <br/>


**Internal stream control**, actually controls the write buffer of the net message. They're "internal" but can be used for advanced use, although note that flushes will not allow the netmessage to be reused without rewriting data.

![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) ![Internal](https://cdn.morgverd.com/static/github/gmod/realms/internal.png) `nm:_WriteToBuffer(table args, callable writer)` - Add a writer function with args to buffer. <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) ![Internal](https://cdn.morgverd.com/static/github/gmod/realms/internal.png) `nm:_FlushWriteBuffer()` - Clears the write buffer entirely. <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) ![Internal](https://cdn.morgverd.com/static/github/gmod/realms/internal.png) `nm:_WriteBufferToStream()` - Actually write the the buffered data into an open stream. <br/>
![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) ![Internal](https://cdn.morgverd.com/static/github/gmod/realms/internal.png) `nm:_WriteToStream()` - Open a network stream with message name and write stream. <br/>

**Standard Message Sending**, is obviously for when the message has finished being written to. Once its ready to send to players sending the messages is (almost entirely) the same as the [official documentation](https://wiki.facepunch.com/gmod/~search:net.Send).


![Shared](https://cdn.morgverd.com/static/github/gmod/realms/shared.png) `nm:Send(table|CRecipientFilter|Entity ply)` - When called from client this acts as `nm:SendToServer`. <br/>
![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) `nm:Broadcast()` - Broadcast the message to all connected players. <br/>
![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) `nm:SendPAS(Vector pos)` - Send to players in the same [Potentially Audible Set (PAS)](https://developer.valvesoftware.com/wiki/PAS) as the vector. <br/>
![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) `nm:SendPVS(Vector pos)` - Send to players in the same [PVS](https://developer.valvesoftware.com/wiki/PVS) (players that can see the vector). <br/>
![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) `nm:SendOmit(table|Entity ply)` - Send to all players, excluding the one(s) provided. <br/>
![Client](https://cdn.morgverd.com/static/github/gmod/realms/client.png) `nm:SendToServer()` - Send the message to the server. <br/>

The **Chunking interface**  allows for buffered write data to be sent [chunked](#chunking). **This requires all buffered write data to be written using `WriteData`**.

![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) `nm:SendChunked(Entity ply, ?boolean verify_checksum, ?callable fn)`

## Sending and Receiving a net message
When sending a net message, there are two different approaches you can take depending on your choice of style and feature requirements.

### Direct Interface
If you really want to (for example if you're porting existing code that already uses the base net functions) you can use the net module's direct function set instead of interfacing with OOP. Doing so is pretty much the same as using the standard net lib.

Below is an example of pre-existing code using the base net functions.
```lua
if SERVER then
    net.AddNetworkString("whatever")
    
    net.Start("whatever")
        net.WriteString("hello")
        net.WriteBool(false)
    net.Send(me)

else
    net.Recieve("whatever", function(len)
        local str = net.ReadString()
        local bool = net.ReadBool()
    end)
end
```

And here is the same code, but using the GNIL net module.
```lua
if SERVER then
    GNIL.Net.AddNetworkString("whatever")
    
    GNIL.Net.Start("whatever") -- Use the GNIL Net Start (to insert header)
        net.WriteString("hello") -- You can use the standard network writers here!
        net.WriteBool(false)
    GNIL.Net.Send(me) -- Use the GNIIL Net Send

else
    GNIL.Net.Recieve("whatever", function(len) -- Use the GNIL Reciever
        local str = net.ReadString() -- The exact same read functions too!
        local bool = net.ReadBool()
    end)
end
```

### OOP NetworkMessage
As outlined above, you can use the [NetworkMessage](#networkmessage) object to write data to a buffer and then send it as a standard message. Using the network message approach allows for the most flexability such as its reusability between clients and ability to send chunked data. 

The message instance is created using `GNIL.Net.Create(networkMessage)` where `networkMessage` is the pooled network string being targetted. From there, you can write data onto the instance using the writers (also documented above).

```lua
-- Since each writer returns the message instance
-- we can chain them together with a send at the end.
GNIL.Net.Create("test")
    :WriteString("Hello there")
    :WriteUInt(21, 5)
:SendToServer()
``` 

As mentioned, since all written data is buffered we can reuse the created NetworkMessage as much as we need to, which could prove useful for caching. Below is an example where we cache a leaderboard that is sent to all new players.

```lua
local leaderboardMessage = GNIL.Net.Create("leaderboard")
for ply, score in pairs(races.GetLeaderboard()) do
    leaderboardMessage:WriteEntity(ply) -- Write the player
    leaderboardMessage:WriteUInt(score, 8) -- Write their score (8 bits = 255 max)
end

-- Now that leaderboardMessage has been written to, we can reuse it for all players.
-- (Use PlayerNetLoad over PlayerInitialSpawn, see below for more info)
hook.Add("PlayerNetLoad", "gnil_send_leaderboard", function(ply)
    leaderboardMessage:Send(ply) -- Send the message to the player as normal
end)

```

## PlayerNetLoad
The network module also provides a useful **server hook** `PlayerNetLoad` which is called when a player has loaded into the server and is at a point where they're able to send and recieve network messages.

![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) ![Internal](https://cdn.morgverd.com/static/github/gmod/realms/internal.png) `GNIL.Net.HasPlayerNetLoaded(Entity|string plyOrSteamID)`

This function is used internally, however it can be useful to quickly check if a player supports networking yet without having to setup any hooks yourself.

Below is a little example incase you've gotten bored of reading text.
```lua
hook.Add("PlayerNetLoad", "gnil_whatever", function(ply)
    GNIL.log(ply:Nick() .. " can now recieve net messages!")
end)
```

## <a name="chunking"></a>Chunking
Chunking allows the server to send large amounts of data by compressing and then splitting the data into large "chunks" that are just below the maximum netmessage size. Each chunk is sent sequentially in order until the last chunk is sent, where the client then combines all the chunks recieved back into a single (or multiple) data strings.

When sending seperate data in the same chunk sequence, the data  is concatenated and split on the client side. For some cases (non UTF characters or alot of control characters, although control characters have been tested to work) it may be better to send each as its own chunked data instead of attempting to send together. (When doing this, ensure the client isn't overwhelmed with data by waiting for the previous chunked data to finish sending using its send callback)

![Server](https://cdn.morgverd.com/static/github/gmod/realms/server.png) `GNIL.Net.Chunks.Send(Entity ply, string messageName, string|table data, ?boolean verify_checksum, ?callable callback)`

**Chunked netmessages use the same messages as standard netmessages**, and therefore any message used to send chunked data must be pooled as normal using `GNIL.Net.AddNetworkString(messageName)`.

**Chunked messages cannot be recieved on the client with a standard net reciever**, instead the client must have a `GNIL.Net.ReceiveChunked(messageName, callback)` defined. If they do not the client will reply with an error after the first chunk has been sent to stop further data from being sent.

Below is an example of the server sending a "verylargefile" to the client. Since we want to execute the file, we opt in for checksum verification to ensure that all chunks were successfully  recieved. We also define a callback to be used once all chunks have been recieved.

**Please note:** The callback is only executed once the client sends back its "termination message" back to the server. This is done when there is an error, or all chunks have been successfully received. However, **malicious players could block the reply from being sent, so the callback should not be relied upon.**

```lua
GNIL.Net.AddNetworkString("execute_me") -- The message name must be pooled as normal

local me = player.GetBySteamID("STEAM_0:1:170509247")
local script = file.Read(".../verylargefile.lua", "LUA")

GNIL.Net.Chunks.Send(
    me, -- Target player
    "execute_me", -- Target message name
    script, -- Data to be chunked
    true, -- Should the output be checksum verified on client?
    function(success, output) -- Called once client recieves all chunks
        if not success then
            GNIL.log(output, "error") -- If unsuccessful, the output is the errormessage.
        end
    end
) 
```

On the client, we must have a chunked reciever to handle the data once it's all been sent. These are created similar to a standard net reciever, however unlike a standard reciever the data is provided as an argument to the callback.

```lua
GNIL.Net.ReceiveChunked("execute_me", function(data)
    
    -- The data recieved will either be a string or a table. This is the same
    -- as the provided data on the serverside function. In our example, we only
    -- sent one string and therefore the data argument will be a string.
    
    GNIL.Utils.Execute(data) -- Use the Execute utility to run the lua code
end)
```
