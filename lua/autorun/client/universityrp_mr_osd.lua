--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("universityrp_mr_osd:cl")

universityrp_mr_osd = universityrp_mr_osd or {}

include("config/universityrp_mr_osd/shared.lua")

-- Configuration:
local BackgroundColor = universityrp_mr_osd.BackgroundColor or Color(0, 0, 0, 191)
local BackgroundMaterial = universityrp_mr_osd.BackgroundMaterial or "vgui/universityrp_mr_osd/background.png"
local ChatBackgroundColorFirst = universityrp_mr_osd.ChatBackgroundColorFirst or Color(
	BackgroundColor.r,
	BackgroundColor.g,
	BackgroundColor.b,
	math.max(BackgroundColor.a, 239)
)
local ChatBackgroundColorSecond = universityrp_mr_osd.ChatBackgroundColorSecond or ChatBackgroundColorFirst
local ChatBackgroundColorFinal = universityrp_mr_osd.ChatBackgroundColorFinal or Color(
	ChatBackgroundColorSecond.r,
	ChatBackgroundColorSecond.g,
	ChatBackgroundColorSecond.b,
	0
)
local LogoMaterial = universityrp_mr_osd.LogoMaterial or "vgui/techcredits/miles"
local Ranks = universityrp_mr_osd.Ranks or {}

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "universityrp_mr_osd:cl")

local materialBackground = Material(BackgroundMaterial, "smooth")
local materialLogo = Material(LogoMaterial, "smooth")
surface.CreateFont("universityrp_mr_osd_1b", {
	font = "Comic Sans MS",
	size = 21,
	weight = 750,
	antialias = true,
	outline = true,
})
surface.CreateFont("universityrp_mr_osd_1bi", {
	font = "Comic Sans MS",
	size = 21,
	weight = 750,
	antialias = true,
	italic = true,
	outline = true,
})
surface.CreateFont("universityrp_mr_osd_1", {
	font = "Comic Sans MS",
	size = 21,
	antialias = true,
	outline = true,
})
surface.CreateFont("universityrp_mr_osd_2", {
	size = 15,
	weight = 750,
	antialias = false,
	outline = true,
})

do
	-- Hide default OSD elements:
	
	local unused = {
		["DarkRP_LocalPlayerHUD"] = true,
		["DarkRP_Hungermod"] = true,
		["CHudBattery"] = true,
		["CHudHealth"] = true,
	}
	hook.Add("HUDShouldDraw", "universityrp_mr_osd:cl", function(name)
		if unused[name] then
			return false
		end
	end)
end

local chatStartTime = nil
local chatEndTime = nil
local chat_bg_x, chat_bg_y
local chat_bg_w, chat_bg_h
do
	-- Prepare drawing a background on the chat box bounds to improve readability:
	
	local ChatTotalTime = 12.
	
	local function onNewChatMessage()
		local now = RealTime()
		chatStartTime = now
		chatEndTime = now + ChatTotalTime
		chat_bg_x, chat_bg_y = chat.GetChatBoxPos()
		chat_bg_w, chat_bg_h = chat.GetChatBoxSize()
		local scr_w, scr_h = ScrW(), ScrH()
		local hud_x, hud_y = 0, scr_h - 256
		local hud_w, hud_h = 256, 256
		-- Fix dimensions:
		chat_bg_w = hud_w
		chat_bg_x = 0
		if chat_bg_y < hud_y then
			chat_bg_h = chat_bg_h - (hud_y - chat_bg_y)
			chat_bg_y = hud_y
		end
	end
	hook.Add("OnPlayerChat", "universityrp_mr_osd:cl", onNewChatMessage)
	hook.Add("ChatText", "universityrp_mr_osd:cl", onNewChatMessage)
end

local function getPlayerRank(ply)
	-- Returns the beautiful name of a user group
	
	local group = ply:GetUserGroup()
	return Ranks[group] or group
end

local scrH = ScrH()
local shouldDrawOsd
hook.Add("HUDPaintBackground", "universityrp_mr_osd:cl", function()
	shouldDrawOsd = hook.Run("HUDShouldDraw", "universityrp_mr_osd:cl")
	if shouldDrawOsd == false then
		return
	end
	scrH = ScrH()
	
	-- Paint background:
	surface.SetMaterial(materialBackground)
	surface.SetDrawColor(BackgroundColor)
	surface.DrawTexturedRect(0, scrH - 512, 512, 512)
	surface.SetMaterial(materialLogo)
	surface.SetDrawColor(255, 255, 255, 255)
	
	-- Paint logo:
	local now = RealTime()
	local animation = now % 90. -- animation every 90 seconds
	if animation < 0.5 then
		-- animation part 1 (getting bigger):
		animation = animation * 4. -- 0 to 2
		if animation > 1. then
			animation = 2. - animation -- 0 to 1 to 0
		end
		local diameter = math.floor(64. * (1. + (animation * 0.2)))
		local offset = 32 - (diameter / 2)
		surface.DrawTexturedRect(192 + offset, scrH - 256 + offset, diameter, diameter)
	elseif animation > 1. and animation < 2. then
		-- animation part 2 (rotating):
		animation = animation - 1. -- 0 à 1
		animation = (-math.cos(animation * (math.pi)) + 1) * 180.
		surface.DrawTexturedRectRotated(192 + 32, scrH - 256 + 32, 64, 64, animation)
	else
		-- animation not running:
		surface.DrawTexturedRect(192, scrH - 256, 64, 64)
	end
end)

do
	local function translateY(y)
		return scrH - 256 + y
	end
	
	local function drawText(text, x, y)
		surface.SetTextPos(x, translateY(y))
		surface.DrawText(text)
	end
	
	local function drawCenteredText(text, y)
		surface.SetTextPos((256 - surface.GetTextSize(text)) / 2, translateY(y))
		surface.DrawText(text)
	end
	
	local function drawGaugeText(text, y)
		surface.SetTextPos(60 + ((152 - surface.GetTextSize(text)) / 2), translateY(y))
		surface.DrawText(text)
	end
	
	local gauge_bg = Color(128, 128, 128)
	local gauge_health = Color(192, 0, 0)
	local gauge_hunger = Color(0, 0, 192)
	local ChatSecondStep = 10
	local ChatFirstStepDuration = 10
	local ChatSecondStepDuration = 2
	local chatBackgroundColorCurrent = Color(0, 0, 0)
	
	hook.Add("HUDPaint", "universityrp_mr_osd:cl", function()
		if shouldDrawOsd == false then
			return
		end
		
		-- Text color pulse value if critical level:
		local now = RealTime()
		local pulse_progress = now % 1.5
		local text_pulse
		if pulse_progress < 0.2 then
			text_pulse = 255 - (pulse_progress * 255 / 0.2)
		elseif pulse_progress < 0.6 then
			text_pulse = ((pulse_progress - 0.2) * 255 / 0.4)
		else
			text_pulse = 255
		end
		
		-- Determine the spectated player:
		local ply = LocalPlayer()
		local ply_spec = FSpectate and FSpectate.getSpecEnt()
		local spectating
		if IsValid(ply_spec) and ply_spec ~= ply and ply_spec:IsPlayer() then
			ply = ply_spec
			spectating = true
		else
			spectating = false
		end
		
		local hunger_disp
		local health_disp
		surface.SetFont("universityrp_mr_osd_1b"); do
			surface.SetTextColor(255, 255, 255)
			if rooms_lib_mr then
				local _, room_name, _, building_name = rooms_lib_mr.getRoom(spectating and ply or nil) -- no player needed for the local player
				if room_name then
					drawCenteredText(room_name, 22)
				else
					drawCenteredText("·", 22)
				end
				if building_name then
					drawCenteredText(building_name, 44)
				else
					drawCenteredText("·", 44)
				end
			end
			drawText(ply.getDarkRPVar and ply:getDarkRPVar("job") or "", 11, 99)
			surface.SetTextColor(255, 255, 0)
			drawText(getPlayerRank(ply), 11, 121)
			surface.SetTextColor(192, 255, 192)
			if DarkRP and ply.getDarkRPVar then
				drawText(
					hl == "fr" and
					"Salaire" or
					"Salary",
					128, 154
				)
				drawText(
					hl == "fr" and
					"Portefeuille" or
					"Wallet",
					11, 154
				)
			end
			local health_raw = ply:Health()
			local health = math.min(math.max(health_raw / ply:GetMaxHealth(), 0), 1)
			health_disp = math.max(math.ceil(health_raw), 0)
			if health_disp <= 15 then
				surface.SetTextColor(255, text_pulse, text_pulse)
			else
				surface.SetTextColor(255, 255, 255)
			end
			drawText(
				hl == "fr" and
				"Santé" or
				"Health",
				11, 205
			)
			draw.RoundedBox(6, 60, translateY(210), 152, 13, gauge_bg)
			local width = 150 * health
			if width > 4 then
				draw.RoundedBox(  4, 61, translateY(211), width, 11, gauge_health)
			elseif health > 0 then
				draw.RoundedBoxEx(0, 61, translateY(211), width, 11, gauge_health) -- no corner
			end
			if FoodItems then -- Hunger Mod enabled
				local hunger
				if spectating then
					surface.SetTextColor(255, 255, 255)
				else
					local hunger_raw = ply:getDarkRPVar("Energy") or 0
					hunger = hunger_raw / 100
					hunger_disp = math.floor(100 - hunger_raw)
					if hunger_disp >= 85 then
						surface.SetTextColor(255, text_pulse, text_pulse)
					else
						surface.SetTextColor(255, 255, 255)
					end
				end
				drawText(
					hl == "fr" and
					"Faim" or
					"Hunger",
					11, 227
				)
				if not spectating then
					draw.RoundedBox(6, 60, translateY(232), 152, 13, gauge_bg)
					width = 150 * hunger
					if width > 4 then
						draw.RoundedBox(  4, 61, translateY(233), width, 11, gauge_hunger)
					elseif hunger_disp < 100 then
						draw.RoundedBoxEx(0, 61, translateY(233), width, 11, gauge_hunger) -- no corner
					end
				end
			end
		end
		surface.SetFont("universityrp_mr_osd_1bi"); do
			surface.SetTextColor(255, 255, 255)
			drawText(ply:Nick(), 11, 77)
		end
		surface.SetFont("universityrp_mr_osd_1"); do
			surface.SetTextColor(192, 255, 192)
			if DarkRP and RPExtraTeams and ply.getDarkRPVar then
				local salary_txt
				if spectating then
					local job = RPExtraTeams[ply:Team()]
					if job then
						salary_txt = "≈" .. DarkRP.formatMoney(job.salary)
					else
						salary_txt = ""
					end
				else
					salary_txt = DarkRP.formatMoney(ply:getDarkRPVar("salary"))
				end
				drawText(salary_txt, 128, 176)
				drawText(DarkRP.formatMoney(ply:getDarkRPVar("money")), 11, 176)
			end
		end
		surface.SetFont("universityrp_mr_osd_2"); do
			if health_disp <= 15 then
				surface.SetTextColor(255, text_pulse, text_pulse)
			else
				surface.SetTextColor(255, 255, 255)
			end
			drawGaugeText(health_disp, 209)
			if DarkRP and FoodItems and not spectating then -- Hunger Mod enabled
				if hunger_disp >= 85 then
					surface.SetTextColor(255, text_pulse, text_pulse)
				else
					surface.SetTextColor(255, 255, 255)
				end
				if hunger_disp < 100 then
					drawGaugeText(hunger_disp .. "%", 231)
				else
					drawGaugeText(DarkRP.getPhrase("starving"), 231)
				end
			end
		end
		
		-- Chat cover:
		if not chatEndTime then
			-- nothing
		elseif chatEndTime > now then
			if not LocalPlayer():IsTyping() then
				local chat_progress = now - chatStartTime
				if chat_progress < ChatSecondStep then -- full background
					chat_progress = chat_progress / ChatFirstStepDuration
					chatBackgroundColorCurrent.r = Lerp(chat_progress, ChatBackgroundColorFirst.r, ChatBackgroundColorSecond.r)
					chatBackgroundColorCurrent.g = Lerp(chat_progress, ChatBackgroundColorFirst.g, ChatBackgroundColorSecond.g)
					chatBackgroundColorCurrent.b = Lerp(chat_progress, ChatBackgroundColorFirst.b, ChatBackgroundColorSecond.b)
					chatBackgroundColorCurrent.a = Lerp(chat_progress, ChatBackgroundColorFirst.a, ChatBackgroundColorSecond.a)
				else -- fading background
					chat_progress = (chat_progress - ChatSecondStep) / ChatSecondStepDuration
					chatBackgroundColorCurrent.r = Lerp(chat_progress, ChatBackgroundColorSecond.r, ChatBackgroundColorFinal.r)
					chatBackgroundColorCurrent.g = Lerp(chat_progress, ChatBackgroundColorSecond.g, ChatBackgroundColorFinal.g)
					chatBackgroundColorCurrent.b = Lerp(chat_progress, ChatBackgroundColorSecond.b, ChatBackgroundColorFinal.b)
					chatBackgroundColorCurrent.a = Lerp(chat_progress, ChatBackgroundColorSecond.a, ChatBackgroundColorFinal.a)
				end
				draw.RoundedBoxEx(0, chat_bg_x, chat_bg_y, chat_bg_w, chat_bg_h, chatBackgroundColorCurrent)
			end
		else
			chatStartTime = nil
			chatEndTime = nil
		end
	end)
end
