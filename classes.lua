---This Contains all of the Functions that you'll need to run and set up the AI.  Most of the functions won't need to be used.  as they're used for internal purposes.
---@diagnostic disable: lowercase-global
---@author KickKing
blank = nil

---This Table contains all of the functions and data for the Village
---@table ai Contains all of the Towns
-- @field town All of the town Functions and Variables
-- @field townNames All of the Town Names
-- @field unit All of the Unit Functions and variables
ai = {
	town = {},
	townNames = {},
	unit = {},
	landmark = {},
	landmarkNames = {},
	route = {},
	trig = {},
	unitSTATE = {},
	townSTATE = {},
	region = {},
	landmarkSTATE = {},
	tick = 2,
	split = 5,
	unitGroup = CreateGroup()
}

---This is the first command that need to be run before anything else.  Initializes everything that's needed.
---@param overallTick number    OPTIONAL 2 | The interval at which each unit added to AI will update it's intelligence and make decisions   
---@param overallSplit number   OPTIONAL 5 | The amount of splits that the Ticks will process Unit intelligence at.  1 means all AI ticks will be processed at the same time, 3 means processing will be split into 3 groups.
function ai.Init(overallTick, overallSplit)

	-- Set Overall Tick if a value isn't specified
	overallTick = overallTick or ai.tick
	overallSplit = overallSplit or ai.split

	ai.tick = overallTick
	ai.split = overallSplit

	---Landmark Actions
	-- @section landmark
	--

	---Creates a New Landmark and Adds it.
	---@param town string
	---@param name string
	---@param rect table
	---@param types table
	---@param unit table OPTIONAL nil |
	---@param radius number OPTIONAL 600 |
	---@param maxCapacity number OPTIONAL Unlimited |
	function ai.landmark.New(town, name, rect, types, unit, radius, maxCapacity)
		unit = unit or nil
		radius = radius or 600
		maxCapacity = maxCapacity or 500

		local handleId = GetHandleId(rect)

		-- Add initial variables to the table
		ai.landmark[name] = {}
		ai.landmark[name] {
			id = handleId,
			alive = true,
			state = "normal",
			town = town,
			name = name,
			rect = rect,
			x = GetRectCenterX(rect),
			y = GetRectCenterY(rect),
			types = types,
			unit = unit,
			radius = radius,
			maxCapacity = maxCapacity
		}

		-- Add Landmark information to the town
		for i = 1, #ai.landmark[name].types do ai.town[town][ai.landmark[name].type[i]] = name end

	end

	--- Town Actions
	--  @section town
	--

	---Adds a new town to the map.  (NEEDS to be extended with additional RECTs)
	---@param name string   This is the name of the town.  This is used to reference the town in other functions
	---@param activityProbability number Specifies the percentage chance that a unit will run down an activity per unit tick
	---@param tickMultiplier number multiples the AI Tick by this value for every unit contained in this town.  If the tick is set to 3 seconds and the multiplier is set to 2, the tick for this town's unit will be 6 seconds.
	---@return boolean
	function ai.town.New(name, activityProbability, tickMultiplier)

		activityProbability = activityProbability or 5
		tickMultiplier = tickMultiplier or 1

		-- Add to list of towns
		table.insert(ai.townNames, name)

		-- Init the Town
		ai.town[name] = {

			-- Add Town Name
			name = name,
			hostileForce = nil,

			-- States
			state = "Auto",
			stateCurrent = "Normal",
			states = {"Auto", "Normal", "Danger", "Pause", "Paused", "Abadon", "Gather"},

			-- Units
			units = CreateGroup(),
			unitCount = 0,

			-- AI Activity Probability
			activityProbability = activityProbability,

			-- AI Intelligence Tick
			tickMultiplier = tickMultiplier,

			-- Set Up Landmarks
			residence = {},
			safehouse = {},
			barracks = {},
			gathering = {},

			-- Set Up town Regions
			region = CreateRegion(),
			rects = {}
		}

		return true
	end

	---Extend the town coverage to include the region
	---@param name any
	---@param rect any
	---@return boolean
	function ai.town.Extend(name, rect)
		RegionAddRect(ai.town[name].region, rect)

		return true
	end

	---Change the State of the Town. (Currently doesn't do anything)
	---@param town string
	---@param state string
	---@return boolean
	function ai.town.State(town, state)

		if TableContains(ai.town[town].states, state) then
			ai.town[town].state = state
			ai.town[town].stateCurrent = state

			ai.townSTATE[state](town)

			return true
		end

		return false
	end

	---Sets the Hostile force for the selected town
	---@param town string
	---@param force any
	---@return boolean
	function ai.town.HostileForce(town, force)

		ai.town[town].force = force
		return true

	end

	---Sets All units to be Vulnerable / Invulnerable in the selected town
	---@param town string
	---@param flag boolean
	---@return boolean
	function ai.town.VulnerableUnits(town, flag)

		ForGroup(ai.town[town].units, function()
			local unit = GetEnumUnit()

			SetUnitInvulnerable(unit, flag)
		end)

		return true

	end

	---Sets the route for every unit in the selected town to the chosen route whether it's in their list of routes or not immediately
	---@param town string
	---@param route string
	function ai.town.UnitsSetRoute(town, route)
		ForGroup(ai.town[town].units, function()
			local unit = GetEnumUnit()

			Debugfunc(function()
				ai.unit.PickRoute(unit, route)
				ai.unit.MoveToNextStep(unit, true)
			end, "Gather")
		end)
	end

	---Sets All units in a town to the specified state
	---@param town any
	---@param state any
	function ai.town.UnitsSetState(town, state)
		ForGroup(ai.town[town].units, function()
			local unit = GetEnumUnit()

			ai.unit.State(unit, state)
		end)
	end

	---Hurt all units in the town by a random percent of their health from the low number to the high number, If kill is false, units won't be killed by this, but their health will be set to 1 percent
	---@param town string
	---@param low number
	---@param high number
	---@param kill boolean
	---@return boolean
	function ai.town.UnitsHurt(town, low, high, kill)

		ForGroup(ai.town[town].units, function()
			local unit = GetEnumUnit()
			local percentLife = GetUnitLifePercent(unit)
			local randInt = GetRandomInt(low, high)

			percentLife = percentLife - randInt
			if not kill and percentLife <= 0 then percentLife = 1 end

			SetUnitLifePercentBJ(unit, percentLife)
		end)

		return true
	end

	---Set the life of all units in a town to a random percent from low to high.
	---@param town string
	---@param low number
	---@param high number
	---@return boolean
	function ai.town.UnitsSetLife(town, low, high)

		ForGroup(ai.town[town].units, function()
			local unit = GetEnumUnit()
			local percentLife = GetRandomInt(low, high)

			SetUnitLifePercentBJ(unit, percentLife)
		end)

		return true
	end

	---Region Actions
	-- @section Region
	--

	---Set up a new region (Internal Function)
	---@param rect any
	function ai.region.New(rect)

		local id = GetHandleId(rect)

		if ai.region[id] == nil then
			ai.region[id] = {
				xMin = GetRectMinX(rect),
				xMax = GetRectMaxX(rect),
				yMin = GetRectMinY(rect),
				yMax = GetRectMaxY(rect),
				x = GetRectCenterX(rect),
				y = GetRectCenterY(rect),
				id = id,
				region = CreateRegion()
			}

			-- Set up Region
			RegionAddRect(ai.region[id].region, rect)

			-- Add Event to AI Region Enter Trigger
			TriggerRegisterEnterRegionSimple(ai.trig.UnitEntersRegion, ai.region[id].region)
		end

	end

	---Get Random point in the specified region.
	---@param id number Handle Id of soure Rect
	---@return number x
	---@return number y
	function ai.region.GetRandom(id)
		local data = ai.region[id]

		return GetRandomReal(data.xMin, data.xMax), GetRandomReal(data.yMin, data.yMax)
	end

	---Get Center point in the specified region  
	---@param id number Handle Id of soure Rect
	---@return number x
	---@return number y
	function ai.region.GetCenter(id) return ai.region[id].x, ai.region[id].y end

	---Check to see if region contains a unit
	---@param id number Handle Id of soure Rect
	---@param unit any
	---@return boolean
	function ai.region.ContainsUnit(id, unit)
		local data = ai.region[id]
		local x = GetUnitX(unit)
		local y = GetUnitY(unit)

		if data.xMin < x and data.xMax > x and data.yMin < y and data.yMax > y then
			return true
		else
			return false
		end
	end

	---Route Actions
	-- @section route
	--

	---Creates a new route that villagers can take when Moving.  Make sure to specify all Steps, Actions and Triggers before creating an additional route
	---@param name  string  Route Name
	---@param loop  boolean Whether or not the route is a loop
	---@param type  string  inTown or outOfTown
	---@return      boolean
	function ai.route.New(name, loop, type)

		ai.routeSetup = name
		-- Set up the route Vars
		ai.route[name] = {name = name, type = type, step = {}, stepCount = 0, endSpeed = nil, loop = loop}

		return true
	end

	---Adds at the end of the selected route, a new place for a unit to move to.
	---@param rect          rect    The Rect (GUI Region) that the unit will walk to
	---@param speed         number  OPTIONAL | Unit Speed | Walk/Run speed of unit.  (under 100 will walk)
	---@param point         string  OPTIONAL | "center" | [center, random] Picks either the center of the Rect or a random point in the rect.
	---@param order         number  OPTIONAL | oid.move |  the order to use to move.
	---@param animationTag  string  OPTIONAL | nil | an anim tag to add to the unit while walking
	---@return              boolean 
	function ai.route.Step(rect, speed, point, order, animationTag)

		-- Set default values if one wasn't specified
		point = point or "center"
		speed = speed or nil
		order = order or oid.move

		-- Set Bas Vars
		local route = ai.routeSetup
		local regionId = GetHandleId(rect)

		-- Add Event to Rect Entering Trigger if not already added
		ai.region.New(rect)

		-- Update the count of steps in the route
		local stepCount = ai.route[route].stepCount + 1

		-- Add the step to the route
		ai.route[route].stepCount = stepCount

		ai.route[route].step[stepCount] = {
			regionId = regionId,
			speed = speed,
			actionCount = 0,
			point = point,
			order = order,
			action = {},
			animationTag = animationTag
		}

		return true

	end

	---Adds an additional action to the picked route step  Applies to the latest defined Route
	---@param time number The amount of time the unit will stop for before continueing on to the next action / step / trigger
	---@param lookAtRect rect OPTIONAL | nil | The rect that the unit will need to look at
	---@param animation string OPTIONAL | nil | The string of the animation you want the unit to play at this action
	---@param loop boolean OPTIONAL | false | Whether or not the animation specified should loop until the end or play once and pause
	---@return boolean
	function ai.route.Action(time, lookAtRect, animation, loop)

		-- Set default values if one wasn't specified
		local route = ai.routeSetup
		animation = animation or nil
		lookAtRect = lookAtRect or nil
		loop = loop or false

		-- Update the action Count for the Route
		local stepCount = ai.route.StepCount(route)
		local actionCount = ai.route.ActionCount(route, stepCount) + 1

		-- Add the action to the Step in the Route
		ai.route[route].step[stepCount].actionCount = actionCount
		ai.route[route].step[stepCount].action[actionCount] = {
			type = "action",
			time = time,
			lookAtRect = lookAtRect,
			animation = animation,
			loop = loop
		}

		return true

	end

	---Add a trigger to the step as the next action.  (Needs to be a GUI Defined trigger)
	---The trigger needs to have the first and last line of the trigger be exactly as definitely in the test action in the test project or it will break the GUI
	---@param trigger any
	---@return boolean
	function ai.route.Trigger(trigger)
		-- Update the action Count for the Route
		local route = ai.routeSetup
		local stepCount = ai.route.StepCount(route)
		local actionCount = ai.route.ActionCount(route, stepCount) + 1

		-- Add the action to the Step in the Route
		ai.route[route].step[stepCount].actionCount = actionCount
		ai.route[route].step[stepCount].action[actionCount] = {type = "trigger", trigger = trigger}

		return true
	end

	---Adds a Function to the Route (NOT FINISHED)
	---@param funct any
	---@return boolean
	function ai.route.Funct(funct)
		-- Update the action Count for the Route
		local route = ai.routeSetup
		local stepCount = ai.route.StepCount(route)
		local actionCount = ai.route.ActionCount(route, stepCount) + 1

		-- Add the action to the Step in the Route
		ai.route[route].step[stepCount].actionCount = actionCount
		ai.route[route].step[stepCount].action[actionCount] = {type = "function", funct = funct}

		return true
	end

	---Finish out the route and specify the speed at which units should use to go back to their home positions
	---@param speed any
	---@return boolean
	function ai.route.Finish(speed)
		speed = speed or nil

		ai.route[ai.routeSetup].endSpeed = speed

		return true
	end

	---Get the Count of steps in a route
	---@param route string
	---@return any
	function ai.route.StepCount(route) return ai.route[route].stepCount end

	---Get the Count of Actions in a Step
	---@param route string
	---@param step string
	---@return any
	function ai.route.ActionCount(route, step) return ai.route[route].step[step].actionCount end

	---Unit Actions
	-- @section unit
	--

	---Adds a unit that exists into the fold to be controlled by the AI.
	---@param town string This is the town that will control aspects of the Unit
	---@param type string This specifies the state the unit has access to see States for more info
	---@param unit any The unit that will be added to the AI
	---@param name string OPTIONAL | Default Name of Unit | The name of the unit. (This will rename the unit in game to this)
	---@param shift string OPTIONAL | "day" | ["day", "night", "all"] Specifies when the unit will be active
	---@param radius number OPTIONAL | 600 | Specifies the units vision radius it uses to detect actions.
	---@return boolean
	---@see states
	function ai.unit.New(town, type, unit, name, shift, radius)

		shift = shift or "day"
		radius = radius or 600

		local handleId = GetHandleId(unit)
		local x = GetUnitX(unit)
		local y = GetUnitY(unit)

		-- Add to Unit groups
		GroupAddUnit(ai.town[town].units, unit)
		GroupAddUnit(ai.unitGroup, unit)

		-- Update Unit Count
		ai.town[town].unitCount = CountUnitsInGroup(ai.town[town].units)
		ai.unit.count = CountUnitsInGroup(ai.unitGroup)

		ai.unit[handleId] = {}
		ai.unit[handleId] = {
			id = handleId,
			unitType = GetUnitTypeId(unit),
			unitName = GetUnitName(unit),
			paused = false,
			town = town,
			name = name,
			enemies = 0,
			alertedAllies = 0,
			tick = ai.tick * ai.town[town].tickMultiplier,
			loop = GetRandomReal(0, ai.tick * ai.town[town].tickMultiplier),
			shift = shift,
			state = "Auto",
			type = type,
			regionId = nil,
			walking = false,
			speed = GetUnitMoveSpeed(unit),
			speedDefault = GetUnitMoveSpeed(unit),
			route = nil,
			radius = radius,
			looped = false,
			stepNumberStart = 0,
			stepNumber = 0,
			actionNumber = 0,
			orderLast = nil,
			routes = {},
			xHome = x,
			yHome = y,
			rectHome = Rect(x - 100, y - 100, x + 100, y + 100),
			facingHome = GetUnitFacing(unit),
			xDest = nil,
			yDest = nil
		}

		if type == "villager" then
			ai.unit[handleId].states = {"Relax", "Move", "Sleep", "ReturnHome", "Moving", "ReturningHome", "Waiting"}
			ai.unit[handleId].stateCurrent = "Relax"

		end

		return true
	end

	---Adds a route to a unit. (Unit must already be in the AI or else this will fail)
	---@param unit any
	---@param route string
	---@return boolean
	function ai.unit.AddRoute(unit, route)
		local handleId = GetHandleId(unit)

		if ai.route[route] ~= nil then
			table.insert(ai.unit[handleId].routes, route)
			return true
		end

		return false

	end

	---Removes the route from the units list of routes
	---@param unit any
	---@param route string
	---@return boolean
	function ai.unit.RemoveRoute(unit, route)
		local handleId = GetHandleId(unit)
		local routes = ai.unit[handleId].routes

		if TableContains(routes, route) then
			ai.unit[handleId].routes = TableRemoveValue(routes, route)
			return true
		end

		return false
	end

	--- Kills the Unit and removes it from AI
	---@param unit any
	function ai.unit.Kill(unit)
		local handleId = GetHandleId(unit)
		local data = ai.unit[handleId]
		ai.unit[handleId] = nil
		GroupRemoveUnit(ai.unitGroup, unit)
		GroupRemoveUnit(ai.town[data.town].units, unit)

		KillUnit(unit)

		return true
	end

	--- Remove the Unit from the AI (Unit will be controlled as if it was an ordinary Unit)
	---@param unit any
	function ai.unit.Remove(unit)
		local handleId = GetHandleId(unit)
		local data = ai.unit[handleId]
		ai.unit[handleId] = nil
		GroupRemoveUnit(ai.unitGroup, unit)
		GroupRemoveUnit(ai.town[data.town].units, unit)

		return true
	end

	--- Pause the Unit
	---@param unit any
	---@param flag boolean If true the unit will pause, if false the unit will unpause
	function ai.unit.Pause(unit, flag)
		local handleId = GetHandleId(unit)

		PauseUnit(unit, flag)
		ai.unit[handleId].paused = flag

		return true
	end

	--- Pick a Route from the Units avalable routes and set it up (Unit will not start moving down the route, this ONLY gets it ready to)
	---@param unit any The Unit in the AI system
	---@param route string OPTIONAL if you want a specific route chosen else it will pick one
	---@param stepNumber integer OPTIONAL if you want a specific Step chosen else it will start at the beginning
	---@param actionNumber integer OPTIONAL if you want a specific Action chosen else it will start at the beginning
	function ai.unit.PickRoute(unit, route, stepNumber, actionNumber)
		local data = ai.unit[GetHandleId(unit)]

		if #data.routes == 0 and route == nil then return false end

		route = route or data.routes[GetRandomInt(1, #data.routes)]

		local routeData = ai.route[route]

		if stepNumber == nil then
			if routeData.loop == true then
				local newDistance = 0
				local distance = 9999999
				local x = GetUnitX(unit)
				local y = GetUnitY(unit)

				local regionX, regionY

				for i = 1, routeData.stepCount do
					regionX, regionY = ai.region.GetCenter(routeData.step[i].regionId)

					newDistance = DistanceBetweenCoordinates(x, y, regionX, regionY)

					if distance > newDistance and not ai.region.ContainsUnit(routeData.step[i].regionId, unit) then
						distance = newDistance
						stepNumber = i
					end
				end

				stepNumber = stepNumber - 1
			end
		end

		stepNumber = stepNumber or 0
		actionNumber = actionNumber or 0

		ai.unit[data.id].route = route
		ai.unit[data.id].stepNumber = stepNumber
		ai.unit[data.id].looped = false
		ai.unit[data.id].stepNumberStart = stepNumber
		ai.unit[data.id].actionNumber = actionNumber

		return true
	end

	--- Run next Step in a Units Current Route
	---Run the next Step in the Unit's current Route
	---@param unit any
	---@return boolean
	function ai.unit.NextStep(unit)
		local data = ai.unit[GetHandleId(unit)]

		local stepNumber = ai.unit[data.id].stepNumber + 1

		-- If there are no more steps, return
		if stepNumber > ai.route[data.route].stepCount then return false end

		local step = ai.route[data.route].step[stepNumber]
		local speed = step.speed or data.speedDefault

		-- Set new Unit Step Info || Reset Action Number
		ai.unit[data.id].stateCurrent = "Moving"
		ai.unit[data.id].stepNumber = stepNumber
		ai.unit[data.id].actionNumber = 0
		ai.unit[data.id].regionId = step.regionId
		ai.unit[data.id].speed = speed

		-- Get new Destination for unit
		if step.point == "random" then
			ai.unit[data.id].xDest, ai.unit[data.id].yDest = ai.region.GetRandom(step.regionId)
		else
			ai.unit[data.id].xDest, ai.unit[data.id].yDest = ai.region.GetCenter(step.regionId)
		end

		-- Set whether unit should run or walk.
		if speed <= 100 then
			BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED, 120.00)
			AddUnitAnimationPropertiesBJ(true, "cinematic", unit)
			ai.unit[data.id].walk = true
		else
			BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED, 270.00)
			AddUnitAnimationPropertiesBJ(false, "cinematic", unit)
			ai.unit[data.id].walk = false
		end

		SetUnitMoveSpeed(unit, speed)

		-- Issue Move Order
		IssuePointOrderById(unit, step.order, ai.unit[data.id].xDest, ai.unit[data.id].yDest)

		return true
	end

	--- Run the units next Route Action
	---Run the Next Action in the Units Current Step in its current Route
	---@param unit any
	---@return boolean
	function ai.unit.NextAction(unit)
		local data = ai.unit[GetHandleId(unit)]

		-- Get Default Variable
		local tick = 0.1

		local stepNumber = data.stepNumber
		local actionNumber = data.actionNumber + 1

		-- If There doesn't exist the current step cancel
		if stepNumber == nil then return end
		if stepNumber > ai.route[data.route].stepCount or stepNumber == 0 then return false end

		-- If there are no more actions, return
		if actionNumber > ai.route[data.route].step[stepNumber].actionCount then return false end

		ai.unit[data.id].actionNumber = actionNumber

		-- If current State is Moving
		if data.stateCurrent == "Moving" then

			-- Get Next Action
			local step = ai.route[data.route].step[stepNumber]
			local action = step.action[actionNumber]

			-- Change State to "Waiting"
			ai.unit[data.id].stateCurrent = "Waiting"

			if action.type == "action" then

				if action.lookAtRect ~= nil then
					local x = GetUnitX(unit)
					local y = GetUnitY(unit)

					-- Get the angle to the rect and find a point 10 units in that direction
					local facingAngle = AngleBetweenCoordinates(x, y, GetRectCenterX(action.lookAtRect),
                                            					GetRectCenterY(action.lookAtRect))

					-- Get Position 10 units away in the correct direction
					local xNew, yNew = PolarProjectionCoordinates(x, y, 10, facingAngle)

					-- Move unit to direction
					IssuePointOrderById(unit, oid.move, xNew, yNew)

					-- Wait for unit to stop Moving or 2 seconds
					WaitWhileOrder(unit, 4)
				end

				if action.animation ~= nil then
					SetUnitAnimation(unit, action.animation)

					-- Loop Animation if checked
					if action.loop then for i = 1, math.floor(action.time) do QueueUnitAnimation(unit, action.animation) end end

					QueueUnitAnimation(unit, "Stand")
				end

				PolledWait(action.time)

				-- Change State to "Moving"
				SetUnitAnimation(unit, oid.stop)
				ai.unit[data.id].stateCurrent = "Moving"

			elseif action.type == "trigger" then

				-- Set Temp Global Data that needs to get passed to trigger
				udg_AI_TriggeringUnit = unit
				udg_AI_TriggeringId = data.id
				udg_AI_TriggeringState = data.stateCurrent
				udg_AI_TriggeringRegion = step.rect
				udg_AI_TriggeringRoute = data.route
				udg_AI_TriggeringStep = data.stepNumber
				udg_AI_TriggeringAction = data.actionNumber

				ai.unit[data.id].stateCurrent = "Waiting"

				-- Run the trigger (Ignoring Conditions)
				TriggerExecute(action.trigger)

				while ai.unit[data.id].stateCurrent == "Waiting" do PolledWait(.5) end

				ai.unit[data.id].stateCurrent = "Moving"
			end
		end

		return true
	end

	--- Set the Unit State
	---Set the Unit's Current state (This is an active step that will change the state and run a set of commands for that state)
	---Current list of states are {"Move", "Relax", "ReturnHome"}
	---@param unit any
	---@param state string
	---@return boolean
	function ai.unit.State(unit, state)
		local data = ai.unit[GetHandleId(unit)]

		if TableContains(ai.unit[data.id].states, state) then
			ai.unit[data.id].state = state

			ai.unitSTATE[state](unit)

			return true
		end

		return false
	end

	---Update the Units Intel (Will run automatically at the unit's tick)
	---@param unit any
	function ai.unit.IntelPre(unit)

		local data = ai.unit[GetHandleId(unit)]

		local u

		local enemies = 0
		local alertedAllies = 0
		local g = CreateGroup()
		local l = GetUnitLoc(unit)

		-- g = GetUnitsInRangeOfLocAll(data.radius, l)

		-- u = FirstOfGroup(g)
		-- while u ~= nil do

		--     -- Look for alerted Allies or Enemy units
		--     if IsUnitInForce(u, ai.town[data.town].hostileForce) then
		--         enemies = enemies + 1
		--     elseif IsUnitInGroup(u, ai.unitGroup) and
		--         ai.unit[GetHandleId(u)].alerted == true then
		--         alertedAllies = alertedAllies + 1
		--     end

		--     GroupRemoveUnit(g, u)
		--     u = FirstOfGroup(g)
		-- end
		-- DestroyGroup(g)
		-- RemoveLocation(l)

		-- ai.unit[data.id].enemies = enemies
		-- ai.unit[data.id].alertedAllies = alertedAllies
	end

	---Runs a post check of intel after all states and Intel have been gathered at the end of a unit's tick
	---@param unit any
	---@return boolean
	function ai.unit.IntelPost(unit)
		local data = ai.unit[GetHandleId(unit)]

		ai.unit[data.id].orderLast = GetUnitCurrentOrder(unit)
		return true

	end

	---Goes to either the Units next Step, Action or Ends the route  (Use this in GUI 99% of the time)
	---@param unit any
	---@param immediately any OPTIONAL | false | If set to true the function will wait to issue the next step until after the unit has stopped moving
	---@return boolean
	function ai.unit.MoveToNextStep(unit, immediately)

		immediately = immediately or false

		Debugfunc(function()
			local data = ai.unit[GetHandleId(unit)]

			-- Set Local Variables
			local success = true
			local tick = 0.1

			-- Wait until unit stops Moving or 2 seconds
			if not immediately then WaitWhileOrder(unit, 4) end

			-- Order Unit to stop
			IssueImmediateOrder(unit, oid.stop)

			-- Keep running actions unit finished with step
			while success do success = ai.unit.NextAction(unit) end

			-- Run next Step
			if ai.unit[data.id].looped and ai.unit[data.id].stepNumber > data.stepNumberStart then

				local speed = ai.route[data.route].endSpeed or data.speedDefault

				if speed < 100 then
					BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED, 100.00)
					AddUnitAnimationPropertiesBJ(true, "cinematic", unit)
					ai.unit[data.id].walk = true
				else
					BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED, 270.00)
					AddUnitAnimationPropertiesBJ(false, "cinematic", unit)
					ai.unit[data.id].walk = false
				end

				SetUnitMoveSpeed(unit, speed)

				ai.unit.State(unit, "ReturnHome")
			else
				success = ai.unit.NextStep(unit)

				-- If route is finished Send unit Home
				if not success then

					if ai.route[data.route].loop then
						ai.unit[data.id].looped = true
						ai.unit[data.id].stepNumber = 0
						ai.unit[data.id].actionNumber = 0
						success = ai.unit.NextStep(unit)
					else

						local speed = ai.route[data.route].endSpeed or data.speedDefault

						if speed < 100 then
							BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED, 100.00)
							AddUnitAnimationPropertiesBJ(true, "cinematic", unit)
							ai.unit[data.id].walk = true
						else
							BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED, 270.00)
							AddUnitAnimationPropertiesBJ(false, "cinematic", unit)
							ai.unit[data.id].walk = false
						end

						SetUnitMoveSpeed(unit, speed)

						ai.unit.State(unit, "ReturnHome")
					end
				end
			end
		end, "Test")
		return true
	end

	---Unit States
	-- @section unitStates

	---This runs when a unit's state is changed to Move.  Will pick a route from the units available routes and send them on the quest
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Move(unit)
		local data = ai.unit[GetHandleId(unit)]

		if #data.routes == 0 and data.route == nil then return false end

		local route = data.routes[GetRandomInt(1, #data.routes)]

		ai.unit.PickRoute(unit)
		ai.unit.MoveToNextStep(unit)

		return true
	end

	---This runs when a unit's state is changed to Relax.  Unit is not moving or doing anything.  Just standing.  At unit's tick, has a chance to tell the unit to go into another state.
	---@param unit any
	function ai.unitSTATE.Relax(unit)
		local data = ai.unit[GetHandleId(unit)]

		local prob = GetRandomInt(1, 100)

		if ai.town[data.town].activityProbability >= prob then

			-- Order Unit to Move onto one of it's routes
			if TableContains(data.states, "Move") then ai.unit.State(unit, "Move") end

		end

	end

	---This runs when a Unit's state is changed to ReturnHome.  The unit will stop what it's doing, clear out it's current route and begin to walk back to it's home position and facing angle
	---@param unit any
	---@return boolean
	function ai.unitSTATE.ReturnHome(unit)
		local data = ai.unit[GetHandleId(unit)]

		ai.unit[data.id].stateCurrent = "ReturningHome"
		ai.unit[data.id].route = nil
		ai.unit[data.id].stepNumber = 0
		ai.unit[data.id].actionNumber = 0
		ai.unit[data.id].xDest = nil
		ai.unit[data.id].yDest = nil
		ai.unit[data.id].speed = nil

		IssuePointOrderById(unit, oid.move, data.xHome, data.yHome)

		return true
	end

	---Unit States Transient
	-- @section unitStates Transient
	--

	---This is an inbetween state.  Don't manually set it's state to this.
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Moving(unit)
		local data = ai.unit[GetHandleId(unit)]

		if GetUnitCurrentOrder(unit) ~= oid.move and data.orderLast ~= oid.Move then ai.unit.MoveToNextStep(unit) end

		return true
	end

	---This is an inbetween state.  Don't manually set it's state to this.
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Waiting(unit)

		-- Do nothing, come on now, what did you think was going to be here??
		return true
	end

	---This is an inbetween state.  Don't manually set it's state to this.
	---@param unit any
	---@return boolean
	function ai.unitSTATE.ReturningHome(unit)
		local data = ai.unit[GetHandleId(unit)]

		local x = GetUnitX(unit)
		local y = GetUnitY(unit)

		if GetUnitCurrentOrder(unit) ~= oid.move then
			if not RectContainsUnit(data.rectHome, unit) then
				IssuePointOrderById(unit, oid.move, data.xHome, data.yHome)

			else
				ai.unit[data.id].stateCurrent = "Relax"
				local xNew, yNew = PolarProjectionCoordinates(x, y, 10, data.facingHome)
				IssuePointOrderById(unit, oid.move, xNew, yNew)
			end
		end

		return true
	end

	--
	---TRIGGERS
	-- @section triggers

	--
	--  UNIT LOOPS
	--

	-- Loop to get on Unit Intellegence
	ai.trig.UnitLoop = CreateTrigger()
	TriggerRegisterTimerEventPeriodic(ai.trig.UnitLoop, (ai.tick / ai.split))

	DisableTrigger(ai.trig.UnitLoop)

	TriggerAddAction(ai.trig.UnitLoop, function()

		-- Set up Local Variables
		local u, data
		local g = CreateGroup()

		-- Add all AI units to the group
		GroupAddGroup(ai.unitGroup, g)

		-- Loop through the Units and check to see if they need anything
		u = FirstOfGroup(g)
		while u ~= nil do
			data = ai.unit[GetHandleId(u)]

			ai.unit[data.id].loop = data.loop + (ai.tick / ai.split)

			-- Check to see if it's time to have the Unit Update itself
			if ai.unit[data.id].loop > (data.tick * ai.town[data.town].tickMultiplier) then
				ai.unit[data.id].loop = 0

				-- Run the routine for the unit's current state
				ai.unit.IntelPre(u)
				ai.unit.State(u, data.stateCurrent)
				ai.unit.IntelPost(u)

			end

			GroupRemoveUnit(g, u)
			u = FirstOfGroup(g)
		end
		DestroyGroup(g)

	end)

	-- Trigger Unit enters a Rect in a Route
	ai.trig.UnitEntersRegion = CreateTrigger()
	DisableTrigger(ai.trig.UnitEntersRegion)
	TriggerAddAction(ai.trig.UnitEntersRegion, function()

		local unit = GetEnteringUnit()
		local region = GetTriggeringRegion()
		Debugfunc(function()
			-- If Unit is an AI Unit
			if IsUnitInGroup(unit, ai.unitGroup) then

				-- Get Unit Data
				local data = ai.unit[GetHandleId(unit)]

				-- If usit it on a route
				if data.route then

					-- If the Rect isn't the targetted end rect, ignore any future actions
					if region == ai.region[data.regionId].region then
						ai.unit.MoveToNextStep(unit)

						return true
					end
				end

			end
		end, "Loop")
		return false
	end)

	--- AI Control
	-- @section control

	---Start Running the AI
	---@return boolean
	function ai.Start()

		-- Add Tick Event and Start Unit Loop Inteligence
		EnableTrigger(ai.trig.UnitLoop)

		-- Enable Unit Route Management
		EnableTrigger(ai.trig.UnitEntersRegion)

		return true

	end

	---Stop Running the AI
	---@return boolean
	function ai.Stop()

		-- Stop Unit Intelligence
		DisableTrigger(ai.trig.UnitLoop)

		-- Enable Unit Route Management
		DisableTrigger(ai.trig.UnitEntersRegion)

		return true
	end
end
