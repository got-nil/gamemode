return {
    realm = "server",
    config = {
            
        -- Possible drivers: sqlite, mysqloo
        driver = "sqlite",

        -- The following settings are only required when using the
        -- mysqloo connection. Ensure the host is the same as the
        -- MySQL user hostname (should be the server IP, not wildcard).
        host = "localhost",
        username = "test",
        password = "password",
        database = "test",
        port = 3306
    }
}
