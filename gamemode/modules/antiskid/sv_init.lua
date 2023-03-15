local MODULE = MODULE

MODULE.name = "AntiSkid"
MODULE.description = "Filter out the really stupid skiddies."
MODULE.author = "morgverd"

-- This module relies heavily on the networking module, so that
-- must be loaded before the other files!
MODULE:Require("net")

GNIL.AntiSkid = GNIL.AntiSkid or {
    ["_message_name"] = GNIL.Utils.Random(math.random(18, 24)),
    ["_checks"] = {},
    ["_waiting_for"] = {}
}

-- Once all the utilities etc have been loaded, we should load the
-- actual detection checks. The file could return a SkidCheck instance
-- and if it does, it should be automatically registered as a check.
function MODULE:OnLoadFinished()
    MODULE:log("Finished loading utilities, loading detection files.", "debug")

    local files, _ = MODULE:Find("detections/*.lua")
    for _, v in pairs(files) do
        
        -- Include the detection and register the check if it returns one.
        -- ALL DETECTION FILES ARE LOADED SERVERSIDE ONLY!!
        local out = GNIL.Utils.Include(MODULE:ResolvePath("detections/" .. v), "sv")
        if out and out.class and out.class.name == "SkidCheck" then
            MODULE:log("Skid Detection file '" .. v .. "' returns a SkidCheck '" .. out.name .. "', auto-registering.", "debug")
            GNIL.AntiSkid.AddCheck(out)
        else
            MODULE:log("Included Skid Detection file '" .. v .. "'", "debug")
        end
    end
end