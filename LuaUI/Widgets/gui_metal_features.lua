-- $Id: gui_metal_features.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_metal_features.lua
--  brief:   highlights features with metal in metal-map viewmode
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "MetalFeatures",
    desc      = "Highlights features with reclaimable metal",
    author    = "trepan",
    date      = "Aug 05, 2007", --Apr 23, 2019
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- Speed Ups

local spGetMapDrawMode = Spring.GetMapDrawMode
local spGetActiveCommand = Spring.GetActiveCommand
local spGetActiveCmdDesc = Spring.GetActiveCmdDesc
local spGetGameFrame = Spring.GetGameFrame

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Map/Reclaimables'
options_order = { 'showhighlight','intensity','pregamehighlight'}
options = {
	showhighlight = {
		name = 'Show Reclaim on Economy Overlay',
		desc = "When to highlight reclaimable features",
		type = 'radioButton',
		value = 'always',
		items = {
			{key ='always', name='Always'},
			{key ='constructors',  name='When Constructor Selected'},
			{key ='reclaiming',  name='When Reclaiming'},
		},
		noHotkey = true,
	},

	intensity = {
		name = 'Highlighted Reclaim Brightness',
		desc = "Increase or decrease visibility of effect",
		type = 'radioButton',
		value = '1',
		items = {
			{key ='1', name='High'},
			{key ='2',  name='Medium'},
			{key ='4',  name='Low'},
		},
		noHotkey = true,
	},

	pregamehighlight = {
		name = "Show Reclaim Before Round Start",
		desc = "Enabled: Show reclaimable metal features before game begins \n Disabled: No highlights before game begins",
		type = 'bool',
		value = false,
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local conSelected = false
local hilite = false
local pregame = true

local function DrawWorldFunc()

  pregame = (spGetGameFrame() < 1)

  if Spring.IsGUIHidden() then
    return false
  end

  -- ways to bypass heavy resource load in economy overlay
  if (pregame and options.pregamehighlight.value) or hilite 
    or (options.showhighlight.value == 'always' and spGetMapDrawMode() ~= 'metal') 
    or (conSelected and options.showhighlight.value == "constructors") then 

    gl.PolygonOffset(-2, -2)
    gl.Blending(GL.SRC_ALPHA, GL.ONE)
  
    local timer = widgetHandler:GetHourTimer()
    local intensity = options.intensity.value
    local alpha = (0.25/intensity) + (0.5 / intensity * math.abs(1 - (timer * 2) % 2))
  
    local myAllyTeam = Spring.GetMyAllyTeamID()
  
    local features = Spring.GetVisibleFeatures()
    for _, fID in pairs(features) do
      local metal = Spring.GetFeatureResources(fID)
      if (metal and (metal > 1)) then
        -- local aTeam = Spring.GetFeatureAllyTeam(fID)
        -- if (aTeam ~= myAllyTeam) then
          local x100  = 100  / (100  + metal)
          local x1000 = 1000 / (1000 + metal)
          local r = 1 - x1000
          local g = x1000 - x100
          local b = x100
          
          gl.Color(r, g, b, alpha)
          
          gl.Feature(fID, true)
        -- end
      end
    end
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    gl.PolygonOffset(false)
    gl.DepthTest(false)
  	
  end
end

function widget:DrawWorld()
  DrawWorldFunc()
end
function widget:DrawWorldRefraction()
  DrawWorldFunc()
end

function widget:SelectionChanged(units)
	if (WG.selectionEntirelyCons) then
		conSelected = true
	else	
		conSelected = false  
	end
end

local currCmd =  spGetActiveCommand() --remember current command
function widget:Update()
	if currCmd == spGetActiveCommand() then --if detect no change in command selection: --skip whole thing
		return
	end --else (command selection has change): perform check/automated-map-view-change
	currCmd = spGetActiveCommand() --update active command
	local activeCmd = spGetActiveCmdDesc(currCmd)
	hilite = (activeCmd and (activeCmd.name == "Reclaim" or activeCmd.name == "Resurrect"))
end
