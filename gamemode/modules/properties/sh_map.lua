-- Binary search algo

local function generateCoordSet(start_pos, width, amount, is_row)
    local set = {}
    for i = 1, amount do
        set[i] = (is_row && start_pos.x || start_pos.y) + (width * i)
    end
    return set
end

function GNIL.Properties.Generate(v1, v2)
    
    -- Search top row (left to right) to find the correct column.
    -- Afterwards, search column to find correct row.
    local width = (v2.x - v1.x) / GNIL.Properties["_resolution"]
    
    -- Precache generated map rows and columns. Only the track set is kept.
    GNIL.Properties["_map"] = {
        sets = {
            row = generateCoordSet(v1, width, GNIL.Properties["_resolution"], true),
            col = generateCoordSet(v1, width, GNIL.Properties["_resolution"], false)
        },
        max = {
            x = v2.x,
            y = v2.y
        },
        width = width
    }
end

hook.Add("InitPostEntity", "GNIL.LoadPropertiesMap", function()
    local map_v1, map_v2 = game.GetWorld():GetModelBounds()
    GNIL.Properties.Generate(map_v1, map_v2)
    GNIL.log("Generated properties map data")
end)
