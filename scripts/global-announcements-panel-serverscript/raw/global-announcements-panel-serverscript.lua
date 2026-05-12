local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local permittedUsers = {12345}

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "AnnouncementsRemote"
remoteEvent.Parent = ReplicatedStorage

local permittedIdsRemote = Instance.new("RemoteEvent")
permittedIdsRemote.Name = "PermittedIdsRemote"
permittedIdsRemote.Parent = ReplicatedStorage

local VALID_FONTS = {
	"FredokaOne","GothamBold","GothamMedium","Arial","ArialBold",
	"Code","SourceSans","SourceSansBold","RobotoMono","Oswald",
	"PatrickHand","Cartoon","Arcade","Fantasy","Antique",
	"Bodoni","Creepster","DenkOne","Fondamento","Gotham"
}

local VALID_COLORS = {
	"#FFFFFF","#FF5050","#50FF50","#5080FF","#FFD700",
	"#FF80FF","#00FFFF","#FF8C00","#ADFF2F","#FF69B4",
	"#00CED1","#DC143C","#7FFF00","#9400D3","#FF4500",
	"#1E90FF","#F0E68C","#FF6347","#40E0D0","#EE82EE"
}

local function isPermitted(player)
	for _, id in ipairs(permittedUsers) do
		if player.UserId == id then return true end
	end
	return false
end

local function isValidFont(fontName)
	for _, v in ipairs(VALID_FONTS) do
		if v == fontName then return true end
	end
	return false
end

local function isValidColor(colorHex)
	for _, v in ipairs(VALID_COLORS) do
		if v == colorHex then return true end
	end
	return false
end

task.spawn(function()
	MessagingService:SubscribeAsync("GlobalAnnouncement", function(message)
		local data = message.Data
		remoteEvent:FireAllClients(
			data.name,
			data.message,
			data.colorHex,
			data.fontName,
			data.duration,
			data.nameColorHex,
			data.showVerified,
			data.showIcon,
			data.soundId,
			data.userId
		)
	end)
end)

permittedIdsRemote.OnServerEvent:Connect(function(player)
	permittedIdsRemote:FireClient(player, isPermitted(player))
end)

remoteEvent.OnServerEvent:Connect(function(player, message, colorHex, fontName, duration, typeStr, nameColorHex, showVerified, showIcon, soundId)
	if not isPermitted(player) then return end
	if type(message) ~= "string" then return end
	if type(colorHex) ~= "string" then return end
	if type(fontName) ~= "string" then return end
	if type(duration) ~= "number" then return end
	if type(nameColorHex) ~= "string" then return end
	if duration <= 0 or duration > 60 then return end
	if message:len() > 300 then return end
	if not isValidFont(fontName) then return end
	if not isValidColor(colorHex) then return end
	if not isValidColor(nameColorHex) then return end

	local safeShowVerified = showVerified == true
	local safeShowIcon = showIcon == true
	local safeSoundId = 130501547093536
	if type(soundId) == "number" and soundId > 0 then
		safeSoundId = soundId
	end

	if typeStr == "GLOBAL" then
		local payload = {
			name = player.Name,
			message = message,
			colorHex = colorHex,
			fontName = fontName,
			duration = duration,
			nameColorHex = nameColorHex,
			showVerified = safeShowVerified,
			showIcon = safeShowIcon,
			soundId = safeSoundId,
			userId = player.UserId
		}
		task.spawn(function()
			MessagingService:PublishAsync("GlobalAnnouncement", payload)
		end)
	else
		remoteEvent:FireAllClients(player.Name, message, colorHex, fontName, duration, nameColorHex, safeShowVerified, safeShowIcon, safeSoundId, player.UserId)
	end
end)