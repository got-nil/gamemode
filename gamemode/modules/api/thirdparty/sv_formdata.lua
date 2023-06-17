
-- Parse multipart form data.
-- https://gist.github.com/lunaboards-dev/deea68b29da7b98e0c9222850486ce1e

return function(body, ctype)
    --Find boundry
    local s, e = ctype:find("boundary=.+")
    local boundry = "--"..ctype:sub(s, e):gsub("boundary=", ""):gsub(";", ""):gsub("%-", "%-")
    s, e = body:find(boundry.."\r\n")
    local t = {}
    local eor_reached = false
    while (not eor_reached and s ~= nil) do
        local ss, se = string.find(body, boundry, e)
        se = se+2
        if (body:sub(se-1,se) == "--") then
            eor_reached = true
        end
        --Search for content disposition header
        local cont_disp = body:match("Content%-Disposition:.-\r\n", e-1):sub(33):gsub("[\r\n]+.+", "")
        local cont_type = body:match("Content%-Type:.-\r\n", e-1)
        --This tells if we have a file
        if (cont_type ~= nil) then
            cont_type = cont_type:sub(15, -3)
        end
        --Basically just find this and remove it, help the parser out.
        local sm = cont_disp:find(";")
        if (sm ~= nil) then
            cont_disp = cont_disp:sub(1,sm-1)..cont_disp:sub(sm+1)
        end
        --Find the end of Content-Disposition. Could have done this better, in case it sends headers.
        local _, cont_end = body:find("Content%-Disposition:.-\r\n\r\n", e-1)
        local ct = {}
        --Find a key/value pair
        local cs, ce = cont_disp:find(".-=\".-\"")
        while (cs) do
            --Get our pair.
            local cb = cont_disp:sub(cs, ce)
            --Find the key
            local cd_key = cb:match(".-=\""):sub(1, -3)
            --Find the value
            local cd_value = cb:match("=\".-\""):sub(3, -2)
            --Store
            ct[cd_key] = cd_value
            --Find the next one
            cs, ce = cont_disp:find(".-=\".-\"", ce)
            --But it's not super accurate.
            if (cs ~= nil) then cs = cs + 2 end
        end
        --Do we have a file?
        if (ct.filename ~= nil) then
            --Yes, add it like so
            t[ct.name] = {
                data = body:sub(cont_end+1, ss-3),
                headers = ct,
                mime = cont_type
            }
        else
            --No. Just add the data.
            t[ct.name] = body:sub(cont_end+1, ss-3);
        end
        s, e = ss, se
    end
    return t
end