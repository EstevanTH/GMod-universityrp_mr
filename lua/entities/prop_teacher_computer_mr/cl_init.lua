--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("prop_teacher_computer_mr:cl")

include("shared.lua")

-- Configuration:
local dev_mode = false
local DisplayTimeout_s = prop_teacher_computer_mr.DisplayTimeout_s or 45.
local DefaultRenderWidth = prop_teacher_computer_mr.DefaultRenderWidth or 1280
local DefaultRenderHeight = prop_teacher_computer_mr.DefaultRenderHeight or 960
local DesignWidth = prop_teacher_computer_mr.DesignWidth or 1024
local DesignHeight = prop_teacher_computer_mr.DesignHeight or 768
local RemoteColor = prop_teacher_computer_mr.RemoteColor or Color(88, 96, 120)

-- VGUI remote control buttons:
local buttonMaterialSize = 32
local button_pressed_bottom = Material("vgui/prop_teacher_computer_mr/remote/button_pressed_bottom.png", "smooth")
local button_pressed_middle = Material("vgui/prop_teacher_computer_mr/remote/button_pressed_middle.png", "smooth")
local button_pressed_top = Material("vgui/prop_teacher_computer_mr/remote/button_pressed_top.png", "smooth")
local button_released_bottom = Material("vgui/prop_teacher_computer_mr/remote/button_released_bottom.png", "smooth")
local button_released_middle = Material("vgui/prop_teacher_computer_mr/remote/button_released_middle.png", "smooth")
local button_released_top = Material("vgui/prop_teacher_computer_mr/remote/button_released_top.png", "smooth")
local pc_on = Material("vgui/prop_teacher_computer_mr/remote/pc_on.png", "")
local pc_standby = Material("vgui/prop_teacher_computer_mr/remote/pc_standby.png", "")
local projector_off = Material("vgui/prop_teacher_computer_mr/remote/projector_off.png", "")
local projector_on = Material("vgui/prop_teacher_computer_mr/remote/projector_on.png", "")
local screen_close = Material("vgui/prop_teacher_computer_mr/remote/screen_close.png", "")
local screen_open = Material("vgui/prop_teacher_computer_mr/remote/screen_open.png", "")
local slide_next = Material("vgui/prop_teacher_computer_mr/remote/slide_next.png", "")
local slide_previous = Material("vgui/prop_teacher_computer_mr/remote/slide_previous.png", "")
local slideshow_close = Material("vgui/prop_teacher_computer_mr/remote/slideshow_close.png", "")
local slideshow_open = Material("vgui/prop_teacher_computer_mr/remote/slideshow_open.png", "")
local slideshow_start = Material("vgui/prop_teacher_computer_mr/remote/slideshow_start.png", "")
local slideshow_stop = Material("vgui/prop_teacher_computer_mr/remote/slideshow_stop.png", "")
local soffice_exit = Material("vgui/prop_teacher_computer_mr/remote/soffice_exit.png", "")
local soffice_open = Material("vgui/prop_teacher_computer_mr/remote/soffice_open.png", "")

local a = prop_teacher_computer_mr.actions -- shortcut

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "prop_teacher_computer_mr:cl")

--[[
local function findUpperPowerOfTwo(num)
	local i = 1
	while i <= 4096 do
		if i >= num then
			return i
		end
		i = i * 2
	end
	return i
end
]]

function ENT:renderScreenAndOverrideMaterial(subMaterialId)
	-- If computer is on, update the screen texture and substitute the sub-material accordingly:
	-- This can be called from other entities (projector screen, etc.).
	
	local materialHtmlSmooth = self:linkedScreenDrawn()
	if materialHtmlSmooth then
		render.MaterialOverrideByIndex(subMaterialId, materialHtmlSmooth)
	end
end

local function makeScreenMaterial(materialName)
	local material = CreateMaterial(materialName, "UnLitGeneric", {
		["$model"] = 1,
		["$nodecal"] = 1,
		["$colorfix"] = "{255 255 255}",
		["proxies"] = {
			["equals"] = {
				["srcVar1"] = "$colorfix",
				["resultVar"] = "$color",
			},
		},
	})
	return material
end

local materialPathScreenDesktop_png = "vgui/prop_teacher_computer_mr/screen/screen_desktop_fr.png"

function ENT:Draw()
	-- 3D rendering, overriding the screen display material
	
	if not prop_teacher_computer_mr.materialScreenUnloaded then
		-- Make a material with the PNG texture and appropriate flags:
		prop_teacher_computer_mr.materialScreenUnloaded = makeScreenMaterial("prop_teacher_computer_mr_unloaded")
		prop_teacher_computer_mr.textureScreenUnloaded = Material(materialPathScreenDesktop_png, "smooth"):GetTexture("$basetexture")
		prop_teacher_computer_mr.materialScreenUnloaded:SetTexture("$basetexture", prop_teacher_computer_mr.textureScreenUnloaded)
	end
	self:renderScreenAndOverrideMaterial(1)
	self:DrawModel()
	render.MaterialOverrideByIndex(1, nil)
end

function ENT:ImpactTrace()
	-- Hide impact traces for guaranteed readability
	
	return true
end

--[[ Notes
	- Warning: if a page refresh is attempted while a video is reading, the URL will be considered as different.
]]

local renderW, renderH, scaleToDesign
do
	do
		local aspectRatioDifference = (DefaultRenderWidth / DefaultRenderHeight) - (DesignWidth / DesignHeight)
		if aspectRatioDifference < -0.01 or aspectRatioDifference > 0.01 then
			ErrorNoHalt("[prop_teacher_computer_mr] The default render aspect ratio is different from the design aspect ratio!\n")
		end
	end
	local scr_w, scr_h = ScrW(), ScrH()
	if scr_w >= DefaultRenderWidth and scr_h >= DefaultRenderHeight then
		renderW = DefaultRenderWidth
		renderH = DefaultRenderHeight
	elseif scr_w >= DesignWidth and scr_h >= DesignHeight then
		renderW = DesignWidth
		renderH = DesignHeight
	else
		-- Fix size for resolutions < {DesignWidth x DesignHeight}:
		print("The screen resolution is smaller than " .. DefaultRenderWidth .. "x" .. DefaultRenderHeight .. ".")
		local aspectRatio = DesignWidth / DesignHeight
		local w, h = DefaultRenderWidth, DefaultRenderHeight
		if scr_w < w then -- resolution with aspect ratio < aspectRatio
			w = scr_w
			h = scr_w / aspectRatio
		end
		if scr_h < h then
			w = scr_h * aspectRatio
			h = scr_h
		end
		renderW = w
		renderH = h
	end
	scaleToDesign = renderW / DesignWidth
end

local GUI_column2 = 48
local GUI_buttontall = 48
local GUI_nextprevtall = 64
local GUI_listtall = 16
local GUI_spacer = 4
local GUI_background = RemoteColor

local black = Color(0, 0, 0)
local grey = Color(128, 128, 128)
local white = Color(255, 255, 255)
local bg_selected = Color(0, 0, 128)
local function addSlideshowToList(list_, title, allowed)
	local slideshowSelector = prop_teacher_computer_mr.slideshowSelector
	local i = list_.count
	list_.count = list_.count + 1
	local icon = vgui.Create("DImage", list_)
	local text = vgui.Create("DLabel", list_)
	local action
	if allowed then
		action = vgui.Create("DImageButton", list_)
	end
	if list_.elements[title] then
		ErrorNoHalt('A slideshow named "' .. title .. '" exists more than once!\n')
	end
	list_.elements[title] = {
		icon = icon,
		text = text,
		action = action,
	}
	local y = 1 + (17 * i)
	icon:SetPos(1, y)
	icon:SetSize(16, 16)
	icon:SetImage("icon16/page_white_powerpoint.png")
	text:SetPos(18, y)
	text:SetText(" " .. title .. " ")
	text:SetContentAlignment(5)
	text:SizeToContents()
	if allowed then
		text:SetTextColor(black)
	else
		text:SetTextColor(grey)
	end
	text:SetBGColor(bg_selected)
	text:SetPaintBackgroundEnabled(false)
	local w = text:GetSize()
	text:SetSize(w, 16)
	if allowed then
		action:SetPos(1, y)
		w = 17 + w
		action:SetSize(w, 16)
		action.DoClick = function()
			slideshowSelector.title = title
			slideshowSelector.buttonOpen:SetEnabled(true)
			for e_title, element in pairs(list_.elements) do
				if e_title ~= title then
					element.text:SetTextColor(black)
					element.text:SetPaintBackgroundEnabled(false)
				else
					element.text:SetTextColor(white)
					element.text:SetPaintBackgroundEnabled(true)
					element.text:SetBGColor(bg_selected)
				end
			end
		end
		action:SetAlpha(0)
	end
end

net.Receive("prop_teacher_computer_mr", function()
	local action = net.ReadUInt(8)
	if action == a.SlideshowOpen then
		local step = net.ReadUInt(8)
		if step == 1 then -- list of categories
			if  IsValid(prop_teacher_computer_mr.slideshowSelector)
			and IsValid(prop_teacher_computer_mr.slideshowSelector.categorySel) then
				local categorySel = prop_teacher_computer_mr.slideshowSelector.categorySel
				categorySel:SetEnabled(true)
				local n = net.ReadUInt(8)
				for i = 1, n do
					local cat = net.ReadString()
					local num = net.ReadUInt(16)
					categorySel:AddChoice(cat .. " (" .. num .. ")", cat)
				end
				categorySel.defaultText = (
					hl == "fr" and
					"Catégorie" or
					"Category"
				)
				categorySel:SetValue(categorySel.defaultText)
			end
		elseif step == 2 then -- list of slideshows
			if  IsValid(prop_teacher_computer_mr.slideshowSelector)
			and IsValid(prop_teacher_computer_mr.slideshowSelector.categorySel)
			and IsValid(prop_teacher_computer_mr.slideshowSelector.listBG) then
				local slideshowSelector = prop_teacher_computer_mr.slideshowSelector
				local cat = net.ReadString()
				if cat == slideshowSelector.cat then
					local categorySel = slideshowSelector.categorySel
					local listBG = slideshowSelector.listBG
					categorySel:SetEnabled(true)
					if IsValid(slideshowSelector.list_) then
						slideshowSelector.list_:Remove()
					end
					slideshowSelector.list_ = vgui.Create("DScrollPanel", listBG); do
						local list_ = slideshowSelector.list_
						list_:SetSize(listBG:GetSize())
						list_.count = 0
						list_.elements = {}
						local n = net.ReadUInt(16)
						for i = 1, n do
							local title = net.ReadString()
							local allowed = net.ReadBool()
							addSlideshowToList(list_, title, allowed)
						end
					end
				end
			end
		elseif step == 3 then -- info about the opened slideshow
			if IsValid(prop_teacher_computer_mr.slideshowSelector) then
				local slideshowSelector = prop_teacher_computer_mr.slideshowSelector
				slideshowSelector:Remove()
			end
		end
	end
end)

local setupImageButton
do
	local material_offset
	local button_top
	local button_middle
	local button_bottom
	local function imageButtonPaint(button, w, h)
		if button:IsDown() then
			button_top = button_pressed_top
			button_middle = button_pressed_middle
			button_bottom = button_pressed_bottom
			surface.SetDrawColor(255, 255, 255)
			material_offset = 2
		else
			button_top = button_released_top
			button_middle = button_released_middle
			button_bottom = button_released_bottom
			if button:GetDisabled() then
				surface.SetDrawColor(255, 192, 192)
			else
				surface.SetDrawColor(255, 255, 255)
			end
			material_offset = 0
		end
		surface.SetMaterial(button_top)
		surface.DrawTexturedRect(0, 0, w, 12)
		surface.SetMaterial(button_middle)
		surface.DrawTexturedRect(0, 12, w, h - 24)
		surface.SetMaterial(button_bottom)
		surface.DrawTexturedRect(0, h - 12, w, 12)
		surface.SetMaterial(button.buttonMaterial)
		surface.DrawTexturedRect(
			((w - buttonMaterialSize) / 2) + material_offset,
			((h - buttonMaterialSize) / 2) - material_offset,
			buttonMaterialSize,
			buttonMaterialSize
		)
		surface.SetDrawColor(255, 255, 255)
		return true
	end
	function setupImageButton(button, material)
		button.buttonMaterial = material
		button.Paint = imageButtonPaint
	end
end

local function removeSeatGui()
	if IsValid(prop_teacher_computer_mr.seatGui) then
		prop_teacher_computer_mr.seatGui:Remove()
	end
end

local function updateSeatGui()
	local computer, on_seat = prop_teacher_computer_mr.getComputerFromPlayer(LocalPlayer())
	if on_seat and IsValid(prop_teacher_computer_mr.seatGui) then
		local seatGui = prop_teacher_computer_mr.seatGui
		if not computer:isComputerOn() then
			seatGui.computerWake:SetEnabled(true)
			seatGui.computerSleep:SetEnabled(false)
			seatGui.programOpen:SetEnabled(false)
			seatGui.programClose:SetEnabled(false)
			seatGui.slideshowOpen:SetEnabled(false)
			seatGui.slideshowClose:SetEnabled(false)
			seatGui.slideshowRun:SetEnabled(false)
			seatGui.slideshowExit:SetEnabled(false)
		else
			local state = computer:GetState()
			if state == a.ComputerWake then
				seatGui.computerWake:SetEnabled(false)
				seatGui.computerSleep:SetEnabled(true)
				seatGui.programOpen:SetEnabled(true)
				seatGui.programClose:SetEnabled(false)
				seatGui.slideshowOpen:SetEnabled(false)
				seatGui.slideshowClose:SetEnabled(false)
				seatGui.slideshowRun:SetEnabled(false)
				seatGui.slideshowExit:SetEnabled(false)
			elseif state == a.ProgramOpen then
				seatGui.computerWake:SetEnabled(false)
				seatGui.computerSleep:SetEnabled(true)
				seatGui.programOpen:SetEnabled(false)
				seatGui.programClose:SetEnabled(true)
				seatGui.slideshowOpen:SetEnabled(true)
				seatGui.slideshowClose:SetEnabled(false)
				seatGui.slideshowRun:SetEnabled(false)
				seatGui.slideshowExit:SetEnabled(false)
			elseif state == a.SlideshowOpen then
				seatGui.computerWake:SetEnabled(false)
				seatGui.computerSleep:SetEnabled(true)
				seatGui.programOpen:SetEnabled(false)
				seatGui.programClose:SetEnabled(true)
				seatGui.slideshowOpen:SetEnabled(true)
				seatGui.slideshowClose:SetEnabled(true)
				seatGui.slideshowRun:SetEnabled(true)
				seatGui.slideshowExit:SetEnabled(false)
			elseif state == a.SlideshowRun then
				seatGui.computerWake:SetEnabled(false)
				seatGui.computerSleep:SetEnabled(false)
				seatGui.programOpen:SetEnabled(false)
				seatGui.programClose:SetEnabled(true)
				seatGui.slideshowOpen:SetEnabled(false)
				seatGui.slideshowClose:SetEnabled(false)
				seatGui.slideshowRun:SetEnabled(false)
				seatGui.slideshowExit:SetEnabled(true)
			end
		end
	end
end

local function seatGuiPaint(self, w, h)
	draw.RoundedBoxEx(
		12,
		0, 0,
		w, h,
		self:GetBackgroundColor(),
		true, true, false, false
	)
end

local function createSeatGui() -- accessible from computer
	if IsValid(prop_teacher_computer_mr.seatGui) then
		prop_teacher_computer_mr.seatGui:Remove()
	end
	prop_teacher_computer_mr.seatGui = vgui.Create("DPanel"); do
		local seatGui = prop_teacher_computer_mr.seatGui
		seatGui.Paint = seatGuiPaint
		seatGui:SetPaintBackground(true)
		seatGui:SetBackgroundColor(GUI_background)
		local scr_W, scr_H = ScrW(), ScrH()
		seatGui:SetSize(
			108,
			5*GUI_spacer + 4*GUI_buttontall
		)
		seatGui:SetPos(scr_W - 109, 1)
		seatGui.computerWake = vgui.Create("DButton", seatGui); do
			local computerWake = seatGui.computerWake
			computerWake:SetPos(GUI_spacer, GUI_spacer)
			computerWake:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(computerWake, pc_on)
			computerWake:SetTooltip(
				hl == "fr" and
				"Réveiller Ordinateur" or
				"Wake Computer up"
			)
			computerWake.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.ComputerWake, 8)
				net.SendToServer()
			end
		end
		seatGui.computerSleep = vgui.Create("DButton", seatGui); do
			local computerSleep = seatGui.computerSleep
			computerSleep:SetPos(
				GUI_spacer + GUI_column2 + GUI_spacer,
				GUI_spacer
			)
			computerSleep:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(computerSleep, pc_standby)
			computerSleep:SetTooltip(
			hl == "fr" and
			"Ordinateur : Veille" or
			"Computer: Standby"
			)
			computerSleep.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.ComputerSleep, 8)
				net.SendToServer()
			end
		end
		seatGui.programOpen = vgui.Create("DButton", seatGui); do
			local programOpen = seatGui.programOpen
			programOpen:SetPos(
				GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer
			)
			programOpen:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(programOpen, soffice_open)
			programOpen:SetTooltip(
				hl == "fr" and
				"Ouvrir Logiciel" or
				"Open Program"
			)
			programOpen.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.ProgramOpen, 8)
				net.SendToServer()
			end
		end
		seatGui.programClose = vgui.Create("DButton", seatGui); do
			local programClose = seatGui.programClose
			programClose:SetPos(
				GUI_spacer + GUI_column2 + GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer
			)
			programClose:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(programClose, soffice_exit)
			programClose:SetTooltip(
				hl == "fr" and
				"Fermer Logiciel" or
				"Close Program"
			)
			programClose.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.ProgramClose, 8)
				net.SendToServer()
			end
		end
		seatGui.slideshowOpen = vgui.Create("DButton", seatGui); do
			local slideshowOpen = seatGui.slideshowOpen
			slideshowOpen:SetPos(
				GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer
			)
			slideshowOpen:SetSize(GUI_column2, GUI_buttontall)
			local txt_open = (
				hl == "fr" and
				"Ouvrir un Diaporama" or
				"Open a Slideshow"
			)
			setupImageButton(slideshowOpen, slideshow_open)
			slideshowOpen:SetTooltip(txt_open)
			slideshowOpen.DoClick = function()
				if IsValid(prop_teacher_computer_mr.slideshowSelector) then
					prop_teacher_computer_mr.slideshowSelector:Remove()
				end
				prop_teacher_computer_mr.slideshowSelector = vgui.Create("DFrame"); do
					local slideshowSelector = prop_teacher_computer_mr.slideshowSelector
					slideshowSelector:MakePopup()
					slideshowSelector:SetKeyboardInputEnabled(false)
					slideshowSelector:SetSize(500, 400)
					slideshowSelector:Center()
					slideshowSelector:SetTitle(txt_open)
					slideshowSelector.categorySel = vgui.Create("DComboBox", slideshowSelector); do
						local categorySel = slideshowSelector.categorySel
						categorySel:SetSize(466, 20)
						categorySel:SetPos(17, 41)
						categorySel:SetEnabled(false)
						categorySel:SetValue(
							hl == "fr" and
							"Chargement..." or
							"Loading..."
						)
						categorySel.OnSelect = function(self, index, value, data)
							slideshowSelector.cat = data
							slideshowSelector.title = nil
							net.Start("prop_teacher_computer_mr")
								net.WriteUInt(a.SlideshowOpen, 8)
								net.WriteUInt(2, 8) -- request for slideshows
								net.WriteString(slideshowSelector.cat)
							net.SendToServer()
							categorySel:SetEnabled(false)
							slideshowSelector.buttonOpen:SetEnabled(false)
							if IsValid(slideshowSelector.list_) then
								slideshowSelector.list_:Remove()
							end
						end
					end
					slideshowSelector.listBG = vgui.Create("DPanel", slideshowSelector); do
						local listBG = slideshowSelector.listBG
						listBG:SetSize(466, 268)
						listBG:SetPos(17, 78)
					end
					slideshowSelector.buttonOpen = vgui.Create("DButton", slideshowSelector); do
						local buttonOpen = slideshowSelector.buttonOpen
						buttonOpen:SetSize(224, 20)
						buttonOpen:SetPos(259, 363)
						buttonOpen:SetEnabled(false)
						buttonOpen:SetText(
							hl == "fr" and
							"Ouvrir" or
							"Open"
						)
						buttonOpen.DoClick = function()
							if slideshowSelector.cat and slideshowSelector.title then
								net.Start("prop_teacher_computer_mr")
									net.WriteUInt(a.SlideshowOpen, 8)
									net.WriteUInt(3, 8) -- open selected slideshow
									net.WriteString(slideshowSelector.cat)
									net.WriteString(slideshowSelector.title)
								net.SendToServer()
							end
							buttonOpen:SetEnabled(false)
						end
					end
					slideshowSelector.buttonCancel = vgui.Create("DButton", slideshowSelector); do
						local buttonCancel = slideshowSelector.buttonCancel
						buttonCancel:SetSize(224, 20)
						buttonCancel:SetPos(17, 363)
						buttonCancel:SetText(
							hl == "fr" and
							"Annuler" or
							"Cancel"
						)
						buttonCancel.DoClick = function()
							slideshowSelector:Remove()
						end
					end
					net.Start("prop_teacher_computer_mr")
						net.WriteUInt(a.SlideshowOpen, 8)
						net.WriteUInt(1, 8) -- request for categories
					net.SendToServer()
				end
			end
		end
		seatGui.slideshowClose = vgui.Create("DButton", seatGui); do
			local slideshowClose = seatGui.slideshowClose
			slideshowClose:SetPos(
				GUI_spacer + GUI_column2 + GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer
			)
			slideshowClose:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(slideshowClose, slideshow_close)
			slideshowClose:SetTooltip(
				hl == "fr" and
				"Fermer Diaporama" or
				"Close Slideshow"
			)
			slideshowClose.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.SlideshowClose, 8)
				net.SendToServer()
			end
		end
		seatGui.slideshowRun = vgui.Create("DButton", seatGui); do
			local slideshowRun = seatGui.slideshowRun
			slideshowRun:SetPos(
				GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer
			)
			slideshowRun:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(slideshowRun, slideshow_start)
			slideshowRun:SetTooltip(
				hl == "fr" and
				"Lancer Diaporama" or
				"Run Slideshow"
			)
			slideshowRun.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.SlideshowRun, 8)
				net.SendToServer()
			end
		end
		seatGui.slideshowExit = vgui.Create("DButton", seatGui); do
			local slideshowExit = seatGui.slideshowExit
			slideshowExit:SetPos(
				GUI_spacer + GUI_column2 + GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer
			)
			slideshowExit:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(slideshowExit, slideshow_stop)
			slideshowExit:SetTooltip(
				hl == "fr" and
				"Arrêter Diaporama" or
				"Stop Slideshow"
			)
			slideshowExit.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.SlideshowExit, 8)
				net.SendToServer()
			end
		end
	end
	updateSeatGui()
end

local createRemoteGui

local function removeRemoteGui()
	if IsValid(prop_teacher_computer_mr.remoteGui) then
		prop_teacher_computer_mr.remoteGui:Remove()
	end
end

local function updateRemoteGui()
	local ply = LocalPlayer()
	local computer, on_seat = prop_teacher_computer_mr.getComputerFromPlayer(ply)
	local shouldBeVisible = false
	if computer then
		if on_seat or ply:InVehicle() then
			shouldBeVisible = true
		else
			-- Note: it does not matter that the weapon may be owned by the spectated player.
			local activeWeapon = ply:GetActiveWeapon()
			if IsValid(activeWeapon) and activeWeapon:GetClass() == computer.RemoteWeaponClass then
				shouldBeVisible = true
			end
		end
	end
	if shouldBeVisible then
		if not IsValid(prop_teacher_computer_mr.remoteGui) then
			-- Re-create it if it was removed because the weapon was switched:
			createRemoteGui() 
		end
		local remoteGui = prop_teacher_computer_mr.remoteGui
		local slideSetPage = remoteGui.slideSetPage
		local state = computer:GetState()
		local filename = computer:GetFilename()
		if not computer:isComputerOn() or state == a.ComputerWake or state == a.ProgramOpen then
			slideSetPage:SetEnabled(false)
			slideSetPage:SetValue(
				hl == "fr" and
				"Pas chargé" or
				"Not loaded"
			)
		elseif state == a.SlideshowOpen or state == a.SlideshowRun then
			slideSetPage:SetEnabled(true)
		else
			slideSetPage:SetEnabled(false)
		end
		if state == a.SlideshowOpen or state == a.SlideshowRun then
			local slideshowPages = computer:GetSlideshowPages()
			local page = computer:GetPage()
			if slideshowPages ~= remoteGui.slideshowPages or filename ~= remoteGui.filename or page ~= remoteGui.page then
				if slideshowPages ~= remoteGui.slideshowPages then
					-- Re-create all the choices when a new document is loaded:
					slideSetPage:Clear()
					for p = 1, slideshowPages do
						slideSetPage:AddChoice(
							string.format(
								(
									hl == "fr" and
									"Diapo %02u" or
									"Slide %02u"),
								p
							),
							p,
							false
						)
					end
				end
				if slideshowPages > 0 then
					slideSetPage:SetValue(string.format(
						(
							hl == "fr" and
							"Diapo %u / %u" or
							"Slide %u / %u"),
						page,
						slideshowPages
					))
				else -- should not happen
					slideSetPage:SetValue(string.format(
						(
							hl == "fr" and
							"Diapo %02u" or
							"Slide %02u"),
						page
					))
				end
				remoteGui.slideshowPages = slideshowPages
				remoteGui.page = page
				remoteGui.filename = filename
			end
		end
		if IsValid(computer:GetProjector()) then
			remoteGui.screenOpen:SetDisabled(false)
			remoteGui.screenClose:SetDisabled(false)
		else
			remoteGui.screenOpen:SetDisabled(true)
			remoteGui.screenClose:SetDisabled(true)
		end
		if IsValid(computer:GetProjectorScreen()) then
			remoteGui.projectorOn:SetDisabled(false)
			remoteGui.projectorOff:SetDisabled(false)
		else
			remoteGui.projectorOn:SetDisabled(true)
			remoteGui.projectorOff:SetDisabled(true)
		end
	elseif IsValid(prop_teacher_computer_mr.remoteGui) then
		removeRemoteGui()
	end
end

local function remoteGuiPaint(self, w, h)
	draw.RoundedBoxEx(
		12,
		0, 0,
		w, h,
		self:GetBackgroundColor(),
		false, false, true, true
	)
end

function createRemoteGui() -- remote + keyboard
	if IsValid(prop_teacher_computer_mr.remoteGui) then
		prop_teacher_computer_mr.remoteGui:Remove()
	end
	prop_teacher_computer_mr.remoteGui = vgui.Create("DPanel"); do
		local remoteGui = prop_teacher_computer_mr.remoteGui
		remoteGui.Paint = remoteGuiPaint
		remoteGui:SetPaintBackground(true)
		remoteGui:SetBackgroundColor(GUI_background)
		local ply = LocalPlayer()
		local scr_W, scr_H = ScrW(), ScrH()
		remoteGui:SetSize(
			108,
			5*GUI_spacer + 2*GUI_buttontall + GUI_nextprevtall + GUI_listtall
		)
		remoteGui:SetPos(
			scr_W - 109,
			1 + 5*GUI_spacer + 4*GUI_buttontall
		)
		remoteGui.screenOpen = vgui.Create("DButton", remoteGui); do
			local screenOpen = remoteGui.screenOpen
			screenOpen:SetPos(GUI_spacer, GUI_spacer)
			screenOpen:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(screenOpen, screen_open)
			screenOpen:SetTooltip(
				hl == "fr" and
				"Ouvrir Écran" or
				"Open Screen"
			)
			screenOpen.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.ScreenOpen, 8)
				net.SendToServer()
			end
		end
		remoteGui.screenClose = vgui.Create("DButton", remoteGui); do
			local screenClose = remoteGui.screenClose
			screenClose:SetPos(
				GUI_spacer + GUI_column2 + GUI_spacer,
				GUI_spacer
			)
			screenClose:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(screenClose, screen_close)
			screenClose:SetTooltip(
				hl == "fr" and
				"Fermer Écran" or
				"Close Screen"
			)
			screenClose.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.ScreenClose, 8)
				net.SendToServer()
			end
		end
		remoteGui.projectorOn = vgui.Create("DButton", remoteGui); do
			local projectorOn = remoteGui.projectorOn
			projectorOn:SetPos(
				GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer
			)
			projectorOn:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(projectorOn, projector_on)
			projectorOn:SetTooltip(
				hl == "fr" and
				"Allumer Projecteur" or
				"Turn Projector On"
			)
			projectorOn.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.ProjectorOn, 8)
				net.SendToServer()
			end
		end
		remoteGui.projectorOff = vgui.Create("DButton", remoteGui); do
			local projectorOff = remoteGui.projectorOff
			projectorOff:SetPos(
				GUI_spacer + GUI_column2 + GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer
			)
			projectorOff:SetSize(GUI_column2, GUI_buttontall)
			setupImageButton(projectorOff, projector_off)
			projectorOff:SetTooltip(
				hl == "fr" and
				"Éteindre Projecteur" or
				"Turn Projector Off"
			)
			projectorOff.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.ProjectorOff, 8)
				net.SendToServer()
			end
		end
		remoteGui.slidePrevious = vgui.Create("DButton", remoteGui); do
			local slidePrevious = remoteGui.slidePrevious
			slidePrevious:SetPos(
				GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer
			)
			slidePrevious:SetSize(GUI_column2, GUI_nextprevtall)
			setupImageButton(slidePrevious, slide_previous)
			slidePrevious:SetTooltip(
				hl == "fr" and
				"Précédent" or
				"Previous"
			)
			slidePrevious.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.SlidePrevious, 8)
				net.SendToServer()
				local computer = prop_teacher_computer_mr.getComputerFromPlayer(ply)
				if computer then
					computer:actionSlidePrevious()
				end
			end
			slidePrevious.DoDoubleClick = slidePrevious.DoClick
		end
		remoteGui.slideNext = vgui.Create("DButton", remoteGui); do
			local slideNext = remoteGui.slideNext
			slideNext:SetPos(
				GUI_spacer + GUI_column2 + GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer
			)
			slideNext:SetSize(GUI_column2, GUI_nextprevtall)
			setupImageButton(slideNext, slide_next)
			slideNext:SetTooltip(
				hl == "fr" and
				"Suivant" or
				"Next"
			)
			slideNext.DoClick = function()
				net.Start("prop_teacher_computer_mr")
					net.WriteUInt(a.SlideNext, 8)
				net.SendToServer()
				local computer = prop_teacher_computer_mr.getComputerFromPlayer(ply)
				if computer then
					computer:actionSlideNext()
				end
			end
			slideNext.DoDoubleClick = slideNext.DoClick
		end
		remoteGui.slideSetPage = vgui.Create("DComboBox", remoteGui); do
			local slideSetPage = remoteGui.slideSetPage
			slideSetPage:SetPos(
				GUI_spacer,
				GUI_spacer + GUI_buttontall + GUI_spacer + GUI_buttontall + GUI_spacer + GUI_nextprevtall + GUI_spacer
			)
			slideSetPage:SetSize(
				GUI_column2 + GUI_spacer + GUI_column2,
				GUI_listtall
			)
			slideSetPage:SetEnabled(false)
			slideSetPage.OnSelect = function(self, index, value, page)
				if page and page > 0 then
					net.Start("prop_teacher_computer_mr")
						net.WriteUInt(a.SlideSetPage, 8)
						net.WriteUInt(page, 16)
					net.SendToServer()
					local computer = prop_teacher_computer_mr.getComputerFromPlayer(ply)
					if computer then
						computer:actionSlideSetPage(page)
					end
				end
			end
		end
	end
	updateRemoteGui()
end

function ENT:playerEntered(ply)
	if ply == LocalPlayer() then
		createSeatGui()
		createRemoteGui()
	end
end

local function playerLeft(self, ply)
	if ply == LocalPlayer() then
		removeSeatGui()
		if not IsValid(self) or self:GetRemoteOwner() ~= ply then
			removeRemoteGui()
		end
	end
end
ENT.playerLeft = playerLeft

do
	local lastComputerSeat -- nil at startup/refresh, ideal to reset the GUI
	local lastComputer
	hook.Add("Think", "prop_teacher_computer_mr:cl", function()
		local ply = LocalPlayer()
		local seat = ply:GetVehicle()
		seat = IsValid(seat) and seat or nil
		if seat ~= lastComputerSeat then
			if IsValid(seat) then
				local computer = prop_teacher_computer_mr.getComputerFromSeat(seat)
				if computer then
					lastComputerSeat = seat
					lastComputer = computer
					computer:playerEntered(ply)
				end
			else
				if IsValid(lastComputerSeat) then
					if IsValid(lastComputer) then
						lastComputer:playerLeft(ply) -- known computer
					else
						playerLeft(nil, ply) -- unknown computer
					end
				else
					playerLeft(nil, ply) -- unknown computer
				end
				lastComputerSeat = nil
				lastComputer = nil
			end
		end
		pcall(updateSeatGui)
		pcall(updateRemoteGui)
	end)
end


-- Simple quotes (') are disallowed in these 3 variables:
local webHead
local webBody
local webPage
do
	local pictures = {}
	local function loadPicture(name, filename)
		pictures[name] = util.Base64Encode(file.Read(filename, "GAME") or "")
	end
	loadPicture("screen_desktop", "materials/" .. materialPathScreenDesktop_png)
	loadPicture("screen_openoffice_welcome", "materials/vgui/prop_teacher_computer_mr/screen/screen_openoffice_welcome_fr.png")
	loadPicture("screen_openoffice_loaded", "materials/vgui/prop_teacher_computer_mr/screen/screen_openoffice_loaded_fr.png")
	-- webHead and webBody must contain no simple quotes (for JavaScript)!
	webHead = [[<style type="text/css">
		body{
			background-color: #808080;
			overflow: hidden;
		}
		table, tr, td{
			padding: 0px;
			border: 0px none;
			margin: 0px;
			border-collapse: collapse;
		}
		.fullpage{
			position: absolute;
			left: 0px;
			top: 0px;
			width: 100%;
			height: 100%;
			z-index: 0;
		}
		table.clock{
			position: absolute;
			left: ]] .. (982 * scaleToDesign) .. [[px;
			top: ]] .. (745 * scaleToDesign) .. [[px;
			z-index: 2;
		}
		#clock{
			font: ]] .. (8 * scaleToDesign) .. [[pt "MS Sans Serif", "Microsoft Sans Serif", sans-serif;
			vertical-align: middle;
			text-align: center;
			width: ]] .. (37 * scaleToDesign) .. [[px;
			height: ]] .. (20 * scaleToDesign) .. [[px;
		}
		#title_windowbar{
			font: bold ]] .. (8 * scaleToDesign) .. [[pt "MS Sans Serif", "Microsoft Sans Serif", sans-serif;
			color: white;
			overflow-x: hidden;
			text-overflow: ellipsis;
			white-space: nowrap;
			position: absolute;
			left: ]] .. (20 * scaleToDesign) .. [[px;
			top: ]] .. (2 * scaleToDesign) .. [[px;
			width: ]] .. (950 * scaleToDesign) .. [[px;
			height: ]] .. (16 * scaleToDesign) .. [[px;
			z-index: 2;
		}
		#title_taskbar{
			font: bold ]] .. (8 * scaleToDesign) .. [[pt "MS Sans Serif", "Microsoft Sans Serif", sans-serif;
			color: black;
			overflow-x: hidden;
			text-overflow: ellipsis;
			white-space: nowrap;
			position: absolute;
			left: ]] .. (106 * scaleToDesign) .. [[px;
			top: ]] .. (749 * scaleToDesign) .. [[px;
			width: ]] .. (133 * scaleToDesign) .. [[px;
			height: ]] .. (15 * scaleToDesign) .. [[px;
			z-index: 2;
		}
		#current_folder{
			position: absolute;
			left: 0px;
			top: 0px;
			width: 0px;
			height: 0px;
			z-index: 2;
		}
		.file_folder{
		}
		.file_folder_selected{
		}
		.slideshow{
			position: absolute;
			left: 0px;
			top: 0px;
			width: 100%;
			height: 100%;
			border: 0px none;
			overflow: hidden;
			z-index: 3;
		}
		#preview_main{
			position: absolute;
			left: ]] .. (226 * scaleToDesign) .. [[px;
			top: ]] .. (129 * scaleToDesign) .. [[px;
			width: ]] .. (708 * scaleToDesign) .. [[px;
			height: ]] .. (531 * scaleToDesign) .. [[px;
			z-index: 2;
		}
		#preview_1{
			position: absolute;
			left: ]] .. (39 * scaleToDesign) .. [[px;
			top: ]] .. (127 * scaleToDesign) .. [[px;
			width: ]] .. (125 * scaleToDesign) .. [[px;
			height: ]] .. (94 * scaleToDesign) .. [[px;
			z-index: 2;
		}
		#preview_2{
			position: absolute;
			left: ]] .. (39 * scaleToDesign) .. [[px;
			top: ]] .. (242 * scaleToDesign) .. [[px;
			width: ]] .. (125 * scaleToDesign) .. [[px;
			height: ]] .. (94 * scaleToDesign) .. [[px;
			z-index: 2;
		}
		#preview_3{
			position: absolute;
			left: ]] .. (39 * scaleToDesign) .. [[px;
			top: ]] .. (357 * scaleToDesign) .. [[px;
			width: ]] .. (125 * scaleToDesign) .. [[px;
			height: ]] .. (94 * scaleToDesign) .. [[px;
			z-index: 2;
		}
		#preview_4{
			position: absolute;
			left: ]] .. (39 * scaleToDesign) .. [[px;
			top: ]] .. (472 * scaleToDesign) .. [[px;
			width: ]] .. (125 * scaleToDesign) .. [[px;
			height: ]] .. (94 * scaleToDesign) .. [[px;
			z-index: 2;
		}
		#preview_5{
			position: absolute;
			left: ]] .. (39 * scaleToDesign) .. [[px;
			top: ]] .. (587 * scaleToDesign) .. [[px;
			width: ]] .. (125 * scaleToDesign) .. [[px;
			height: ]] .. (94 * scaleToDesign) .. [[px;
			z-index: 2;
		}
	</style>]]
	
	webBody = [[<img class="fullpage" id="screen_desktop" src="data:image/png;base64,]] .. pictures.screen_desktop .. [[" />
		<img class="fullpage" id="screen_openoffice_welcome" src="data:image/png;base64,]] .. pictures.screen_openoffice_welcome .. [[" style="visibility:hidden;" />
		<img class="fullpage" id="screen_openoffice_loaded" src="data:image/png;base64,]] .. pictures.screen_openoffice_loaded .. [[" style="visibility:hidden;" />
		<img id="preview_main" src="" style="visibility:hidden;" />
		<img id="preview_1" src="" style="visibility:hidden;" />
		<img class="slideshow" id="slideshow_img_0" src="about:blank" style="visibility:hidden;" />
		<iframe class="slideshow" id="slideshow_iframe_0" src="" style="visibility:hidden;" scrolling="no"></iframe>
		<table class="clock"><tr><td id="clock"></td></tr></table>
		<div id="title_windowbar"></div>
		<div id="title_taskbar"></div>]]
	
	-- Remove new lines:
	webHead = string.gsub(webHead, "[%c]", " ")
	webBody = string.gsub(webBody, "[%c]", "")
	
	webPage = [[<html>
	<head>
		]] .. webHead .. [[
	</head>
	<body>
		]] .. webBody .. [[
	</body>
	</html>]]
end

local LoadingTextFont = "prop_teacher_computer_mr_loading64"
local LoadingTextHeight = 64
local LoadingTextColor = {255, 255, 255}
surface.CreateFont(LoadingTextFont, {
	extended = true,
	size = LoadingTextHeight,
	outline = true,
} )
local LoadingAnimFont = "prop_teacher_computer_mr_loading48"
local LoadingAnimHeight = 48
local LoadingAnimColor = {255, 255, 255}
surface.CreateFont(LoadingAnimFont, {
	extended = true,
	size = LoadingAnimHeight,
	outline = true,
})

do
	local loadingAnim
	do
		-- Animated line as loading animation:
		local list_ = {
			"░░░░░░░░",
			"░▓░░░░░░",
			"░░▓░░░░░",
			"░░░▓░░░░",
			"░░░░▓░░░",
			"░░░░░▓░░",
			"░░░░░░▓░",
			"░░░░░░░▓",
		}
		function loadingAnim()
			return list_[math.floor(((RealTime() * #list_) % #list_) + 1)]
		end
	end
	
	local htmlRenderer_drawLoadingOverlay
	do
		local loadingText = (
			hl == "fr" and
			"Chargement" or
			"Loading"
		)
		local pageText = (
			hl == "fr" and
			"Diapo %u" or
			"Slide %u"
		)
		
		function htmlRenderer_drawLoadingOverlay(self, w, h, isGuiOverlay)
			if self:IsLoading() then
				if isGuiOverlay then
					-- On the on-screen full page overlay, manually paint the HTML material instead of letting it invisible during loading state:
					local materialHtml = self:GetHTMLMaterial()
					if materialHtml then
						surface.SetDrawColor(255, 255, 255)
						surface.SetMaterial(materialHtml)
						surface.DrawTexturedRect(0, 0, materialHtml:Width(), materialHtml:Height())
					end
				end
				if IsValid(self.computer) and self.computer:GetState() == a.SlideshowRun then
					local page = self.computer:GetPage()
					if page > 0 then
						--draw.NoTexture()
						--surface.SetDrawColor(127, 127, 127, 127)
						--surface.DrawTexturedRect(0, 0, w, h)
						surface.SetTextColor(unpack(LoadingTextColor))
						if self:getLoadingType() == 0 then
							surface.SetFont(LoadingTextFont)
							local text_w, text_h = nil, LoadingTextHeight
							local text_x, text_y
							local text = loadingText; do
								text_w = surface.GetTextSize(text)
								text_x, text_y = (w - text_w) / 2, (h / 2) - (text_h * 1.5)
								surface.SetTextPos(text_x, text_y)
								surface.DrawText(text)
							end
							local text = string.format(pageText, page); do
								text_w = surface.GetTextSize(text)
								text_x, text_y = (w - text_w) / 2, text_y + text_h
								surface.SetTextPos(text_x, text_y)
								surface.DrawText(text)
							end
							local text = loadingAnim(); do
								text_w = surface.GetTextSize(text)
								text_x, text_y = (w - text_w) / 2, text_y + text_h
								surface.SetTextPos(text_x, text_y)
								surface.DrawText(text)
							end
						else
							surface.SetFont(LoadingAnimFont)
							local text_h = LoadingAnimHeight
							local text = loadingAnim()
							local text_w = surface.GetTextSize(text)
							local text_x, text_y = (w - text_w) / 2, h - text_h
							surface.SetTextPos(text_x, text_y)
							surface.DrawText(text)
						end
					end
				end
			end
		end
	end
	
	local function htmlRenderer_PaintOver(self, w, h)
		-- Painted on the on-screen full page view:
		self:drawLoadingOverlay(w, h, true)
	end
	
	local htmlRenderer_setLoadingType
	local htmlRenderer_getLoadingType
	do
		local loadingType = 0 -- 0=current page, 1=preloading
		function htmlRenderer_setLoadingType(type_)
			loadingType = type_
		end
		function htmlRenderer_getLoadingType()
			return loadingType
		end
	end
	
	function ENT:createHtmlRenderer()
		self.lastScreenDrawn = self.lastScreenDrawn or 0.
		self.htmlRenderer = vgui.Create("DHTML")
		self.htmlRenderer:SetSize(renderW, renderH)
		self.htmlRenderer:SetAlpha(0) -- The panel is drawn on the screen, so we hide it.
		self.htmlRenderer:SetMouseInputEnabled(false)
		self.htmlRenderer:SetKeyboardInputEnabled(false)
		self.htmlRenderer:SetHTML(webPage)
		self.htmlRenderer:MoveToBack()
		self.htmlRenderer:Center()
		self.htmlRenderer.lastKnown = {} -- contains last known values, required for updates
		self.htmlRenderer.computer = self
		
		--[[
		do
			local loadedSince = 0. -- ready time
			-- A delay of 0.5 seconds seems okay not to hurry Awesomium and do the preload properly. (?)
			function self.htmlRenderer:getLoadedSince() -- unused
				if loadedSince == 0. then
					return 0.
				else
					return RealTime() - loadedSince
				end
			end
			function self.htmlRenderer:resetLoadedSince() -- unused
				loadedSince = 0.
			end
			local old_Think = self.htmlRenderer.Think
			function self.htmlRenderer:Think()
				if self:IsLoading() then
					loadedSince = 0.
				else
					loadedSince = RealTime()
				end
				return old_Think(self)
			end
		end
		]]
		self.htmlRenderer.drawLoadingOverlay = htmlRenderer_drawLoadingOverlay
		self.htmlRenderer.PaintOver = htmlRenderer_PaintOver
		self.htmlRenderer.getLoadingType = htmlRenderer_getLoadingType
		self.htmlRenderer.setLoadingType = htmlRenderer_setLoadingType
		self.htmlRenderer.computer = self
	end
end

function ENT:Think()
	if not self:isComputerOn() then
		if IsValid(self.htmlRenderer) then
			self.htmlRenderer:Remove()
			self.state = nil -- force a state change to occur
		end
	end
	local now = RealTime()
	local remove = false
	if IsValid(self.htmlRenderer) and now > self.lastScreenDrawn + DisplayTimeout_s then
		local room1, room2
		if rooms_lib_mr then
			room1 = rooms_lib_mr.getRoom(self)
			room2 = rooms_lib_mr.getRoom(LocalPlayer())
		end
		if (not room1 and not room2) or room1 ~= room2 then -- none in a room or both in different rooms
			remove = true -- will be removed on any change or if current URL is a video; no performance impact for idle desks
		end
	end
	if IsValid(self.htmlRenderer) then -- checking if not self.htmlRenderer:IsLoading() is dangerous because loading external contents must be ignored
		local state = self:GetState()
		local lastKnown = self.htmlRenderer.lastKnown
		if state ~= self.state -- self.state is nil at the beginning
		or lastKnown.page1Url ~= self:GetPreviewUrl()
		or lastKnown.previousUrl ~= self:GetPreviousUrl()
		or lastKnown.currentUrl ~= self:GetCurrentUrl()
		or lastKnown.nextUrl ~= self:GetNextUrl()
		or lastKnown.filename ~= self:GetFilename() then -- situation just changed
			if remove then
				self.htmlRenderer:Remove() -- marked as "to remove" and change occured
			else
				-- self.nextForceStateChange = now + math.random(0.7, 1.0)
				lastKnown.page1Url = self:GetPreviewUrl()
				lastKnown.previousUrl = self:GetPreviousUrl()
				lastKnown.currentUrl = self:GetCurrentUrl()
				lastKnown.nextUrl = self:GetNextUrl()
				lastKnown.filename = self:GetFilename() -- new values of filename are usually late
				if not self.htmlRenderer.fixingOrigin and not self.htmlRenderer.fixedOrigin then
					local rootUrl = prop_teacher_computer_mr.getSameOriginFixingUrl(lastKnown.currentUrl)
					if rootUrl then
						self.htmlRenderer:OpenURL(rootUrl)
						self.htmlRenderer.fixingOrigin = true
					end
				end
				self.state = state
				self:onStateChange(false)
			end
		elseif self.htmlRenderer.fixingOrigin and not self.htmlRenderer:IsLoading() then -- origin just fixed
			if self.htmlRenderer.fixingOrigin then
				self.htmlRenderer:RunJavascript(
					[[document.body.innerHTML = ']] .. webBody .. [[';
					document.head.innerHTML = ']] .. webHead .. [[';]]
				)
				self.htmlRenderer.fixingOrigin = false
				self.htmlRenderer.fixedOrigin = true
			end
			-- self.nextForceStateChange = now + math.random(0.7, 1.0)
			self:onStateChange(true)
		end
		if remove and prop_teacher_computer_mr.isVideoUrl(lastKnown.currentUrl) then
			self.htmlRenderer:Remove() -- marked as "to remove" and video playing
		elseif IsValid(self.htmlRenderer) then
			if state ~= a.SlideshowOpen and state ~= a.SlideshowRun then
				-- Unloaded slideshow: new possibility of fixing origin.
				self.htmlRenderer.fixingOrigin = nil
				self.htmlRenderer.fixedOrigin = nil
			end
		end
	end
	self:SetNextClientThink(CurTime())
	return true
end

-- Screen content methods:

function ENT:setClock(clockText)
	self.htmlRenderer:RunJavascript(
		[[document.getElementById("clock").innerHTML = "]] .. clockText.. [[";]]
	)
	self.htmlRenderer.clockText = clockText
end

function ENT:setProgramTitle(text)
	self.htmlRenderer:RunJavascript(
		[[document.getElementById("title_windowbar").innerHTML = "]] .. text .. [[";
		document.getElementById("title_taskbar").innerHTML = "]] .. text .. [[";]]
	)
end

do
	local views = {"screen_desktop", "screen_openoffice_welcome", "screen_openoffice_loaded"} -- true: fullscreen slideshow
	local previews = {"preview_main", "preview_1"}
	local keepSlideshow = {["screen_openoffice_loaded"] = true} -- keep slideshow loaded
	
	local function JS_HideElementId(jsCode, id)
		table.insert(jsCode, string.format(
			'document.getElementById("%s").style.visibility = "hidden";',
			id
		))
	end
	
	local function JS_ShowElementId(jsCode, id)
		table.insert(jsCode, string.format(
			'document.getElementById("%s").style.visibility = "visible";',
			id
		))
	end
	
	local function JS_LoadUrlHtml(jsCode, id, url, forced)
		table.insert(jsCode, string.format(
			[[(function(){
				var id = "%s";
				var url = "%s";
				var elt = document.getElementById(id);
				elt.style.visibility = "visible";
				if(elt.src != url){
					elt.src = url;
					%s
				}
			})();]],
			id,
			url,
			(dev_mode and not forced and 'console.log(id + " moved to " + url);' or '')
		))
	end
	
	local function JS_LoadUrlPicture(jsCode, id, url, forced)
		-- Setup a URL into the <img> with the specified id:
		
		url = url or "about:blank"
		table.insert(jsCode, string.format(
			[[(function(){
				var id = "%s";
				var url = "%s";
				var elt = document.getElementById(id);
				elt.style.visibility = "visible";
				if(elt.src != url){
					elt.src = url;
					%s
				}
			})();]],
			id,
			url,
			(dev_mode and not forced and 'console.log(id + " moved to " + url);' or '')
		))
	end
	
	local function JS_ClearUrlHtml(jsCode, id, forced)
		table.insert(jsCode, string.format(
			[[(function(){
				var id = "%s";
				var elt = document.getElementById(id);
				elt.style.visibility = "hidden";
				if(elt.src != ""){
					elt.src = "";
					%s
				}
			})();]],
			id,
			(dev_mode and not forced and 'console.log(id + " moved to empty URL");' or '')
		))
	end
	
	local function JS_ClearUrlPicture(jsCode, id, forced)
		table.insert(jsCode, string.format(
			[[(function(){
				var id = "%s";
				var elt = document.getElementById(id);
				elt.style.visibility = "hidden";
				if(elt.src != "about:blank"){
					elt.src = "about:blank";
					%s
				}
			})();]],
			id,
			(dev_mode and not forced and 'console.log(id + " moved to empty URL");' or '')
		))
	end
	
	function ENT:htmlShowScreen(id, forced)
		-- forced: there was no natural change
		if IsValid(self.htmlRenderer) then
			local ply = LocalPlayer()
			local jsCode = {}
			for _, view in ipairs(views) do
				if view == id then
					JS_ShowElementId(jsCode, view)
				else
					JS_HideElementId(jsCode, view)
				end
			end
			local page = self:GetPage()
			local url
			if id == true and page >= 0 then -- slideshow active
				local urls = {self:GetPreviousUrl(), self:GetCurrentUrl(), self:GetNextUrl()}
				url = urls[2]
				if page > 0 and string.len(url) ~= 0 then
					if prop_teacher_computer_mr.isPictureUrl(url) then
						if dev_mode and not forced then LocalPlayer():ChatPrint("slideshow_img_0 is moving to " .. url) end
						JS_LoadUrlPicture(jsCode, "slideshow_img_0", url, forced)
						JS_ClearUrlHtml(jsCode, "slideshow_iframe_0", forced) -- unload iframes when URL is picture (prevent background video)
					else
						if prop_teacher_computer_mr.isYouTubeUrl(url) then -- current page is YouTube video
							-- Translate the YouTube player:
							url = url .. "&hl=" .. hl
							-- Set the start position properly:
							local start = self:GetVideoPosition_s()
							if start > 0 then
								url = url .. "&start=" .. start -- fix the start
							end
							-- Only play if connected to a projector or local player is the owner:
							if IsValid(self:GetProjector()) or prop_teacher_computer_mr.getComputerFromPlayer(ply) then
								url = url .. "&autoplay=1"
							end
						end
						if dev_mode and not forced then LocalPlayer():ChatPrint("slideshow_iframe_0 is moving to " .. url) end
						JS_LoadUrlHtml(jsCode, "slideshow_iframe_0", url, forced)
						JS_ClearUrlPicture(jsCode, "slideshow_img_0", forced) -- unload imgs when URL is HTML (prevent showing of previous picture)
					end
				else -- invalid page number
					JS_ClearUrlPicture(jsCode, "slideshow_img_0", forced) -- unload imgs when URL is HTML (prevent showing of previous picture)
					if dev_mode and not forced then LocalPlayer():ChatPrint("slideshow_iframe_0 is moving to empty URL") end
					JS_ClearUrlHtml(jsCode, "slideshow_iframe_0", forced) -- unload iframes when empty URL (prevent background video)
				end
			else -- slideshow inactive
				JS_ClearUrlPicture(jsCode, "slideshow_img_0", forced) -- unload imgs when URL is HTML (prevent showing of previous picture)
				if dev_mode and not forced then LocalPlayer():ChatPrint("slideshow_iframe_0 is moving to empty URL") end
				JS_ClearUrlHtml(jsCode, "slideshow_iframe_0", forced) -- unload iframes when slideshow inactive (prevent background video)
			end
			-- Previews:
			url = nil
			if keepSlideshow[id] or id == true then -- slideshow opened
				url = self:GetPreviewUrl()
				if not prop_teacher_computer_mr.isPictureUrl(url) then
					url = nil
				end
			end
			if url then
				for _, page_id in ipairs(previews) do
					JS_LoadUrlPicture(jsCode, page_id, url, forced)
				end
			else
				for _, page_id in ipairs(previews) do
					-- hide previews:
					JS_ClearUrlPicture(jsCode, page_id, forced)
				end
			end
			-- Run JS:
			self.htmlRenderer:RunJavascript(table.concat(jsCode))
		end
	end
end

do
	local actionToScreen = {
		-- Associate an HTML id to every action:
		[a.ComputerWake] = "screen_desktop",
		[a.ProgramClose] = "screen_desktop",
		[a.ProgramOpen] = "screen_openoffice_welcome",
		[a.SlideshowClose] = "screen_openoffice_welcome",
		[a.SlideshowExit] = "screen_openoffice_loaded",
		[a.SlideshowOpen] = "screen_openoffice_loaded",
		[a.SlideshowRun] = true,
	}
	function ENT:onStateChange(forced)
		local state = self.state
		local id = actionToScreen[state]
		if id ~= nil then
			self:htmlShowScreen(id, forced)
		end
		if state == a.SlideshowOpen or state == a.SlideshowRun then
			self:setProgramTitle(self:GetFilename() .. " - OpenOffice Impress")
		else
			self:setProgramTitle("")
		end
	end
end

do
	local fixHdr = true -- only once per frame
	local fixHdrOnce = true
	
	function prop_teacher_computer_mr.fixHdr()
		-- Apply HDR fixes to get a proper fullbright display on screens:
		
		if fixHdr then
			fixHdr = false
			if fixHdrOnce then
				fixHdrOnce = nil
				RunConsoleCommand("mat_disable_bloom", "1")
				print("[prop_teacher_computer_mr] HDR bloom has been disabled.")
			end
			render.ResetToneMappingScale(1.)
		end
	end
	
	hook.Add("PostRender", "prop_teacher_computer_mr:fixHdr:cl", function()
		fixHdr = true
	end)
end

do
	prop_teacher_computer_mr.materialsHtmlSmoothAll = prop_teacher_computer_mr.materialsHtmlSmoothAll or {}
	prop_teacher_computer_mr.texturesHtmlSmooth = prop_teacher_computer_mr.texturesHtmlSmooth or {}
	local materialsHtmlSmoothAvailable = {}
	local materialsHtmlSmoothUsage = {}
	local texturesHtmlSmooth = {}
	
	for _, materialHtmlSmooth in ipairs(prop_teacher_computer_mr.materialsHtmlSmoothAll) do
		texturesHtmlSmooth[materialHtmlSmooth] = materialHtmlSmooth:GetTexture("$basetexture")
	end
	
	hook.Add("PostRender", "prop_teacher_computer_mr:materialsHtmlSmooth:cl", function()
		materialsHtmlSmoothAvailable = {}
		for _, materialHtmlSmooth in ipairs(prop_teacher_computer_mr.materialsHtmlSmoothAll) do
			materialsHtmlSmoothAvailable[materialHtmlSmooth] = true
		end
		materialsHtmlSmoothUsage = {}
	end)
	
	function ENT:getMaterialHtmlSmooth()
		-- Returns an available smooth HTML copy material and its texture:
		
		local materialHtmlSmooth = materialsHtmlSmoothUsage[self] or next(materialsHtmlSmoothAvailable)
		if not materialHtmlSmooth then
			-- A new material must be created:
			local materialId = #prop_teacher_computer_mr.materialsHtmlSmoothAll + 1
			local materialName = "prop_teacher_computer_mr_" .. materialId
			-- Using a rendertarget instead of the HTML texture provides 3 benefits: smoothing, higher FPS, no material resize needed, possible overlay.
			materialHtmlSmooth = makeScreenMaterial(materialName)
			prop_teacher_computer_mr.materialsHtmlSmoothAll[materialId] = materialHtmlSmooth
			local textureHtmlSmooth = GetRenderTargetEx(
				materialName,
				renderW, renderH,
				bit.bor(RT_SIZE_LITERAL, RT_SIZE_OFFSCREEN),
				MATERIAL_RT_DEPTH_NONE,
				bit.bor(0x4, 0x8, 0x2000000, 0x10, 0x100, 0x200), -- https://developer.valvesoftware.com/wiki/Valve_Texture_Format
				0,
				IMAGE_FORMAT_RGB888
			)
			materialHtmlSmooth:SetTexture("$basetexture", textureHtmlSmooth)
			texturesHtmlSmooth[materialHtmlSmooth] = textureHtmlSmooth
		end
		materialsHtmlSmoothAvailable[materialHtmlSmooth] = nil
		materialsHtmlSmoothUsage[self] = materialHtmlSmooth
		return materialHtmlSmooth, texturesHtmlSmooth[materialHtmlSmooth]
	end
end

do
	local lastClockRefreshed = 0.
	local clockText
	
	local camRenderSmooth = {
		x = 0,
		y = 0,
		w = renderW,
		h = renderH,
		type = "2D",
	}
	
	local function inGameClock()
		local time = GetGlobalInt("URP_clock")
		local h, m, s
		if time == -1 then -- Atmos missing or disabled
			local clock = os.date("*t", os.time())
			time = (clock.hour * 3600) + (clock.min * 60) + clock.sec
			h, m, s = clock.hour, clock.min, clock.sec
		else
			s = time
			h = math.floor(s / 3600)
			s = s - (h * 3600)
			m = math.floor(s / 60)
			s = s - (m * 60)
		end
		return h, m, s
	end
	
	function ENT:linkedScreenDrawn()
		-- Renders the HTML content of the screens (for both computer screen & projector screen)
		-- Creates the HTML panel and the materials if needed
		-- Returns the smooth material on which the HTML view was copied.
		
		if IsValid(self) and self:isComputerOn() then
			local materialHtmlSmooth, textureHtmlSmooth = prop_teacher_computer_mr.materialScreenUnloaded, nil
			prop_teacher_computer_mr.fixHdr()
			self.lastScreenDrawn = self.lastScreenDrawn or 0.
			local now = RealTime()
			if now ~= self.lastScreenDrawn then -- prevent rendering the screen on several times
				self.lastScreenDrawn = now
				if not IsValid(self.htmlRenderer) then
					self.materialHtml = nil
					local room1, room2
					if rooms_lib_mr then
						room1 = rooms_lib_mr.getRoom(self)
						room2 = rooms_lib_mr.getRoom(LocalPlayer())
					end
					if room1 == room2 then -- none in a room or both in same room
						self:createHtmlRenderer()
					end
				else
					local materialHtml = self.htmlRenderer:GetHTMLMaterial()
					if materialHtml and materialHtml ~= self.materialHtml then
						-- set the required $ignorez material flag:
						materialHtml:SetInt("$flags", bit.bor(32768, materialHtml:GetInt("$flags")))
					end
					self.materialHtml = materialHtml
					-- self.materialHtml is available a few moments after calling self:createHtmlRenderer().
				end
				if self.materialHtml then -- available a bit later
					-- only if HTML material:
					materialHtmlSmooth, textureHtmlSmooth = self:getMaterialHtmlSmooth()
					if textureHtmlSmooth then
						render.PushRenderTarget(textureHtmlSmooth)
							camRenderSmooth.w = textureHtmlSmooth:Width()
							camRenderSmooth.h = textureHtmlSmooth:Height()
							cam.Start(camRenderSmooth)
								local success, message = pcall(function()
									surface.SetDrawColor(255, 255, 255)
									surface.SetMaterial(self.materialHtml)
									surface.DrawTexturedRect(0, 0, self.materialHtml:Width(), self.materialHtml:Height())
									self.htmlRenderer:drawLoadingOverlay(renderW, renderH, false)
								end)
								if not success then
									ErrorNoHalt(message .. "\n")
								end
							cam.End2D()
						render.PopRenderTarget()
					end
					if now ~= lastClockRefreshed then -- maximum 1 refreshed clock per frame
						local h, m = inGameClock()
						clockText = string.format("%02u:%02u", h, m)
						if clockText ~= self.htmlRenderer.clockText then
							self:setClock(clockText) -- refresh clock
							lastClockRefreshed = now
						end
					end
				end
			else
				if self.materialHtml then
					-- only if HTML material (otherwise textureHtmlSmooth would have obsolete content):
					materialHtmlSmooth, textureHtmlSmooth = self:getMaterialHtmlSmooth()
				end
			end
			return materialHtmlSmooth, textureHtmlSmooth
		end
	end
end

-- Live-reload cleanup (must be at the end of the file):
prop_teacher_computer_mr.materialScreenUnloaded = nil
timer.Simple(0., function()
	for computer in pairs(prop_teacher_computer_mr.getAllComputers()) do
		if IsValid(computer.htmlRenderer) then
			computer.htmlRenderer:Remove()
		end
		computer.state = nil
		computer.htmlRenderer = nil
	end
	local ply = LocalPlayer()
	if IsValid(ply) then
		local computer, on_seat = prop_teacher_computer_mr.getComputerFromPlayer(ply)
		if IsValid(computer) then
			createRemoteGui()
			if on_seat then
				createSeatGui()
			end
		end
	end
end)

function ENT:OnRemove()
	if IsValid(self.htmlRenderer) then
		self.htmlRenderer:Remove()
	end
	self.htmlRenderer = nil
end

hook.Add("findFirstPersonOverlayComputer_mr", "prop_teacher_computer_mr:cl", function(ply, seat)
	local computer
	local allComputers = prop_teacher_computer_mr.getAllComputers()
	do
		-- Find computer linked to current seat:
		computer = prop_teacher_computer_mr.getComputerFromSeat(seat, allComputers)
	end
	if not computer and rooms_lib_mr then
		-- Find a unique computer in the room:
		local room_ply = rooms_lib_mr.getRoom(ply)
		if room_ply then
			local inRoomComputers = {}
			for computer_ in pairs(allComputers) do
				if rooms_lib_mr.getRoom(computer_) == room_ply then
					inRoomComputers[#inRoomComputers + 1] = computer_
					if #inRoomComputers > 1 then
						-- more that 1 computer, no need to bother any further:
						break
					end
				end
			end
			if #inRoomComputers == 1 then
				computer = inRoomComputers[1]
			end
		end
	end
	if IsValid(computer) then
		return computer
	end
end)

do
	local eFirstPersonOverlayComputer
	
	hook.Add("newFirstPersonOverlayComputer_mr", "prop_teacher_computer_mr:cl", function(eFirstPersonOverlayComputer_)
		eFirstPersonOverlayComputer = eFirstPersonOverlayComputer_
	end)
	
	hook.Add("DrawOverlay", "prop_teacher_computer_mr:cl", function()
		-- It's better to use ents.FindByClass() because of the PVS.
		
		local ply = LocalPlayer()
		if not IsValid(ply) then
			return
		end
		local allComputers = prop_teacher_computer_mr.getAllComputers()
		local filtered = false -- whether undisplayed HTML panels have been hidden or not (for this frame)
		local veh = ply:GetVehicle()
		if IsValid(veh) then
			local computer = eFirstPersonOverlayComputer
			if IsValid(computer) then
				if computer:isComputerOn() and IsValid(computer.htmlRenderer) then
					for computer_ in pairs(allComputers) do
						if IsValid(computer_.htmlRenderer) then
							if computer_ == computer then
								if computer_.htmlRenderer:GetAlpha() ~= 255 then
									computer_.htmlRenderer:SetAlpha(255)
									if computer_:GetForTechnician() then
										computer_.htmlRenderer:SetMouseInputEnabled(true)
									end
								end
							else -- hide all other desks' HTML
								if computer_.htmlRenderer:GetAlpha() ~= 0 then
									computer_.htmlRenderer:SetAlpha(0)
									computer_.htmlRenderer:SetMouseInputEnabled(false)
								end
							end
						end
					end
					filtered = true
				end
			end
		end
		if not filtered then -- no computer found, hide all HTML
			for computer_ in pairs(allComputers) do
				if IsValid(computer_.htmlRenderer) then
					if computer_.htmlRenderer:GetAlpha() ~= 0 then
						computer_.htmlRenderer:SetAlpha(0)
						computer_.htmlRenderer:SetMouseInputEnabled(false)
					end
				end
			end
		end
	end)
end

hook.Add("canUseFirstPersonZoom_mr", "prop_teacher_computer_mr:cl", function(seat, ply)
	local computer
	local allComputers = prop_teacher_computer_mr.getAllComputers()
	do
		computer = prop_teacher_computer_mr.getComputerFromSeat(seat, allComputers)
	end
	if not computer and rooms_lib_mr then
		local room_ply = rooms_lib_mr.getRoom(ply)
		if room_ply then
			for computer_ in pairs(allComputers) do
				if room_ply == rooms_lib_mr.getRoom(computer_) then
					computer = computer_ -- computer in the same room
					break
				end
			end
		end
	end
	if computer then
		return true
	end
end)
