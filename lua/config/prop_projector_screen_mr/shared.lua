--- SHARED ---

-- How long it takes to deploy & retract the screen:
prop_projector_screen_mr.MoveDuration_s = 8.

-- Default model:
-- Material indexes, pose parameters & attachments must match the default ones.
prop_projector_screen_mr.Model = "models/mohamed_rachid/projector_screen_15.mdl"

-- All allowed models:
-- Material indexes, pose parameters & attachments must match the default ones.
prop_projector_screen_mr.AllowedModels = {
	["models/mohamed_rachid/projector_screen_15.mdl"] = true,
	["models/mohamed_rachid/projector_screen_25.mdl"] = true,
	["models/mohamed_rachid/projector_screen_30.mdl"] = true,
	["models/mohamed_rachid/projector_screen_35.mdl"] = true,
	["models/mohamed_rachid/projector_screen_40.mdl"] = true,
}

--- CLIENT ---

-- Material displayed on the screen when there is no signal:
prop_projector_screen_mr.MaterialPathNoSignal = "models/mohamed_rachid/projector_screen_no_signal_fr"
