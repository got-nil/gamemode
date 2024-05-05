MODULE.name = "UI"
MODULE.author = "gnil"
MODULE.description = "Shared UI tools."

GNIL.UI = GNIL.UI or {}
MODULE.OnLoad = function()
    MODULE:IncludeDirectory("lib")
    MODULE:IncludeDirectory("comp")
end