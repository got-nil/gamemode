TODO: Documentation, Middleware

**WARNING**: Currently this implementation does not have any builtin authentication. Eventually there will be, but it needs to be implemented directly on the webproxy instead of here to prevent invalid/unauthenticated requests from even reaching the garrysmod server. Until then (which will probably be when we actually try to use this module in a production environment), **all routes are unauthenticated. The proxy itself should provide authentication.**

This module requires an upstream service to act as HTTP termination.
The game server connects to this via websocket.

