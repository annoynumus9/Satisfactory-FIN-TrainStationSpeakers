-- CUSTOMIZABLE VALUES
STATION = component.proxy("replace_me_for_manual_override") 	-- The ID of the station (use the Network Manager item) (will auto-detect any stations attached, override if you want a specific one)
SPEAKERS = component.proxy({"replace_me_for_manual_override"})	-- The ID(s) of the speakers (automatically detects speakers, override if you want to choose specific ones)
SPEAKER_VOLUME = 2                                            	-- Volume Gain of the speaker
SPEAKER_RANGE = 7000                                          	-- Range of the speaker (optimized for 1 station and 5 platforms)
ANNOUNCEMENT_DISTANCE = 100000                                	-- The distance a train has to be to a station for the announcement to start (optimized for 1 station and 5 platforms)
TRAINS_TO_TAIL = {}                     						-- List of the trains you want messages for. Set to {} or nil to watch all trains
MSG_COUNT = 11                                                	-- The amount of one liners minus 1 (only change if you tempered with the audio files for that)
USE_CUSTOM_AUDIO = false                                        -- If this is set to 'true' you NEED custom audio files (check the guide on how to make them), otherwise it will always call every train/station "Train" and "Station"
CALCULATION_INTERVAL = 1 --DO NOT CHANGE FOR NOW				  		 -- The interval (seconds) in which the distance between the tailed trains and the station is calculated

warn("Known bug: sounds do not properly notify when ended, so I can't know when the sound ends ;D")
warn("Custom sounds WILL (likely) NOT WORK")
---- CODE ----
function getLocation(Object)
	local pos = Object.location
	return pos.x, pos.y, pos.z
end

-- SETUP
-- This is where all the setup happens

---- VARIABLES ----
finished = true


---- SPEAKERS ----
if not SPEAKERS or #SPEAKERS == 0 then
	SPEAKERS = component.proxy(component.findComponent(classes.Build_Speakers_C)) -- Gets all connected speakers
end

function playSound(soundName)
	for _, SPEAKER in ipairs(SPEAKERS) do
		SPEAKER:stopSound()
		SPEAKER:playSound(soundName, 0.001)
	end
end

for _, SPEAKER in ipairs(SPEAKERS) do
	SPEAKER:setVolume(SPEAKER_VOLUME)
	SPEAKER:setRange(SPEAKER_RANGE)
end


---- EVENTS ----
-- Listen to the last speaker for better accuracy as it plays last
event.ignoreAll()
event.registerListener({sender=SPEAKERS[#SPEAKERS], event="SpeakerSound"}, function(e, s, state, sound)
	print(state, "|", sound)
	if state == 1 then
		finished = true
	end
end)


---- TRAINS ----

-- Allows for more efficient checking
if TRAINS_TO_TAIL then
	for _, value in ipairs(TRAINS_TO_TAIL) do
		TRAINS_TO_TAIL[value] = true
	end
end

-- Handle automatic station detection
if not STATION then
	STATION = component.proxy(component.findComponent(classes.Build_TrainStation_C)[1])
end


---- MORE VARIABLES ----
stationX, _, stationZ = getLocation(STATION)
stationName = STATION.name
trackGraph = STATION:getTrackGraph()
trains = trackGraph:getTrains()
playing = false
inRange = false
stage = 0


-- MAIN
-- Optimizations are always welcome.
-- Just make a pull request on the repository to integrate your changes
while true do
    sleep(CALCULATION_INTERVAL)

    for _,train in ipairs(trains) do
		if TRAINS_TO_TAIL == nil or #TRAINS_TO_TAIL == 0 or TRAINS_TO_TAIL[train:getName()] then
			locomotive = train:getMaster()
				
			-- Prevents the program to run into errors when loading the save
			-- When loading the save train:getMaster() returns nil
			if locomotive then
				trainX, _, trainZ = getLocation(locomotive)
				-- Why the fuck does math.pow not exist!?
				distanceX = math.abs((stationX * stationX) - (trainX * trainX))
				distanceZ = math.abs((stationZ * stationZ) - (trainZ * trainZ))
				distance = math.sqrt(distanceX + distanceZ)
				timeTable = train:getTimeTable()
				nextStop = timeTable:getStop(timeTable:getCurrentStop()).station.name

				if finished and stage ~= 0 then
					finished = false
					if stage == 1 then
						sleep(1)
						if USE_CUSTOM_AUDIO then
							playSound("trains/" .. tailedTrain)
						else
							playSound("trains/default")
							sleep(2)
						end
							
						stage = 2
					elseif stage == 2 then
						if nextStop == stationName then
							playSound("arrivingat")
							sleep(1)
						else
							playSound("commingthrough")
							sleep(1)
						end
                        
						stage = 3
					elseif stage == 3 then
						if USE_CUSTOM_AUDIO then
							playSound("stations/" .. stationName)
						else
							playSound("stations/default")
							sleep(1)
						end
							
						stage = 4
					elseif stage == 4 then
						playSound("msg/msg" .. math.random(0, MSG_COUNT))
						stage = 5
					else
						playing = false
						stage = 0
					end
				end

				if distance > ANNOUNCEMENT_DISTANCE and inRange then
					inRange = false
				end

				if distance <= ANNOUNCEMENT_DISTANCE and not playing and not inRange then
					playSound("announcement")
					stage = 1
					playing = true
					inRange = true
				end
            end
        end
    end
end
