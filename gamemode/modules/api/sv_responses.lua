GNIL.API.Responses = GNIL.API.Responses or {}

---@param body? any
---@param status_code? number
---@param headers? table
---@return API.Response
local function createResponse(body, status_code, headers)
    if status_code == nil then status_code = 200 end
    return GNIL.API.Response:New(status_code, body, headers)
end

---JSON response, can be either a table or string value.
---@param data table|string
---@param status_code? number
---@return API.Response
function GNIL.API.Responses.JSON(data, status_code)
    return createResponse(
        istable(data) && util.TableToJSON(data) || data, ---@diagnostic disable-line
        status_code,
        {
            ["Content-Type"] = "application/json"
        }
    )
end

---Plaintext response.
---@param text string
---@param status_code? number
---@return API.Response
function GNIL.API.Responses.Text(text, status_code)
    return createResponse(
        text,
        status_code,
        {
            ["Content-Type"] = "text/plain"
        }
    )
end

---Empty response (without body).
---@param status_code number
---@return API.Response
function GNIL.API.Responses.Empty(status_code)
    return createResponse(
        nil,
        status_code
    )
end

---File response with content headers.
---@param filepath string
---@param gamepath string
---@param status_code number
---@return API.Response
function GNIL.API.Responses.File(filepath, gamepath, status_code)
    local content = file.Read(filepath, gamepath)

    -- If the file does not exist, return a 500 error response
    -- as theres basically nothing else we can do with a nonexistant file.
    if content == nil then
        return createResponse(nil, 500)
    end

    -- Get the extension from the filepath.
    local parts = string.Explode(".", filepath)
    local extension = parts[#parts]

    -- Return the constructed response with file content.
    return createResponse(
        content,
        status_code or 200,
        {
            ["Content-Type"] = GNIL.API.Mimetypes.GetMimetype(extension) or "application/octet-stream",
            ["Content-Length"] = #content
        }
    )
end