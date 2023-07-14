local function split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}; local i = 1;
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
local function GetPlayerDiscord(source)
	local _source = source
	for _, id in pairs(GetPlayerIdentifiers(_source)) do
		if string.match(id, "discord:") then
			return id
		end
	end
	return ""
end

local usePGXFramework = false
local allowEveryone = false
local allowList = {
	["discord:334018024283570187"] = true, -- peter
}

RegisterCommand("xnote:toggle", function(source, args, raw)
	if usePGXFramework then
		local player = PGX.GetPlayer(source)
		if player and player.source and player.discord and player.connected and player.char and allowList[player.discord] then
			TriggerClientEvent("xnote:hasBook", player.source)
		end
	else
		if source > 0 and (allowEveryone or allowList[GetPlayerDiscord(source)]) then
			TriggerClientEvent("xnote:hasBook", source)
		end
	end
end)

if usePGXFramework then
	PGX.RegisterServerCallback("PGX:getPlayer", function(source, cb, id)
		local xPlayer = PGX.GetPlayer(source)
		if not xPlayer or not xPlayer.connected or allowList[xPlayer.discord]  then
			cb(nil)
		end

		if type(id) == "string" then
			for i,k in pairs(PGX.GetPlayers()) do
				if k and k.char and k.char.firstname .. " " .. k.char.lastname == id then
					cb(k)
					return
				end
			end
		else
			if not id or type(id) ~= "number" or id < 1 then cb(nil) end
			cb(PGX.GetPlayer(id))
			return
		end
		cb(nil)
	end)
else
	local function GetPlayerCharName(svid)
		--todo !!!! IMPORTANT !!!!
		-- ADD YOUR FRAMEWORK OR NAME LOGIC HERE

		return GetPlayerName(svid)
	end

	RegisterNetEvent("PGX:getPlayer", function(index, id)
		local _source = source
		if not _source or type(_source) ~= "number" or _source < 1 then return false end
		local discord = GetPlayerDiscord(_source)
		if allowEveryone or allowList[discord] then
			if type(id) == "string" then
				local Players = GetPlayers()
				for i,k in pairs(Players) do
					local s = tonumber(k)
					local name = GetPlayerCharName(s)
					if name and name == id then
						local sl = split(name, " ")
						TriggerClientEvent("xnote:sendPlayer", _source, index, { char = { firstname = sl[1], lastname = sl[2] }, SVID = s })
						return
					end
				end
			else
				if not id or type(id) ~= "number" or id < 1 then return false end
				local name = GetPlayerCharName(id)
				if not name then return false end
				local sl = split(name, " ")
				TriggerClientEvent("xnote:sendPlayer", _source, index, { char = { firstname = sl[1], lastname = sl[2] }, SVID = id })
				return
			end
		end
		TriggerClientEvent("xnote:sendPlayer", _source, index, nil)
	end)
end

RegisterNetEvent("xnote:kill", function(svid)
	local _source = source
	if usePGXFramework then
		local xPlayer = PGX.GetPlayer(_source)
		if not xPlayer or not xPlayer.connected or allowList[xPlayer.discord]  then return false end
		local Other = PGX.GetPlayer(svid)
		if not Other or not Other.source or not Other.char or not Other.char.firstname or not Other.connected then return false end
		TriggerClientEvent("xnote:killSelf", Other.source, xPlayer.source)
	else
		local discord = GetPlayerDiscord(_source)
		if not discord or discord == "" then return false end
		if not svid or type(svid) ~= 'number' or svid < 1 then return false end
		local OtherDiscord = GetPlayerDiscord(svid)
		if not OtherDiscord or OtherDiscord == "" then return false end
		TriggerClientEvent("xnote:killSelf", svid, _source)
	end
end)
