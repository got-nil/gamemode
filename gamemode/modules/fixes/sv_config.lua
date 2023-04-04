local banned, nodamage, nocolide, nopickup = GNIL_FIXES_ENT_BANNED, GNIL_FIXES_ENT_NODAMAGE, GNIL_FIXES_ENT_NOCOLIDE, GNIL_FIXES_ENT_NOPICKUP
GNIL.Fixes.Config = {
    Entities = {

        ["light"] = {banned},
        ["light_spot"] = {banned},
        ["spotlight_end"] = {banned},
        ["beam"] = {banned},
        ["env_fire"] = {banned},
        ["trigger_hurt"] = {banned},
        ["point_spotlight"] = {banned},
        ["env_sprite"] = {banned},
        ["func_tracktrain"] = {banned},
        ["point_template"] = {banned},
        
        ["donation_box"] = {nodamage},
        ["gmod_winch_controller"] = {nodamage},
        ["gmod_button"] = {nodamage},
        ["gmod_balloon"] = {nodamage},
        ["gmod_cameraprop"] = {nodamage},
        ["gmod_emitter"] = {nodamage},
        ["gmod_light"] = {nodamage},
        ["keypad"] = {nodamage},
        ["gmod_poly"] = {nodamage},

        ["prop_fix"] = {nodamage, nocolide},
        ["prop_physics"] = {nodamage, nocolide},
        ["prop_dynamic"] = {nodamage, nocolide},
        ["ent_picture"] = {nodamage, nocolide},

        ["func_door"] = {nocolide},
        ["func_door_rotating"] = {nocolide},
        ["prop_door_rotating"] = {nocolide},
        ["spawned_food"] = {nocolide},
        ["func_movelinear"] = {nocolide},

        ["keypad"] = {nocolide, nopickup}

    }
}