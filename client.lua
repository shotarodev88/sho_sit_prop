ESX = nil
local debugProps, sitting, lastPos, currentSitCoords, currentScenario = {}
local disableControls = false
local currentObj = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

if Config.Debug then
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			for i=1, #debugProps, 1 do
				local coords = GetEntityCoords(debugProps[i])
				local hash = GetEntityModel(debugProps[i])
				local id = coords.x .. coords.y .. coords.z
				local model = 'unknown'

				for i=1, #Config.Interactables, 1 do
					local seat = Config.Interactables[i]

					if hash == GetHashKey(seat) then
						model = seat
						break
					end
				end

				local text = ('ID: %s~n~Hash: %s~n~Model: %s'):format(id, hash, model)

				ESX.Game.Utils.DrawText3D({
					x = coords.x,
					y = coords.y,
					z = coords.z + 2.0
				}, text, 0.5)
			end

			if #debugProps == 0 then
				Citizen.Wait(500)
			end
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()

		if sitting and not IsPedUsingScenario(playerPed, currentScenario) then
			wakeup()
		end

		if IsControlJustPressed(0, 38) and IsControlPressed(0, 21) and IsInputDisabled(0) and IsPedOnFoot(playerPed) then
			if sitting then
				wakeup()
			end			
		end
	end
end)

Citizen.CreateThread(function()
	local Sitables = {}

	for k,v in pairs(Config.Interactables) do
		local model = GetHashKey(v)
		table.insert(Sitables, model)
	end
	Wait(100)
	exports['qtarget']:AddTargetModel(Sitables, {
        options = {
            {
                event = "Boost-Sit:Sit",
                icon = "fas fa-chair",
                label = "Sit",
            },
        },
        job = {"all"},
        distance = Config.MaxDistance
    })
end)

RegisterNetEvent("Boost-Sit:Sit")
AddEventHandler("Boost-Sit:Sit", function()
	print("Nu suveikiau")
	local playerPed = PlayerPedId()

	if sitting and not IsPedUsingScenario(playerPed, currentScenario) then
		wakeup()
	end

		-- Disable controls
	if disableControls then
		DisableControlAction(1, 37, true) -- Disables INPUT_SELECT_WEAPON (TAB)
	end

	local object, distance = GetNearChair()

	if Config.Debug then
		table.insert(debugProps, object)
	end

	if distance and distance < 1.4 then
		local hash = GetEntityModel(object)

		for k,v in pairs(Config.Sitable) do
			if GetHashKey(k) == hash then
				sit(object, k, v)
				break
			end
		end
	end
end)

function GetNearChair()
	local object, distance
	local coords = GetEntityCoords(GetPlayerPed(-1))
	for i=1, #Config.Interactables do
		object = GetClosestObjectOfType(coords, 3.0, GetHashKey(Config.Interactables[i]), false, false, false)
		distance = #(coords - GetEntityCoords(object))
		if distance < 1.6 then
			return object, distance
		end
	end
	return nil, nil
end

function wakeup()
	local playerPed = PlayerPedId()
	local pos = GetEntityCoords(GetPlayerPed(-1))

	TaskStartScenarioAtPosition(playerPed, currentScenario, 0.0, 0.0, 0.0, 180.0, 2, true, false)
	while IsPedUsingScenario(GetPlayerPed(-1), currentScenario) do
		Wait(100)
	end
	ClearPedTasks(playerPed)

	FreezeEntityPosition(playerPed, false)
	FreezeEntityPosition(currentObj, false)

	TriggerServerEvent('sho_sit_prop:leavePlace', currentSitCoords)
	currentSitCoords, currentScenario = nil, nil
	sitting = false
	disableControls = false
end

function sit(object, modelName, data)
	-- Fix for sit on chairs behind walls
	if not HasEntityClearLosToEntity(GetPlayerPed(-1), object, 17) then
		return
	end
	disableControls = true
	currentObj = object
	FreezeEntityPosition(object, true)

	PlaceObjectOnGroundProperly(object)
	local pos = GetEntityCoords(object)
	local playerPos = GetEntityCoords(GetPlayerPed(-1))
	local objectCoords = pos.x .. pos.y .. pos.z

	ESX.TriggerServerCallback('sho_sit_prop:getPlace', function(occupied)
		if occupied then
			ESX.ShowNotification('There is someone on this chair')
		else
			local playerPed = PlayerPedId()
			lastPos, currentSitCoords = GetEntityCoords(playerPed), objectCoords

			TriggerServerEvent('sho_sit_prop:takePlace', objectCoords)
			
			currentScenario = data.scenario
			TaskStartScenarioAtPosition(playerPed, currentScenario, pos.x, pos.y, pos.z + (playerPos.z - pos.z)/2, GetEntityHeading(object) + 180.0, 0, true, false)

			Citizen.Wait(2500)
			if GetEntitySpeed(GetPlayerPed(-1)) > 0 then
				ClearPedTasks(GetPlayerPed(-1))
				TaskStartScenarioAtPosition(playerPed, currentScenario, pos.x, pos.y, pos.z + (playerPos.z - pos.z)/2, GetEntityHeading(object) + 180.0, 0, true, true)
			end

			sitting = true
		end
	end, objectCoords)
end


local Table = 0
local sitting = false
local Chairs = {
	{ location = vec3(-1183.2, -887.01, 14.0), heading = 214.57, width = 0.6, height = 0.6, minZ = 13.0, maxZ = 14.45, distance = 2.7, seat = 1 },
	{ location = vec3(-1184.03, -887.54, 14.0), heading = 214.57, width = 0.6, height = 0.6, minZ = 13.0, maxZ = 14.45, distance = 2.7, seat = 1 },
	{ location = vec3(-1182.08, -888.63, 14.0), heading = 33.74, width = 0.6, height = 0.6, minZ = 13.0, maxZ = 14.45, distance = 2.7, seat = 1 },
	{ location = vec3(-1182.86, -889.09, 14.0), heading = 33.74, width = 0.6, height = 0.6, minZ = 13.0, maxZ = 14.45, distance = 2.7, seat = 1 },

	{ location = vec3(-1181.2, -890.08, 14.0), heading = 122.89, width = 0.8, height = 0.8, minZ = 12.0, maxZ = 14.0, distance = 3.8, seat = 2 },
	{ location = vec3(-1181.36, -891.54, 14.0), heading = 34.91, width = 0.8, height = 0.8, minZ = 12.0, maxZ = 14.0, distance = 3.8, seat = 2 },
	
	{ location = vec3(-1183.43, -892.97, 14.0), heading = 122.24, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 3 },
	{ location = vec3(-1183.96, -892.15, 14.0), heading = 122.24, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 3 },
	{ location = vec3(-1184.82, -893.85, 14.0), heading = 302.96, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 3 },
	{ location = vec3(-1185.32, -893.09, 14.0), heading = 302.96, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 3 },

	{ location = vec3(-1185.76, -894.45, 14.0), heading = 122.24, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 4 },
	{ location = vec3(-1186.22, -893.73, 14.0), heading = 122.24, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 4 },
	{ location = vec3(-1187.28, -895.58, 14.0), heading = 302.96, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 4 },
	{ location = vec3(-1187.7, -894.77, 14.0), heading = 302.96, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 4 },

	{ location = vec3(-1189.5, -897.0, 14.0), heading = 28.39, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 5 },
	{ location = vec3(-1190.9, -896.79, 14.0), heading = 302.76, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 5 },
	
	{ location = vec3(-1190.31, -892.59, 14.0), heading = 36.6, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 6 },
	{ location = vec3(-1191.3, -891.35, 14.0), heading = 210.99, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 6 },

	{ location = vec3(-1187.59, -890.79, 14.0), heading = 126.79, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 7 },
	{ location = vec3(-1189.06, -890.59, 14.0), heading = 209.77, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 7 },
	{ location = vec3(-1189.33, -892.15, 14.0), heading = 303.68, width = 0.6, height = 0.6, minZ = 12.0, maxZ = 14.0, distance = 2.7, seat = 7 },
}

Citizen.CreateThread(function()
	for k, v in pairs(Chairs) do
		exports['qtarget']:AddBoxZone("addon_chair_"..k, v.location, v.width, v.height, { 
			name="addon_chair_"..k, 
			heading = v.heading, 
			debugPoly=false, 
			minZ = v.minZ, 
			maxZ = v.maxZ, 
		}, { 
			options = { 
				{ 
					event = "sho_sit_prop:Chair", 
					icon = "fas fa-chair", 
					label = "Sit Down", 
					loc = v.location, 
					head = v.heading, 
					seat = v.seat 
				},
			},
			distance = v.distance
		})
	end
end)

RegisterNetEvent('sho_sit_prop:Chair', function(data)
	local canSit = true
	local sitting = false
	for k, v in pairs(ESX.Game.GetPlayersInArea(data.loc, 0.6)) do
		local dist = #(GetEntityCoords(v) - data.loc)
		if dist <= 0.4 then 
			canSit = false 
		end
	end
	if canSit then
		TaskStartScenarioAtPosition(PlayerPedId(), "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER", data.loc.x, data.loc.y, data.loc.z-0.5, data.head, 0, 1, true)
		Table = data.seat
		sitting = true
	end
	while sitting do
		local ped = PlayerPedId()
		if sitting then 
			if IsControlJustReleased(0, 202) and IsPedUsingScenario(ped, "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER") then
				sitting = false
				ClearPedTasks(ped)
				if Table == 1 then SetEntityCoords(ped, vec3(-1184.39, -888.87, 12.98)) SetEntityHeading(ped, 123.03) end
				if Table == 2 then SetEntityCoords(ped, vec3(-1182.78, -891.1, 12.98)) SetEntityHeading(ped, 120.19) end
				if Table == 3 then SetEntityCoords(ped, vec3(-1185.19, -891.8, 12.98)) SetEntityHeading(ped, 35.06) end
				if Table == 4 then SetEntityCoords(ped, vec3(-1187.54, -893.46, 12.98)) SetEntityHeading(ped, 30.33) end
				if Table == 5 then SetEntityCoords(ped, vec3(-1190.48, -895.44, 12.98)) SetEntityHeading(ped, 33.09) end
				if Table == 6 then SetEntityCoords(ped, vec3(-1191.48, -892.5, 12.98)) SetEntityHeading(ped, 125.01) end
				if Table == 7 then SetEntityCoords(ped, vec3(-1188.01, -892.1, 14.0)) SetEntityHeading(ped, 212.94) end
				Table = 0
			end
		end
		Wait(5) 
		if not IsPedUsingScenario(ped, "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER") then 
			sitting = false 
		end
	end
end)