GNIL.Fixes["_originalConvars"] = GNIL.Fixes["_originalConvars"] or {}
local convarStates = {

    ["async_mode"] = 0,
    ["snd_mix_async"] = 1,
    ["mat_queue_mode"] = 2,
    ["gmod_mcore_test"] = 1,
    ["spawnicon_queue"] = 1,
    ["studio_queue_mode"] = 1,
    ["snd_async_fullyasync"] = 1,
    ["M9KGasEffect"] = 0,
    ["g_ragdoll_fadespeed"] = 200,
    ["tf_particles_disable_weather"] = 1,
    ["prop_active_gib_limit"] = 0,

    ["mod_load_mesh_async"] = 1,
    ["mod_load_anims_async"] = 1,
    ["mod_load_vcollide_async"] = 1,

    ["cl_threaded_bone_setup"] = 1,
    ["cl_threaded_client_leaf_system"] = 1,
    ["cl_forcepreload"] = 1,
    ["cl_detaildist"] = 0,
    ["cl_detailfade"] = 0,
    ["cl_drawmonitors"] = 1,
    ["cl_ejectbrass"] = 0,
    ["cl_playerspraydisable"] = 1,

    ["net_queued_packet_thread"] = 1,
    ["net_splitpacket_maxrate"] = 2097152,
    ["net_udp_recvbuf"] = 131072,
    ["net_maxroutable"] = 1260,
    ["net_maxfragments"] = 1792,
    ["net_compresspackets"] = 1,
    ["net_compresspackets_minsize"] = 25000,

    ["r_threaded_renderables"] = 1,
    ["r_threaded_particles"] = 1,
    ["r_decal_cullsize"] = 15,
    ["r_decalstaticprops"] = 0,
    ["r_dynamic"] = 0,
    ["r_drawflecks"] = 0,
    ["r_drawdetailprops"] = 0,
    ["r_drawmodeldecals"] = 0,
    ["r_forcewaterleaf"] = 1,
    ["r_lightaverage"] = 0,
    ["r_maxnewsamples"] = 2,
    ["r_propsmaxdist"] = 0,
    ["r_renderoverlayfragment"] = 0,
    ["r_waterdrawreflection"] = 0,
    ["r_waterdrawrefraction"] = 1,
    ["r_waterforceexpensive"] = 0,
    ["r_waterforcereflectentities"] = 0,
    ["r_shadowrendertotexture"] = 1,
    ["r_staticprop_lod"] = 4,
    ["r_maxsampledist"] = 1,
    ["r_flex"] = 0,
    ["r_shadows"] = 1,
    ["r_3dsky"] = 1,
    ["r_lod"] = 0,
    ["r_spray_lifetime"] = 0,
    ["r_fastzreject"] = 1,
    ["r_queued_ropes"] = 1,
    ["r_queued_decals"] = 1,
    ["r_threaded_particles"] = 1,
    ["r_threaded_renderables"] = 1,
    ["r_queued_post_processing"] = 1,
    ["r_threaded_client_shadow_manager"] = 1,
    ["r_dynamic"] = 0,
    ["r_dynamiclighting"] = 0,
    ["r_decals"] = 25,

    ["rope_averagelight"] = 0,
    ["rope_collide"] = 0,
    ["rope_rendersolid"] = 0,
    ["rope_shake"] = 0,
    ["rope_smooth"] = 0,
    ["rope_subdiv"] = 0,
    ["rope_wind_dist"] = 0,

    ["mat_forcehardwaresync"] = 0,
    ["mat_filterlightmaps"] = 1,
    ["mat_filtertextures"] = 1,
    ["mat_motion_blur_enabled"] = 0,
    ["mat_shadowstate"] = 1,
    ["mat_colorcorrection"] = 0,
    ["mat_disable_bloom"] = 1,
    ["mat_disable_fancy_blending"] = 1,
    ["mat_disable_lightwarp"] = 1,
    ["mat_envmapsize"] = 8,
    ["mat_reduceparticles"] = 1
    
}

return {
    name = "convars",
    enable = function()
        local ply = LocalPlayer()
        for k, v in pairs(convarStates) do
            if k == "gmod_mcore_test" and system.IsOSX() then continue end

            -- Cache the convar original state before setting it.
            if not GNIL.Fixes["_originalConvars"][k] then
                local var = GetConVar(k)
                if var == nil then continue end
                GNIL.Fixes["_originalConvars"][k] = var:GetInt()
            end
            ply:ConCommand(k .. " " .. v)
        end
    end,
    disable = function()
        local ply = LocalPlayer()
        for k, v in pairs(GNIL.Fixes["_originalConvars"]) do
            ply:ConCommand(k .. " " .. v)
        end
        GNIL.Fixes["_originalConvars"] = {}
    end
}