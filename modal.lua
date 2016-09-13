-----------------------------------------------------------------------------------------
--
-- modal.lua
-- 
-- Modal dialog for Corona SDK
-- V. Sergeyev
--
-- Usage:
-- showDialog("You completed the level. \n1st place.", "Next level", "level2", beforeNext)
--
-----------------------------------------------------------------------------------------

local storyboard = require( "storyboard" )
local widget = require "widget"

local dialog
local msgText
local preAction
local actionGo
local menuBtn
local actionBtn


-- 
function _destroyDialog()
	dialog:removeSelf()
	msgText:removeSelf()
	menuBtn:removeSelf()
	actionBtn:removeSelf()
end

-- 
function onMenuBtnRelease()
	_destroyDialog()
	storyboard.gotoScene( "menu", "fade", 500 )
	return true
end

-- 
function onActionBtnRelease()
	_destroyDialog()
	if preAction then
		preAction()
	end
	if actionGo ~= "" then
		storyboard.gotoScene( actionGo, "fade", 500 )
	end
	return true
end

-- 
function showDialog(msg, actionLabel, action, preaction)
	physics.pause()
	isPause = true

	preAction = preaction
	actionGo = action

	dialog = display.newRoundedRect(50, 50, 380, 220, 12)
	dialog:setFillColor( 96 )
	-- dialog.strokeWidth = 3
	-- dialog:setStrokeColor(180, 180, 180)
	dialog.alpha = 0.9

	msgText = display.newText(msg, 80, 80, 320, 160, native.systemFont, 24)

	menuBtn = widget.newButton{
		label="Menu",
		labelColor = { default={255}, over={128} },
		default="ui/button.png",
		over="ui/button-over.png",
		width=154, height=40,
		onRelease = onMenuBtnRelease	-- event listener function
	}
	menuBtn.view:setReferencePoint( display.CenterReferencePoint )
	menuBtn.view.x = 150
	menuBtn.view.y = 230

	actionBtn = widget.newButton{
		label=actionLabel,
		labelColor = { default={255}, over={128} },
		default="ui/button.png",
		over="ui/button-over.png",
		width=154, height=40,
		onRelease = onActionBtnRelease	-- event listener function
	}
	actionBtn.view:setReferencePoint( display.CenterReferencePoint )
	actionBtn.view.x = 330
	actionBtn.view.y = 230
end