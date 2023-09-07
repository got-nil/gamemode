local MODULE = MODULE
GNIL.Commands.DiscoveredCommands = GNIL.Commands.DiscoveredCommands or {}

-- Cache the hashed plaintext result so I can at least
-- pretend that this isn't terribly inefficient.
cachedHashes = {}
local function hashCache(text)
    if not cachedHashes[text] then
        cachedHashes[text] = util.SHA256(text)
    end
    return cachedHashes[text]
end

-- Every 30 seconds reset the hash cache to prevent it
-- from becoming too large from repeative use.
timer.Create("gnil_hash_cache_reset", 30, 0, function()
    cachedHashes = {}
end)

-- "Discover" a command by checking if the provided plaintext
-- is a registered hashed command string.
function GNIL.Commands.Discover(plaintext)
    if GNIL.Commands.DiscoveredCommands[plaintext] then return end

    local hash = hashCache(plaintext)
    if GNIL.Commands["_r"][hash] then
        MODULE:log("Discovered concommand '" .. plaintext .. "' (" .. hash .. ")", "debug")
        GNIL.Commands.DiscoveredCommands[plaintext] = hash
    end
end

-- Reverse lookup commands registry. The command must've been
-- discovered before running this (which it should've been to get here).
function GNIL.Commands.GetCommandArgumentsByPlaintext(plaintext)
    if not GNIL.Commands.DiscoveredCommands[plaintext] then return end
    return GNIL.Commands["_r"][GNIL.Commands.DiscoveredCommands[plaintext]]
end

-- Called when the concommand is actually sent.
function GNIL.Commands.Process(ply, _, args, argstr)
    if GNIL.Commands["_r"] == nil then MODULE:log("The server has not yet sent a command manifest.", "error") return end

    if #args == 0 then
        GNIL.Commands.print_logo()

        local lines = {
            "GotNil is a GarrysMod development group started by a group of friends that wanted to make something cool.",
            "Commands will autocomplete once they've been 'discovered', however some commands may just default to being public.",
            "Some commands may not work in chat, however all commands that work in chat will work in console.\n"
        }
        for k, v in ipairs(lines) do Msg(v .. "\n") end

        -- If the user has discovered commands, we should show them here.
        if #table.GetKeys(GNIL.Commands.DiscoveredCommands) > 0 then
            Msg("Here are the commands you've discovered:\n")
            for name, _ in pairs(GNIL.Commands.DiscoveredCommands) do
                MsgC(GNIL.Commands.logo_color, "    gnil " .. name)

                -- If the discovered command has arguments, display them here.
                args = GNIL.Commands.GetCommandArgumentsByPlaintext(name)
                if args then
                    MsgC(GNIL.Commands.logo_color, " " .. GNIL.Commands.Arguments.GetArgumentsPreview(args))
                end

                Msg("\n")
            end
            Msg("\n")
        end

        Msg("Finally, while you're here, enjoy some credits:\n")
        for _, v in ipairs(GNIL._CREDITS) do
            MsgC(GNIL.Commands.logo_color, "    [" .. v["name"] .. "]")
            Msg(" -> " .. v["title"] .. "\n")
        end
        return
    end

    -- If we get here, the user is actually sending a command.
    -- Before sending to the server, we should ensure that the command they're
    -- attempting to send has been discovered and is defined by the client. This
    -- is easy to beat if you're one of professors script kiddie mates, but the
    -- actual validation takes place serverside, this is just to reduce net messages
    -- for commands that are obviously invalid.
    local c = GNIL.Commands.GetCommandArgumentsByPlaintext(args[1])
    if c == nil then MODULE:log("The command '" .. args[1] .. "' is unrecognised by the client.", "error") return end

    GNIL.Net.Create("module_commands_executed")
        :WriteString(argstr)
    :SendToServer()
end

-- Add the root gnil command and add both processors.
concommand.Add(
    "gnil",
    GNIL.Commands.Process,
    GNIL.Commands.Autocomplete.Process,
    "The GotNil core gamemode commands"
)