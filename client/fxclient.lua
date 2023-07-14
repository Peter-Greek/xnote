-- CFG --
local usePGXFramework = false
-- END --

local pIndex = 0
local awaits = {}
local lookedPlayers = {}
local hasDeathNote = false
local curNames = {}
local cur_action = false
local sin, cos, atan2, abs, rad, deg, _at, _pi, _t, _fl, _ci = math.sin, math.cos, math.atan2, math.abs, math.rad, math.deg, math.atan, math.pi, type, math.floor, math.ceil
local vec3, vec4 = vector3, vector4
local _sin, _cos, _abs = math.sin, math.cos, math.abs
local function RotationToDirection(rot)
	local rotZ = rad(rot.z)
	local rotX = rad(rot.x)
	local cosOfRotX = abs(cos(rotX))
	return vec3(-sin(rotZ) * cosOfRotX, cos(rotZ) * cosOfRotX, sin(rotX))
end
local function GetHeadingFromVectors(v1, v2)
	local dX = (v2.x - v1.x)
	local dY = (v2.y - v1.y)
	local heading = _at(dY, dX) * (180/_pi)
	return heading < 0 and 360 + heading or heading
end
local function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={} ; local i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end

	return t
end

local function display(state)
	SetNuiFocus(state, state)
	SendNUIMessage({type = 'display', state = state})

	print('sending resName')
	SendNUIMessage({type = 'setroot', res = GetCurrentResourceName(), data = {res = GetCurrentResourceName()}})

	cur_action = state
end

RegisterCommand("xnote:display", function(source, args, raw)
	if hasDeathNote then
		if not args[1] then
			display(not cur_action)
		end
	else
		if cur_action then
			display(not cur_action)
		end
	end
end)

RegisterNUICallback("exit", function(data)
	display(false)
end)


if not usePGXFramework then
	RegisterNetEvent("xnote:sendPlayer", function(id, data)
		if id and awaits[id] then
			awaits[id]:resolve(data)
			awaits[id] = nil
		end
	end)
end

RegisterNUICallback("setText", function(data)
	if data and data.str then
		local arr = split(data.str, "\n");
		for i = 1, #arr do
			local s = arr[i]
			print("new str", s)
			local isNum = tonumber(s)
			if isNum then
				if lookedPlayers[isNum] then
					if usePGXFramework then
						PGX.TriggerServerCallback("PGX:getPlayer", function(char)
							if char then
								if not curNames[isNum] then
									TriggerServerEvent("xnote:kill", isNum)
									curNames[isNum] = true
								end
							end
						end, isNum)
					else
						pIndex = pIndex + 1
						local thisIndex = pIndex
						awaits[thisIndex] = promise:new()
						TriggerServerEvent("PGX:getPlayer", thisIndex, isNum)
						local done = Citizen.Await(awaits[thisIndex])
						if done and done.char and done.SVID and done.SVID == isNum then
							if not curNames[isNum] then
								Citizen.SetTimeout(5000, function()
									TriggerServerEvent("xnote:kill", isNum)
								end)
								curNames[isNum] = true
							end
						end
					end
				else
					print("NOT SEEN YET 1")
				end
			else
				if usePGXFramework then
					PGX.TriggerServerCallback("PGX:getPlayer", function(char)
						if char then
							if lookedPlayers[char.SVID] then
								if not curNames[char.SVID] then
									TriggerServerEvent("xnote:kill", char.SVID)
									curNames[char.SVID] = true
								end
							else
								print("NOT SEEN YET 2")
							end
						end
					end, s)
				else
					pIndex = pIndex + 1
					local thisIndex = pIndex
					awaits[thisIndex] = promise:new()
					TriggerServerEvent("PGX:getPlayer", thisIndex, s)
					local done = Citizen.Await(awaits[thisIndex])
					if done and done.SVID then
						if lookedPlayers[done.SVID] then
							if not curNames[done.SVID] then
								Citizen.SetTimeout(5000, function()
									TriggerServerEvent("xnote:kill", done.SVID)
								end)
								curNames[done.SVID] = true
							end
						else
							print("NOT SEEN YET 2")
						end
					end
				end
			end
		end
	end
end)

RegisterNetEvent("xnote:hasBook")
AddEventHandler("xnote:hasBook", function()
	hasDeathNote = not hasDeathNote

	if not hasDeathNote and cur_action then
		display(false)
	end
end)

RegisterNetEvent("xnote:killSelf")
AddEventHandler("xnote:killSelf", function(killer)
	local myPed = PlayerPedId()
	if not LocalPlayer.state.isDead and not IsPedDeadOrDying(myPed) then -- ped not already dead (you can add your own extra logic here)
		SetEntityHealth(myPed, 0)

		-- add your own notifications here
		--PGX.Notify("error", "You have been killed by a death note, someone has written your name down!")
		print("KILLER", killer)
	end
end)

Citizen.CreateThread(function()
	local me = GetPlayerServerId(PlayerId())
	while true do
		Citizen.Wait(10)
		if hasDeathNote then
			local myPed = PlayerPedId()
			local myCoords = GetEntityCoords(myPed, false)
			for _,ply in pairs(GetActivePlayers()) do
				local oPed = GetPlayerPed(ply)
				local oCoords = GetEntityCoords(oPed, false)
				local sId = GetPlayerServerId(ply)

				local dist = #(myCoords - oCoords)
				if sId ~= me and not lookedPlayers[sId] and dist < 200 then
					if NetworkIsPlayerActive(ply)  then
						local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(myCoords.x, myCoords.y, myCoords.z, oCoords.x, oCoords.y, oCoords.z, -1, myPed, 0))
						if b then
							local exi = DoesEntityExist(e)
							local ty = GetEntityType(e)
							if e and ty == 1 and exi then
								if e == oPed then
									lookedPlayers[#lookedPlayers+1] = sId
								end
							end
						end
					end
				end
			end
		else
			Citizen.Wait(1000)
		end
	end
end)






