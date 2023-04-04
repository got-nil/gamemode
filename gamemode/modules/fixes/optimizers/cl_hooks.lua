GNIL.Fixes["_originalHooks"] = GNIL.Fixes["_originalHooks"] or {}
local hooks = {
    
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
        local hooks = hook.GetTable()
        for _, v in ipairs(hooks) do
            if not hooks[v[1]] then continue end
            if not hooks[v[1]][v[2]] then continue end

            if not GILL.Optimizer["_originalHooks"][v[1]] then
                GILL.Optimizer["_originalHooks"][v[1]] = {}
            end
            if not GNIL.Fixes["_originalHooks"][v[1]][v[2]] then
                GNIL.Fixes["_originalHooks"][v[1]][v[2]] = hooks[v[1]][v[2]]
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