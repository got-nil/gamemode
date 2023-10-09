GNIL.Fixes["_originalHooks"] = GNIL.Fixes["_originalHooks"] or {}
local laggy_hooks = {

    {"Think", "DOFThink"},
    {"PlayerTick", "TickWidgets"},
    {"RenderScene", "RenderSuperDoF"},
    {"PostRender", "RenderFrameBlend"},
    {"PreRender", "PreRenderFrameBlend"},
    {"PostDrawEffects", "RenderWidgets"},
    {"RenderScene", "RenderStereoscopy"},
    {"GUIMouseReleased", "SuperDOFMouseUp"},
    {"GUIMousePressed", "SuperDOFMouseDown"},
    {"NeedsDepthPass", "NeedsDepthPass_Bokeh"},
    {"RenderScreenspaceEffects", "RenderBloom"},
    {"RenderScreenspaceEffects", "RenderBokeh"},
    {"RenderScreenspaceEffects", "RenderToyTown"},
    {"RenderScreenspaceEffects", "RenderSunbeams"},
    {"RenderScreenspaceEffects", "RenderMotionBlur"},
    {"PreventScreenClicks", "SuperDOFPreventClicks"}

}

return {
    name = "hooks",
    enable = function()
        local player_hooks = hook.GetTable()
        for _, v in ipairs(laggy_hooks) do
            if not player_hooks[v[1]] then continue end
            if not player_hooks[v[1]][v[2]] then continue end

            if not GNIL.Fixes["_originalHooks"][v[1]] then
                GNIL.Fixes["_originalHooks"][v[1]] = {}
            end
            if not GNIL.Fixes["_originalHooks"][v[1]][v[2]] then
                GNIL.Fixes["_originalHooks"][v[1]][v[2]] = player_hooks[v[1]][v[2]]
            end
            hook.Remove(v[1], v[2])
        end
    end,
    disable = function()
        for eventName, data in pairs(GNIL.Fixes["_originalHooks"]) do
            for identifier, func in pairs(data[eventName]) do
                hook.Add(eventName, identifier, func)
            end
        end
        GNIL.Fixes["_originalHooks"] = {}
    end
}