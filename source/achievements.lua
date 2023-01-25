-- Achievements for Playdate

---@diagnostic disable-next-line: lowercase-global
achievements = {}

---@class (exact) Achievement
---@field id string A unique ID for the achievement.
---@field isGranted? boolean Whether or not the achievement has been granted.

---Set up the achievements system.
---@param achievementDefs Achievement[] The current achievements definitions for the game.
function achievements.init(achievementDefs)
	if achievementDefs == nil then
		error("No data provided during init", 2)
	end

	achievements.kAchievements = {}
	for _, achDef in ipairs(achievementDefs) do
		if type(achDef.id) ~= "string" or achDef.id == "" then
			error('Achievement has invalid ID "' .. achDef.id .. '"', 2)
		end

		if achievements.kAchievements[achDef.id] then
			error('Duplicate achievement ID "' .. achDef.id .. '"', 2)
		end

		if type(achDef.id) ~= "nil" then
			print('WARN: Achievement definition "' .. achDef.id .. '" has achievement data: isGranted', 2)
		end

		achievements.kAchievements[achDef.id] = achDef
	end
end

return achievements
