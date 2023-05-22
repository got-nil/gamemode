return {
    realm = "server",
    shared = {
        "driver"
    },
    config = {
            
        -- Possible drivers: sqlite, mysqloo
        driver = "sqlite",

        -- The following settings are only required when using the
        -- mysqloo connection. Ensure the host is the same as the
        -- MySQL user hostname (should be the server IP, not wildcard).
        host = "localhost",
        username = "username",
        password = "password",
        database = "database",
        port = 3306,

        test1 = "76561198301284223",
        test2 = "01234",
        test3 = {
            a = {
                b = {
                    c = "76561198301284223"
                }
            }
        }

    },

    -- Allows only certain players to 
    --  shared: Same as client.
    --  server: Limits which players should recieve shared attributes.
    --  client: Limits which players recieve the config file via net FileInclude.

    check = function(ply)
        return false
    end
}