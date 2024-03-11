return {
    realm = "server",
    config = {

        -- reload_type:
        --  'luarefresh' = If the server is using luarefresh.
        --  'vfs'        = Send a VFS to the client and reload the module (for development).

        client_refresh_modules = true,
        reload_type = "luarefresh"
    }
}