local QRCore = exports['qr-core']:GetCoreObject()

RegisterServerEvent('rsg-bandits:server:robplayer')
AddEventHandler('rsg-bandits:server:robplayer', function()
	local src = source
	local Player = QRCore.Functions.GetPlayer(src)
	Player.Functions.SetMoney('cash', 0)
end)