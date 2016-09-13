-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )

local scene = composer.newScene()

-- include Corona's "widget" library
local widget = require "widget"

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5

--Seed the random
math.randomseed( os.time() )

--DELETElocal increment
local circle = {}
local numCircle={}
--DELETElocal playerPattern={0,0,0,0,0}
local CPUPatternNew={} 



--Levels file path
local path = system.pathForFile( "lvl/lvl"..math.random(4)..".txt", system.ResourceDirectory)
local file = io.open(path,"r")
for line in file:lines() do
    table.insert(CPUPatternNew,{line})
end
io.close( file )

--Index for dots[]
local bCircle = 1

--The sceneGroup that holds all objects
local sceneGroup

--If user is touch and then release then disable touch event
local canTouch=false

--INITIAL COORDINATION FOR GRID
local spX=-5
local spY=(screenH-499)/2---510/4*0.25 --510 was screenH

--Actuall stage
local stage=0

--Stage Level, how many object will be required
local stageLevel=0

--Pattern animate step index, NULLED@TURN
local ipat=0

--Experimental string that hold user order of touch
local playerPatternString=""
local CPUEditedPattern={}

--Sound & effects
local sounds = {}   
local myChannel, mySource   
sounds.bgSound = audio.loadStream( "ping.wav" )
sounds.correct = audio.loadStream("correct.wav")
audio.reserveChannels(2)
--Index for the pitch function/Increase incrementaly, should be NULLED@TURN
local sfxIndex=0.9

-----------------------UI------------------------
--DELETElocal UI_scoreText
local UI_timerRect
local popupRect
local overlay_background_dimed
local okBtn
local windowRectTut
-----------------------UI------------------------    
    
--global step time 
local animationTime=350
local initialDelay=1500
local resetTime=500

--Timer for time meter bar
local beatTimer

--Local for end game
local gameIsFinished=false

--First timer/tutorial
local firstTimerTutorial=false

--LEVEL EDITOR VARIABLES
local counter=0
local editorMode=false

--Game mode, will be implemented on future releases
local easyMode=true

--Error handling
local function myUnhandledErrorListener( event )
 
    local iHandledTheError = true
 
    if iHandledTheError then
        print( "Handling the unhandled error", event.errorMessage )
    else
        print( "Not handling the unhandled error", event.errorMessage )
    end
    
    return iHandledTheError
end

--Bind the listener for error suppresion
Runtime:addEventListener("unhandledError", myUnhandledErrorListener)

--TODO correct timer function. Need to be precice in countdown
function updateUItimer()
    UI_timerRect.width=UI_timerRect.width-screenW*1/100
    print(UI_timerRect.width)
    if UI_timerRect.width<=0.01 then endGame() end
end

--Exit to menu function
function exitToMenu()
    --Play click sound
    audio.play( _G.clickSound )
    
    --timer.cancel(beatTimer)
    composer.removeScene( "menu")
    composer.removeScene( "level1")
	composer.gotoScene( "menu", "fade", 350 )
end 

--Function to pitch the speed of sound
function pitchSound(pitchS)
    myChannel, mySource = audio.play( sounds.bgSound, { channel=1, loops=0 } )	
    al.Source( mySource, al.PITCH,pitchS)
end

-------------------------------------------------------------------------------------------
--                              TABLE OPERATIONS                                         --
-------------------------------------------------------------------------------------------
function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end
-------------------------------------------------------------------------------------------
--                              TABLE OPERATIONS                                         --
-------------------------------------------------------------------------------------------


--Alternative string.format function for converting boolean to string, since lua doesnt have any
local function myformat( fmt, ... )
    local buf = {}
     for i = 1, select( '#', ... ) do
         local a = select( i, ... )
         if type( a ) ~= 'string' and type( a ) ~= 'number' then
             a = tostring( a )
         end
         buf[i] = a
     end
     return string.format( fmt, unpack( buf ) )
end
 
--Stage creation: Random num->get pattern from CPUPattern table->copy to CPUEditedPattern
function generateStage()
    --Increament stage and stageLevel
    stage=stage+1
    stageLevel=stageLevel+1
    
    --Copy pattern to temp pattern
    local tt=CPUPatternNew[stage][1]
    CPUEditedPattern={}
    for k in string.gmatch(tt,'%w+') do
      table.insert(CPUEditedPattern,k)
    end
    
end

--Reset all colored objects
local function resetStage()
    --LEVEL EDITOR 
    counter=0
    
    --UI_timerRect.width=screenW
    --timer.resume(beatTimer)
    
    --Reset SFX pitch
    sfxIndex=0.9
    
    --Reset objects
    for i=1,#circle do
      circle[i].tag=false
      circle[i]:setFillColor( 142,194,40,1 )
    end
    
    --User can touch now           
    canTouch=true
    
end

--Ends current game, show option dialog
function endGame()
    
    --Get highscore
    if stage>user.level then
        user.level=stage-1
        saveValue('user.txt', json.encode(user))
    end
    
    --User cant touch dots
    canTouch=false
    
    --End game pop up dialog
    overlay_background_dimed.isVisible=true
    
    --Notify that game is ended
    gameIsFinished=true
    
    if not easyMode then
        --Pause timer for lower bar
        timer.cancel(beatTimer,timer1)
        
        --Reset bar width
        UI_timerRect.width=screenW
    end 
     
    --Now show pop in a fancy way 
    transition.to( popupRect, { time=800, x=screenW/2-popupRect.width/2, transition=easing.outBounce } )
    transition.to( UI_exitBtn, { time=800, x=screenW/2, transition=easing.outBounce } )
    transition.to( UI_restartBtn, { time=800, x=screenW/2, transition=easing.outBounce } )
    
    --TODO add share score with native
    --local isAvailable = native.canShowPopup( "social", serviceName )
    --native.showAlert("social",{service ="twitter",  message = "Hi there!"})
    
    --timer.performWithDelay(1500,restartGame)
    
end 
 
 
--Show pattern function: get pattern from CPUEditedPattern
local function showPattern()
    
    if not easyMode then
        --reset bar width and its timer
        UI_timerRect.width=screenW
        timer.pause(beatTimer)
    end 
    
    --Disable user touch
    canTouch=false
    
    --Increamental index from object change color
    ipat=ipat+1

    --pitch sound
    sfxIndex=sfxIndex+0.2
    pitchSound(sfxIndex)
    
    --Actuall change color of object
    circle[tonumber(CPUEditedPattern[ipat])]:setFillColor(255/255, 93/255, 115/255, 0.78 )--180/255,88/255,20/255 )
    
    --When done, call resetStage()
    if ipat==stageLevel then
      timer.performWithDelay(resetTime,resetStage)
    end
    
    --on every stage mark the correspoding text 
    numCircle[ipat]:setFillColor(61/255, 125/255, 167/255,0.8)--255/255, 93/255, 115/255, 0.78 )
    
end


--Restart Game function
function restartGame()
    --Play click sound
    audio.play( _G.clickSound )
    
    --Hide end game dialog(will be destroyed from sceneGroup)
    popupRect.isVisible=false
    
    --Remove dim background
    overlay_background_dimed.isVisible=false
    
    --Hide all dots and stage text
    for i=1,#circle do
        numCircle[i].isVisible=false
        circle[i].isVisible=false
       --transition.fadeOut(numCircle[i], { time=1 } )
        --transition.fadeOut(circle[i], { time=1 } )
    end
    
    --Now remove the scene and go to transition sceene
    composer.removeScene("level1")
    composer.gotoScene( "transScene" , "fade",350)
end

--Touch event
local function touchi( event )

    --If the game is not finished
    if gameIsFinished==false then
    
        --User if touching the screen,NO lift
        if event.phase == "moved" or event.phase=="began" and canTouch==true then
        
            --Is the circle tag is false a.k.a not touched?
            if circle[event.target.value].tag==false then
                
                --LEVEL EDITOR counter for touched dots so far
                counter=counter+1
                
                --Sound Effects
                sfxIndex=sfxIndex+0.2
                pitchSound(sfxIndex)
                
                --Change color of circle and set tag to true
                circle[event.target.value]:setFillColor(1, 0, 1, 0.5 )
                circle[event.target.value].tag=true
                
                --Create player's pattern so we can compare later
                playerPatternString=playerPatternString..myformat("%s", circle[event.target.value].value).."-"
                
            end --circle[event.target.value].ta
        
            
        --User if lifted his finger off the screen
        elseif event.phase == "ended" or event.phase == "cancelled" then
           
            if canTouch==true then
            
                    ----------------------------------------------------------------------------
                                        ----LEVEL EDITOR----
                    ----------------------------------------------------------------------------
                    if editorMode then 
                        local patha = system.pathForFile( "lvl/lvl4.txt", system.ResourceDirectory)
                        local files = io.open(patha, "a")
                        io.output(files)
                        io.write(string.sub(playerPatternString,1,-2).."\n")
                        io.close(files)
                        playerPatternString=""
                        resetStage()
                        --timer.cancel(beatTimer)
                        stage=stage+1
                        print("STAGE:",stage)
                    else
                    ----------------------------------------------------------------------------
                                        ----LEVEL EDITOR----
                    ----------------------------------------------------------------------------
	                if not easyMode then 
                        --First reset the bar timer and bar width
                        UI_timerRect.width=UI_timerRect.width
                        timer.pause(beatTimer)
                    end
                    
                    --Remove the last - from player's pattern
                    playerPatternStringSubbed=string.sub(playerPatternString,1,-2)
                    
                    --Is user correct
                    if playerPatternStringSubbed == CPUPatternNew[stage][1] then 
                        
                        --Reset player's pattern string
                        playerPatternString=""
                        
                        --Remove touch event(no more touching)
                        Runtime:removeEventListener("touch",onTouch)
                        
                        --Pattern increment index reset
                        ipat=0
                        
                        --Remove cirlce's number overlay(level indicator)
                        --numCircle[stage]:setFillColor(255/255, 93/255, 115/255, 0.78)
                        transition.fadeOut(numCircle[stage], { time=750 } )
                        
                        --Call reset stage
                        resetStage()
                        
                        --And generate the next stage
                        generateStage()
                        
                        --Finally play the new stage with the above fresh pattern
                        --The pattern time is decreasing on every stage
                        timer1=timer.performWithDelay(animationTime-stage*5,showPattern,stageLevel)
                        
                        --Correct pattern sound,play it in channel 2
                        audio.play( sounds.correct, { channel=2, loops=0 } )	
                        
                    --User is wrong
                    else
                        
                        --Just end the game
                        endGame()
                        
                    end --playerPatternStringSubbed
                    
                end --Editor mode
                
                --Reset player's pattern string <- AGAIN? Why? DELETE LAST.
                playerPatternString=""
                
            end --canTouch==true
            
        end --event.phase == "moved"
        
    end --gameIsFinished
    
end

--The spawn function, spawns one circle at X and Y 
-- <- The magic is here! ->
local spawnImage=function(x,y)
    circle[bCircle] = display.newImageRect( "dot2.png",64,64 )
    circle[bCircle].x =spX+55*x
    circle[bCircle].y =spY+55*y
    sceneGroup:insert(circle[bCircle])
    circle[bCircle].value = bCircle 
    circle[bCircle].tag=false
    numCircle[bCircle]= display.newText(  circle[bCircle].value, spX+55*x, spY+y*55, "Helsinki", 14 )
    sceneGroup:insert(numCircle[bCircle])
    numCircle[bCircle].align="center"
    circle[bCircle]:addEventListener( "touch", touchi )
    bCircle = bCircle + 1
end

function scene:create( event )

	-- Called when the scene's view does not exist.
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.
    
	sceneGroup = self.view
    
    --Das background, plain WHITE
	local background = display.newRect( 0, 0, screenW, screenH )
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( 1.0 )
    
    
    --LEVEL EDITOR counter label
    if editorMode then 
        local options = {
            text = "",
            x = display.contentCenterX,
            y = 15,--display.contentCenterY-(display.contentCenterY-50),
            font="Helsinki",
            fontSize = 22,
            anchorX=0,
            anchorY=0,
            height = 0,
            align = "center"
        }
        UI_scoreText=display.newText(options)
        UI_scoreText:setFillColor(104/255, 157/255, 153/255, 0.6) 
    end 
    
        
    --Overlay semi transparent when the end game dialog is shown
    overlay_background_dimed = display.newRect(0,0,screenW,screenH)
	overlay_background_dimed.anchorX = 0
	overlay_background_dimed.anchorY = 0
	overlay_background_dimed.x, background.y = 0, 0
	overlay_background_dimed:setFillColor(0,0,0, 0.5)
    overlay_background_dimed.isVisible=false
    
    --This is for later.TIMER BAR
    if not easyMode then 
        --The timer bar at the botton ->TODO:make it colorfull, from green to red
        UI_timerRect= display.newRect( 0, screenH-5, screenW, 5 )
        UI_timerRect.anchorX=0
        UI_timerRect.anchorY=0
        UI_timerRect:setFillColor(94/255, 46/255, 0/255, 1 ) 
    
        --And the timer for reducing the bar width
        beatTimer= timer.performWithDelay(100,updateUItimer,-1)
        timer.pause(beatTimer)
    end
    
    --End game dialog
    popupRect=display.newRect(-300,screenH/2-screenH/4,screenW/4*3,screenH/4)
    popupRect.anchorX = 0
	popupRect.anchorY = 0
    popupRect:setFillColor(1, 1, 1, 1)
    
    --Restart button
    UI_restartBtn = display.newText("Restart", 0, 0, "Helsinki", 20 )
    UI_restartBtn:setFillColor( 99/255, 116/255, 131/255,1)
    UI_restartBtn.width=popupRect.width/2
    UI_restartBtn.x = -200
	UI_restartBtn.y = popupRect.y+UI_restartBtn.height+20
    UI_restartBtn:addEventListener("touch",restartGame)
    
    --Exit to menu button
    UI_exitBtn = display.newText("Menu", 0, 0, "Helsinki", 20 )
    UI_exitBtn:setFillColor( 99/255, 116/255, 131/255,1 )
    UI_exitBtn.width=popupRect.width
    UI_exitBtn.x = -200
	UI_exitBtn.y = popupRect.y+UI_exitBtn.height*2+40
    UI_exitBtn:addEventListener("touch",exitToMenu)
        
	-- All display objects must be inserted into group
	sceneGroup:insert( background )
   
    --DAS Magic! Spawn circles
    for y=1,8 do
       for x=1,5 do
         spawnImage(x,y)
       end
    end

    --Tutorial dialog for first time game
    if firstTimerTutorial then
        windowRectTut=display.newRect(halfW,screenH/2,screenW-screenW/4,screenH-screenH/3)
        windowRectTut:setFillColor(1,0,1,0.5)
        sceneGroup:insert(windowRectTut)
        for i=1,40 do 
            circle[i]:removeEventListener("touch",touchi)
        end
        timer.performWithDelay(2000,hideTutorial,1)
    end   
    
    --The order of adding object to sceneGroup is mandatory
    sceneGroup:insert( overlay_background_dimed )
    sceneGroup:insert( popupRect )
    sceneGroup:insert( UI_exitBtn )
    sceneGroup:insert( UI_restartBtn )

   
    --TIMER BAR
    if not easyMode then sceneGroup:insert( UI_timerRect ) end
    
end

--UI text in editor mode(Touch dots indicator)
local UI_text = function()  
    local memUsed = (collectgarbage("count"))
    local texUsed = system.getInfo( "textureMemoryUsed" ) / 1048576 -- Reported in Bytes
    UI_scoreText.text=string.format("counter: %.00f", counter)
end

--Editor mode ui text
if editorMode then
	Runtime:addEventListener( "enterFrame", UI_text)
end

--Hide tutorial screen and do normal stuff
function hideTutorial()

    --Tutorial window hide
    windowRectTut.isVisible=false
    
    --Add touch listener back to circles
    for i=1,40 do 
        circle[i]:addEventListener( "touch", touchi )
    end
    
    --This is the start of the game,first time.    
    generateStage()
    
    --Create the main pattern generator timer
    timer1=timer.performWithDelay(initialDelay,showPattern,stageLevel)
    
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
        
        ----------------------------------------------------------------------------
                                ----LEVEL EDITOR----
        ----------------------------------------------------------------------------
        --TODO delete maybe this?
        if editorMode==true then canTouch=true end
        ----------------------------------------------------------------------------
                                ----LEVEL EDITOR----
        ----------------------------------------------------------------------------
        
        --Start the game if not tutorial and editorMode are true
        if firstTimerTutorial == false and editorMode == false then     
            --This is the start of the game,first time.    
            generateStage()

            --Create the main pattern generator timer
            timer1=timer.performWithDelay(initialDelay,showPattern,stageLevel)      
        end         
    end
       
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	    
end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view
	
    --sceneGroup:remove(UI_scoreText)
    --DO we need this? Maybe not!
    for i=1,#numCircle do
        numCircle[i].isVisible=false
        circle[i]=nil
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