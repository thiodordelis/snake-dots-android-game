-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()

-- include Corona's "widget" library
local widget = require "widget"

--------------------------------------------

-- forward declarations and other locals
local sceneGroup

--Menu buttons
local playBtn
local leaderboardsBtn
local highscoreBtn
local UI_madebyText

--Cirlce effect declarations
circle = {}
bCircle = 1
local spX=-5
local spY=0

--Timer for background effect animation
local timer1
 
--Colors
local btnLabel={99/255, 116/255, 131/255}

local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5

--Seed the random
math.randomseed( os.time() )

--Music FX
_G.clickSound = audio.loadSound( "menuclick.wav" )

--Load/save variables
json = require('json')

-- Save specified value to specified encrypted file
function saveValue(strFilename, strValue)
 
  local theFile = strFilename
  local theValue = strValue
  local path = system.pathForFile( theFile, system.DocumentsDirectory )
 
  local file = io.open( path, "w+" )
  if file then -- If the file exists, then continue. Another way to read this line is 'if file == true then'.
    file:write(theValue) -- This line will write the contents of the table to the .json file.
    io.close(file) -- After we are done with the file, we close the file.
    return true -- If everything was successful, then return true
  end
end

-- Load specified encrypted file, or create new file if it does not exist
function loadValue(strFilename)
  local theFile = strFilename
  local path = system.pathForFile( theFile, system.DocumentsDirectory )
  local file = io.open( path, "r" )
 
  if file then -- If file exists, continue. Another way to read this line is 'if file == true then'.
    local contents = file:read( "*a" ) -- read all contents of file into a string
    io.close( file ) -- Since we are done with the file, close it.
    return contents -- Return the table with the JSON contents
  else
    return '' -- Return nothing
  end
end

--Get user json params(level). This if global, accessable from everywhere
user = json.decode(loadValue('user.txt'))

--If this is the first time, then set score to 0
if not user then
  _G.user = {
    level = 0, -- stores user level
  }
  saveValue('user.txt', json.encode(user))
end

--Now get the highest level from user.txt
user = json.decode(loadValue('user.txt'))

--------------------------------------------------------------------------------------------------
----------------------------------- Google Game center -------------------------------------------
--------------------------------------------------------------------------------------------------
local gameNetwork = require( "gameNetwork" )
local playerName
 
local function loadLocalPlayerCallback( event )
   playerName = event.data.alias
   --saveSettings()  --save player data locally using your own "saveSettings()" function
end
 
local function gameNetworkLoginCallback( event )
   gameNetwork.request( "loadLocalPlayer", { listener=loadLocalPlayerCallback } )
   return true
end
 
local function gpgsInitCallback( event )
   gameNetwork.request( "login", { userInitiated=true, listener=gameNetworkLoginCallback } )
end
 
local function gameNetworkSetup()
   if ( system.getInfo("platformName") == "Android" ) then
      gameNetwork.init( "google", gpgsInitCallback )
   else
      gameNetwork.init( "gamecenter", gameNetworkLoginCallback )
   end
end
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------

------HANDLE SYSTEM EVENTS------
local function systemEvents( event )
   print("systemEvent " .. event.type)
   if ( event.type == "applicationSuspend" ) then
      print( "suspending..........................." )
   elseif ( event.type == "applicationResume" ) then
      print( "resuming............................." )
   elseif ( event.type == "applicationExit" ) then
      print( "exiting.............................." )
   elseif ( event.type == "applicationStart" ) then
      gameNetworkSetup()  --login to the network here
   end
   return true
end
Runtime:addEventListener( "system", systemEvents )

--Function to animate button on click
local function btnAnimate()
    audio.play( _G.clickSound )
    transition.to( playBtn, { time=500, x=display.contentWidth*1.5,transition=easing.outBounce } )
    transition.to( leaderboardsBtn, { time=900, x=display.contentWidth*1.5,transition=easing.outBounce } )
    transition.to( highscoreBtn, { time=1300, x=display.contentWidth*1.5,transition=easing.outBounce } )
end

-- 'onRelease' event listener for playBtn
local function onPlayBtnRelease()
    
    --Stop the timer for background effect
    timer.cancel(timer1)
    
    --Animate the buttons
    btnAnimate()
    
	-- go to level1.lua scene with fade effect
    composer.gotoScene( "level1", "fade", 350 )
    
	return true	-- indicates successful touch
end

--onRelase of highscore button
local function onhighscoreBtnRelease()
--TODO add share dialog to tweet highscore
    print ("Share dialgo tweet")
end

-- 'onRelease' event listener for leaderboardsBtn
local function onleaderboardsBtnRelease()
    timer.cancel(timer1)
	return true	-- indicates successful touch
end


--Spawn function for the background effect
local spawnImage=function(x,y)
    circle[bCircle] = display.newImage( "dot2.png" ,true)
    circle[bCircle].x = spX+x*55
    circle[bCircle].y = spY+y*55
    sceneGroup:insert(circle[bCircle])
    circle[bCircle].value = bCircle 
    circle[bCircle].tag=false
    circle[bCircle].alpha=0.7
    circle[bCircle].isVisible=false
    bCircle = bCircle + 1
end

--Background effect with dots appearing
function showHideCirlce()
    local index=math.random(40)
    transition.fadeIn(  circle[index], { time=1000 } )
    
    if circle[index].isVisible==false then
        circle[index].isVisible=true
    else 
        circle[index].isVisible=true
    end
    
    transition.fadeOut(  circle[index], { time=2000 } )
end

--Open developers homepage
function openHomepage( event )
    system.openURL( "http://theodoros.info" ) 
end

function scene:create( event )
    sceneGroup = self.view

    --Blue background
    local background = display.newRect(0,0,screenW,screenH)
	background.anchorX = 0
	background.anchorY = 0
	background.x, background.y = 0, 0
	background:setFillColor(61/255, 125/255, 167/255,0.8)--104/255, 157/255, 153/255, 0.6)
	
	-- Play button
	playBtn = widget.newButton{
		label="Play",
		labelColor = { default=btnLabel, over={128} },
		default="button.png",
		over="button-over.png",
        font="Helsinki",
		width=154, height=60,
        shape="roundedRect",
        fontSize=38,
        emboss=false,
        textOnly=false,
		onRelease = onPlayBtnRelease	-- event listener function
	}
	playBtn.x = -250
	playBtn.y = 180
    transition.to( playBtn, { time=900, x=display.contentWidth*0.5,transition=easing.outBounce } )
    
    --Leaderboards button
    leaderboardsBtn=widget.newButton{
		label="Leaderboards",
		labelColor = { default=btnLabel, over={128} },
		default="button.png",
		over="button-over.png",
        font="Helsinki",
		width=154, height=60,
        shape="roundedRect",
        fontSize=18,
		onRelease = onleaderboardsBtnRelease	-- event listener function
	}
	leaderboardsBtn.x = -250
	leaderboardsBtn.y = 180+playBtn.height+20
    transition.to( leaderboardsBtn, { time=1100, x=display.contentWidth*0.5,transition=easing.outBounce } )
    
    --Highscore button
    highscoreBtn=widget.newButton{
		label="Highscore: "..user.level,
		labelColor = { default=btnLabel, over={128} },
		default="button.png",
		over="button-over.png",
        font="Helsinki",
		width=154, height=60,
        shape="roundedRect",
        fontSize=18,
		onRelease = onhighscoreBtnRelease	-- event listener function
	}
	highscoreBtn.x = -250
	highscoreBtn.y = 180+leaderboardsBtn.height*2+40
    transition.to( highscoreBtn, { time=1300, x=display.contentWidth*0.5,transition=easing.outBounce } )

    --Made by text
    local UI_madebyText_options = {
        text = "Monkey games 🐒 \n http://theodoros.info",
        x = display.contentCenterX,
        y =screenH-30,
        font="Helsinki",
        fontSize = 12,
        anchorX=0,
        anchorY=0,
        width=screenW,
        height = 30,
        align = "center",
    }

    UI_madebyText=display.newText(UI_madebyText_options)
    UI_madebyText:setFillColor(1,1,1,1)
    UI_madebyText:addEventListener( "tap", openHomepage)
    
	-- all display objects must be inserted into group
	sceneGroup:insert( background )
    
     --Create main menu background--Must be first in z index
    for y=1,8 do
        for x=1,5 do
         spawnImage(x,y)
        end
    end
    
    sceneGroup:insert( playBtn )
    sceneGroup:insert(leaderboardsBtn)
    sceneGroup:insert(highscoreBtn)
    sceneGroup:insert( UI_madebyText )
    
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
        timer1=timer.performWithDelay(1500,showHideCirlce,100)
                      
	end	
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
end

function scene:destroy( event )
	local sceneGroup = self.view
	
	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	for i=1,#circle do
        circle[i]=nil
    end
    
    background=nill
    
	if playBtn then
		playBtn:removeSelf()	-- widgets must be manually removed
		playBtn = nil
	end
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene