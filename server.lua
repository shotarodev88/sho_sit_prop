ESX = nil
local seatsTaken = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterNetEvent('sho_sit_prop:takePlace')
AddEventHandler('sho_sit_prop:takePlace', function(objectCoords)
	seatsTaken[objectCoords] = true
end)

RegisterNetEvent('sho_sit_prop:leavePlace')
AddEventHandler('sho_sit_prop:leavePlace', function(objectCoords)
	if seatsTaken[objectCoords] then
		seatsTaken[objectCoords] = nil
	end
end)

ESX.RegisterServerCallback('sho_sit_prop:getPlace', function(source, cb, objectCoords)
	cb(seatsTaken[objectCoords])
end)