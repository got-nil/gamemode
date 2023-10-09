GNIL.Database = GNIL.Database or {
    ["_tables"] = {},
    ["_db"] = false,
    ["_modules_loaded"] = false
}

-- Create missing tables defined by the modules.
local function createAllTables()
    for table_name, table_data in pairs(GNIL.Database["_tables"]) do

        -- Create the table create query and add all table keys.
        local query = GNIL.Database["_db"]:Create(table_name)
        for k, v in pairs(table_data) do
            if k:sub(1, 1) == "_" then continue end
            query:Create(k, v)
        end

        -- If there is a _primary_key attribute in the table we
        -- should apply it to the create query.
        if table_data["_primary_key"] then
            query:PrimaryKey(table_data["_primary_key"])
        end

        -- Execute the table create.
        query:Execute()
    end
end

-- Allow the table to be called to return the database object.
setmetatable(GNIL.Database, {
    __call = function() return GNIL.Database["_db"] end,
})

-- If there isn't a stored database attempt to start connection.
if not GNIL.Database["_db"] then
    local conf, db = GNIL.Config("database"), GNIL.Thirdparty.mysql

    db.OnConnectionFailed = function(_, errorText)
        GNIL.log("Failed to connect to the database with error: " .. errorText, "error")
        hook.Run("GNIL.Database.ConnectionFailed", db, errorText)
    end
    db.OnConnected = function()
        GNIL.log("Successfully connected to database!", "debug")
        hook.Run("GNIL.Database.Connected", db)
        if GNIL.Database["_modules_loaded"] then
            createAllTables()
        end
    end

    -- Attempt connection with configured credentials.
    db:SetModule(conf:Get("driver", "sqlite"))
    db:Connect(
        conf:Get("host", "localhost"),
        conf:Get("username"),
        conf:Get("password"),
        conf:Get("database"),
        conf:Get("port", 3306)
    )

    -- Cache the created database object.
    GNIL.log("Connecting to database...", "debug")
    GNIL.Database["_db"] = db
end

-- When all modules have been loaded, attempt to create all the tables
-- defined within the modules. If the database is not yet connected by
-- this time then the database OnConnected will create the tables instead.
hook.Add("GNIL.Modules.LoadedAll", "gnil_database_modules_loadedall", function()
    if GNIL.Database["_db"]:IsConnected() then
        createAllTables()
    else
        GNIL.Database["_modules_loaded"] = true
    end
end)

-- Collect any database tables info from modules.
hook.Add("GNIL.Modules.Init", "gnil_database_modules_init", function(name, init)
    if not init.database then return end

    -- Ensure the database table is formatted correctly.
    local isvalid, out = GNIL.Validation.Structure(init.database, {
        tables = {{}, TYPE_TABLE, true},
        required = {true, TYPE_BOOL, false}
    })
    if not isvalid then
        init:log("Invalid provided database structure, with error: '" .. out .. "'", "warning")
        return false
    end

    -- Copy the tables structure to be created later.
    for k, v in pairs(out.tables) do

        -- Key should be table name, value should be the table headers.
        if not (isstring(k) and istable(v) and (not table.IsSequential(v))) then
            init:log("Invalid provided database structure for table '" .. tostring(k) .. "'!", "warning")
            return false
        end

        GNIL.Database["_tables"][k] = v
    end
end)