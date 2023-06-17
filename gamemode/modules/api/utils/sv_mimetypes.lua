GNIL.API.Mimetypes = GNIL.API.Mimetypes or {
    ["_parsed"] = false
}

-- These are all recognised/supported file mimetypes. Format:
--  mimetype extension ...(additional extensions seperated by spaces)... 
local mimetypes = [[
# Audio
audio/midi mid midi kar
audio/mp4 aac f4a f4b m4a
audio/mpeg mp3
audio/ogg oga ogg opus
audio/x-realaudio ra
audio/x-wav wav

# Images
image/bmp bmp
image/gif gif
image/jpeg jpeg jpg
image/png png
image/svg+xml svg svgz
image/tiff tif tiff
image/vnd.wap.wbmp wbmp
image/webp webp
image/x-icon ico cur
image/x-jng jng

# JavaScript
application/javascript js
application/json json

# Manifest files
application/x-web-app-manifest+json webapp
text/cache-manifest manifest appcache

# Microsoft Office
application/msword doc
application/vnd.ms-excel xls
application/vnd.ms-powerpoint ppt
application/vnd.openxmlformats-officedocument.wordprocessingml.document docx
application/vnd.openxmlformats-officedocument.spreadsheetml.sheet xlsx
application/vnd.openxmlformats-officedocument.presentationml.presentation pptx

# Video
video/3gpp 3gpp 3gp
video/mp4 mp4 m4v f4v f4p
video/mpeg mpeg mpg
video/ogg ogv
video/quicktime mov
video/webm webm
video/x-flv flv
video/x-mng mng
video/x-ms-asf asx asf
video/x-ms-wmv wmv
video/x-msvideo avi

# Web feeds
application/xml atom rdf rss xml
application/xslt+xml xsl

# Web fonts
application/font-woff woff
application/font-woff2 woff2
application/vnd.ms-fontobject eot
application/x-font-ttf ttc ttf
font/opentype otf

# Other
application/java-archive jar war ear
application/mac-binhex40 hqx
application/pdf pdf
application/postscript ps eps ai
application/rtf rtf
application/vnd.wap.wmlc wmlc
application/xhtml+xml xhtml
application/vnd.google-earth.kml+xml kml
application/vnd.google-earth.kmz kmz
application/x-7z-compressed 7z
application/x-chrome-extension crx
application/x-opera-extension oex
application/x-xpinstall xpi
application/x-cocoa cco
application/x-java-archive-diff jardiff
application/x-java-jnlp-file jnlp
application/x-makeself run
application/x-perl pl pm
application/x-pilot prc pdb
application/x-rar-compressed rar
application/x-redhat-package-manager rpm
application/x-sea sea
application/x-shockwave-flash swf
application/x-stuffit sit
application/x-tcl tcl tk
application/x-x509-ca-cert der pem crt
application/x-bittorrent torrent
application/zip zip
application/octet-stream bin exe dll
application/octet-stream deb
application/octet-stream dmg
application/octet-stream iso img
application/octet-stream msi msp msm
application/octet-stream safariextz
text/css css
text/html html htm shtml
text/mathml mml
text/plain txt
text/vnd.sun.j2me.app-descriptor jad
text/vnd.wap.wml wml
text/vtt vtt
text/x-component htc
text/x-vcard vcf

# Lua is not officially supported, this is the unofficial type
application/x-lua lua  
]]

-- Parse mimetypes
function GNIL.API.Mimetypes.Parse(mimetypes)
    local out_mimetypes, out_extensions = {}, {}

    for line in string.gmatch(mimetypes, "[^\n\r]+") do
        if line[1] == "#" then continue end
        local parts = string.Explode(" ", line)
        
        -- A mimetype can have multiple extensions, simply anything
        -- past the first index (the mimetype) is an extension.
        local extensions = {}
        for i = 1, #parts - 1 do
            extensions[i] = parts[i+1]
        end
        out_mimetypes[parts[1]] = extensions
        
        -- Reverse map the mimetype to all found extensions for pre-cached
        -- reverse searching (finding mime by extension).
        for _, v in ipairs(extensions) do
            out_extensions[v] = parts[1]
        end
    end

    return out_mimetypes, out_extensions
end

-- Getters for cached mimetypes.
function GNIL.API.Mimetypes.GetExtensions(mimetype) return GNIL.API.Mimetypes["_mime"][extension] end
function GNIL.API.Mimetypes.GetExtension(mimetype) return GNIL.API.Mimetypes["_mime"][extension] != nil && GNIL.API.Mimetypes["_mime"][extension][1] || nil end
function GNIL.API.Mimetypes.GetMimetype(extension) return GNIL.API.Mimetypes["_exts"][extension] end

-- If the mimetypes text has not yet been parsed, do so now.
if not GNIL.API.Mimetypes["_parsed"] then
    local parsed_mimetypes, parsed_extensions = GNIL.API.Mimetypes.Parse(mimetypes)
    
    -- Cache parsed mimetypes.
    GNIL.API.Mimetypes["_mime"] = parsed_mimetypes
    GNIL.API.Mimetypes["_exts"] = parsed_extensions
end