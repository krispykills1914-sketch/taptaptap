local Base = "https://raw.githubusercontent.com/krispykills1914-sketch/taptaptap/refs/heads/main/"
local function run(path)
    local ok, src = pcall(game.HttpGet, game, Base .. path)
    if not ok or type(src) ~= "string" or #src < 50 then
        error("[Tapology] failed to download " .. path .. ": " .. tostring(src))
    end
    local fn, err = loadstring(src, "@" .. path)
    if not fn then
        error("[Tapology] " .. path .. " compile failed: " .. tostring(err))
    end
    local ran, result = pcall(fn)
    if not ran then
        error("[Tapology] " .. path .. " failed: " .. tostring(result))
    end
end
run("modules.lua")
run("main.lua")
