-- https://github.com/CFC-Servers/cfc_detached_timer/blob/main/lua/includes/modules/cfc_detached_timer.lua
-- Used for startup timers, where CurTime timers are too inaccurate.

local dTimer = dTimer or {
    timers = {},
    idCounter = 0
}

function dTimer.GetCurTime()
    return SysTime()
end

function dTimer.Create( id, delay, reps, f )
    dTimer.timers[id] = { id = id, delay = delay, reps = reps, func = f, lastCall = dTimer.GetCurTime() }
end

function dTimer.Adjust( id, delay, reps, f )
    local curTimer = dTimer.timers[id]
    if not curTimer then return false end

    curTimer.delay = delay or curTimer.delay
    curTimer.reps = reps or curTimer.reps
    curTimer.func = f or curTimer.f
    return true
end

function dTimer.Exists( id )
    return tobool( dTimer.timers[id] )
end

function dTimer.Remove( id )
    dTimer.timers[id] = nil
end

function dTimer.RepsLeft( id )
    return dTimer.timers[id] and dTimer.timers[id].reps or -1
end

function dTimer.TimeLeft( id )
    local curTimer = dTimer.timers[id]
    if not curTimer then return end

    return curTimer.delay - ( dTimer.GetCurTime() - curTimer.lastCall )
end

function dTimer.Simple( delay, f )
    dTimer.Create( "SimpleTimer" .. dTimer.idCounter, delay, 1, f )
    dTimer.idCounter = dTimer.idCounter + 1
end

function dTimer.Pause( id )
    local curTimer = dTimer.timers[id]
    if not curTimer or curTimer.pauseTime then return false end

    curTimer.pauseTime = dTimer.GetCurTime()
    return true
end

function dTimer.Stop( id )
    local curTimer = dTimer.timers[id]
    if not curTimer or curTimer.pauseTime then return false end

    curTimer.pauseTime = curTimer.lastCall
    return true
end

function dTimer.Start( id )
    local curTimer = dTimer.timers[id]
    if not curTimer or not curTimer.pauseTime then return false end

    curTimer.lastCall = dTimer.GetCurTime() - ( curTimer.pauseTime - curTimer.lastCall )
    curTimer.pauseTime = nil
    return true
end
dTimer.UnPause = dTimer.Start

hook.Add( "Think", "DetatchedTimer_HandleTimers", function()
    local time = dTimer.GetCurTime()
    for id, curTimer in pairs( dTimer.timers ) do
        if curTimer.pauseTime then continue end

        local delayPassed = time - curTimer.lastCall > curTimer.delay

        if not delayPassed then continue end

        curTimer.lastCall = time

        local hasReps = curTimer.reps > 0

        if hasReps then
            curTimer.reps = curTimer.reps - 1
            if curTimer.reps == 0 then
                dTimer.Remove( id )
            end
        end

        curTimer.func()
    end
end)

return dTimer