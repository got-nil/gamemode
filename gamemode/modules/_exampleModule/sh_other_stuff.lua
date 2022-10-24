/*

    This file will be auto loaded after the init file has finished, as
    it is in the root module level (top level within the module directory)
    and it includes a realm prefix ("sh_") to specify that it should be
    sent to both the client and server.

    In this example module the init file is server only, meaning that the
    client will still execute this file however it will not run the init.

*/