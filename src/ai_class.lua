---This Contains all of the Functions that you'll need to run and set up the AI.  Most of the functions won't need to be used.  As they're used for internal purposes.
---@author Mark Wright (KickKing)
ai = {
	landmark = {},
	town = {},
	region = {},
	route = {},
	unit = {},
	unitSTATE = {},
	townSTATE = {},
	landmarkSTATE = {},
	intel = {},
	trig = {},
	tick = 3,
	split = 7,
	tickTown = 5
}

---Initialization.
-- Initialization of AI Villagers
-- @section init

--- This Initialized everything needed to run Village AI. Run this before using any other functions in AI Villagers.
---@param tickUnit number    OPTIONAL | 2 | The interval at which each unit added to AI will update it's intelligence and make decisions   
---@param splitUnit number   OPTIONAL | 5 | The amount of splits that the Ticks will process Unit intelligence at.  1 means all AI ticks will be processed at the same time, 3 means processing will be split into 3 groups.
---@param tickTown number    OPTIONAL | 5 | The interval at which each Town added to AI will update it's intelligence and make decisions   
function ai.Init(tickUnit, splitUnit, tickTown)

	Debugfunc(function()

		-- Set Overall Tick if a value isn't specified
		ai.tick = tickUnit or ai.tick
		ai.split = splitUnit or ai.split
		ai.tickTown = tickTown or ai.tickTown

		ai.landmarkNames = {}
		ai.landmarkRegions = {}
		ai.townNames = {}
		ai.townRegions = {}
		ai.townCount = 0
		ai.unitGroup = CreateGroup()
		ai.unitGroupTick = CreateGroup()

		ai.landmark.Init()
		ai.town.Init()
		ai.region.Init()
		ai.route.Init()
		ai.unit.Init()
		ai.unitSTATE.Init()
		ai.townSTATE.Init()
		ai.intel.Init()
		ai.trig.Init()

		---Start Running the AI
		---@return boolean
		function ai.Start()

			-- Add Tick Event and Start Unit Loop Inteligence
			EnableTrigger(ai.trig.UnitLoop)
			EnableTrigger(ai.trig.TownLoop)

			-- Enable Unit Route Management
			EnableTrigger(ai.trig.UnitEntersRoute)
			EnableTrigger(ai.trig.UnitEntersTown)
			EnableTrigger(ai.trig.UnitEntersLandmark)

			return true

		end

		---Stop Running the AI
		---@return boolean
		function ai.Stop()

			-- Stop Unit Intelligence
			DisableTrigger(ai.trig.UnitLoop)

			-- Enable Unit Route Management
			DisableTrigger(ai.trig.UnitEntersRoute)

			return true
		end

	end, "Init")
end

---Landmark Actions
-- @section landmark
--

---Landmark Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.landmark.Init()

	---Creates a New Landmark and Adds it.
	---@param town string
	---@param name string
	---@param rect table
	---@param types table
	---@param unit table OPTIONAL nil |
	---@param maxCapacity number OPTIONAL Unlimited |
	function ai.landmark.New(town, name, rect, types, unit, maxCapacity)
		unit = unit or nil
		maxCapacity = maxCapacity or 500

		local handleId = GetHandleId(rect)

		-- Add initial variables to the table
		ai.landmark[name] = {
			id = handleId,
			alive = true,
			town = town,
			name = name,
			rect = rect,
			region = CreateRegion(),
			x = GetRectCenterX(rect),
			y = GetRectCenterY(rect),
			types = types,
			unit = unit,
			unitsInside = CreateGroup(),
			unitCount = 0,
			maxCapacity = maxCapacity
		}

		-- Set up region
		RegionAddRect(ai.landmark[name].region, rect)
		ai.landmarkRegions[GetHandleId(ai.landmark[name].region)] = name

		-- Add Region enter Trigger
		TriggerRegisterEnterRegionSimple(ai.trig.UnitEntersLandmark, ai.landmark[name].region)

		-- Add Landmark information to the town
		for i = 1, #types do table.insert(ai.town[town][types[i]], name) end

	end

	return true
end

--- Town Actions
--  @section town
--

---Town Functions Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.town.Init()

	---Adds a new town to the map.  (NEEDS to be extended with additional RECTs)
	---@param name string   This is the name of the town.  This is used to reference the town in other functions
	---@param activityProbability number Specifies the percentage chance that a unit will run down an activity per unit tick
	---@return boolean
	function ai.town.New(name, activityProbability)

		activityProbability = activityProbability or 5

		-- Add to list of towns
		table.insert(ai.townNames, name)
		ai.townCount = ai.townCount + 1

		-- Init the Town
		ai.town[name] = {

			-- Add Town Name
			name = name,
			hostileForce = nil,

			-- States
			state = "Relaxing",
			states = {"Relax", "Relaxing", "Caution", "Cautioning", "Alert", "Alerting", "Pause", "Pausing"},

			-- Units
			units = CreateGroup(),
			unitCount = 0,
			unitEnemies = 0,

			-- AI Activity Probability
			activityProbability = activityProbability,

			-- Set Up Landmarks
			residence = {},
			safehouse = {},
			barracks = {},
			gathering = {},

			-- Set Up town Regions
			region = CreateRegion(),
			rects = {}
		}

		-- Add region Key to the Database
		ai.townRegions[GetHandleId(ai.town[name].region)] = name

		-- Add event to the town entering
		TriggerRegisterEnterRegionSimple(ai.trig.UnitEntersTown, ai.town[name].region)

		return true
	end

	---Extend the town coverage to include the region
	---@param name any
	---@param rect any
	---@return boolean
	function ai.town.Extend(name, rect)
		RegionAddRect(ai.town[name].region, rect)
		table.insert(ai.town[name].rects, rect)

		return true
	end

	---Change the State of the Town. (Currently doesn't do anything)
	---@param town string
	---@param state string
	---@return boolean
	function ai.town.State(town, state)

		if TableContains(ai.town[town].states, state) then
			ai.town[town].state = state
			ai.town[town].state = state

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

		ai.town[town].hostileForce = force
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
end

---Region Actions
-- @section Region
--

---Region Functions Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.region.Init()
	---Set up a new region (Internal Function, Don't need to use)
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
			TriggerRegisterEnterRegionSimple(ai.trig.UnitEntersRoute, ai.region[id].region)
		end

	end

	---Get Random point in the specified region.
	---@param id number Handle Id of soure Rect
	---@return number x
	---@return number y
	function ai.region.GetRandomCoordinates(id)
		local data = ai.region[id]

		return GetRandomReal(data.xMin, data.xMax), GetRandomReal(data.yMin, data.yMax)
	end

	---Get Center point in the specified region  
	---@param id number Handle Id of soure Rect
	---@return number x
	---@return number y
	function ai.region.GetCenterCoordinates(id) return ai.region[id].x, ai.region[id].y end

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
end

---Route Actions
-- @section route
--

---Route Functions Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.route.Init()

	---Creates a new route that villagers can take when Moving.  Make sure to specify all Steps, Actions and Triggers before creating an additional route
	---@param name  string  Route Name
	---@param loop  boolean Whether or not the route is a loop
	---@return      boolean
	function ai.route.New(name, loop)

		ai.routeSetup = name
		-- Set up the route Vars
		ai.route[name] = {name = name, step = {}, stepCount = 0, endSpeed = nil, loop = loop}

		return true
	end

	---Adds at the end of the selected route, a new place for a unit to move to.
	---@param rect          any    The Rect (GUI Region) that the unit will walk to
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
	---@param lookAtRect any OPTIONAL | nil | The rect that the unit will need to look at
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
end

---Unit Actions
-- @section unit
--

---Unit Functions Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.unit.Init()

	---Adds a unit that exists into the fold to be controlled by the AI.
	---@param town string This is the town that will control aspects of the Unit
	---@param type string This specifies the state the unit has access to see States for more info
	---@param unit any The unit that will be added to the AI
	---@param name string OPTIONAL | Default Name of Unit | The name of the unit. (This will rename the unit in game to this)
	---@param shift string OPTIONAL | "day" | ["day", "night", "all"] Specifies when the unit will be active
	---@param radius number OPTIONAL | 600 | Specifies the units vision radius it uses to detect actions.
	---@return boolean
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
			shift = shift,
			type = type,
			regionId = nil,
			landmark = nil,
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
			ai.unit[handleId].states = {
				"Relax", "Relaxing", "Move", "Moving", "Flee", "Fleeing", "Hide", "Hiding", "Return", "Sleep", "Sleeping",
    "ReturnHome", "ReturningHome", "Wait", "Waiting"
			}
			ai.unit[handleId].state = "Relax"

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
					regionX, regionY = ai.region.GetCenterCoordinates(routeData.step[i].regionId)

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
		if stepNumber == nil or data.route == nil then return false end
		if stepNumber > ai.route[data.route].stepCount then return false end

		local step = ai.route[data.route].step[stepNumber]
		local speed = step.speed or data.speedDefault

		-- Set new Unit Step Info || Reset Action Number
		ai.unit[data.id].state = "Moving"
		ai.unit[data.id].stepNumber = stepNumber
		ai.unit[data.id].actionNumber = 0
		ai.unit[data.id].regionId = step.regionId
		ai.unit[data.id].speed = speed

		-- Get new Destination for unit
		if step.point == "random" then
			ai.unit[data.id].xDest, ai.unit[data.id].yDest = ai.region.GetRandomCoordinates(step.regionId)
		else
			ai.unit[data.id].xDest, ai.unit[data.id].yDest = ai.region.GetCenterCoordinates(step.regionId)
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
		if stepNumber == nil or data.route == nil then return end
		if stepNumber > ai.route[data.route].stepCount or stepNumber == 0 then return false end

		-- If there are no more actions, return
		if actionNumber > ai.route[data.route].step[stepNumber].actionCount then return false end

		ai.unit[data.id].actionNumber = actionNumber

		-- If current State is Moving
		if data.state == "Moving" then

			-- Get Next Action
			local step = ai.route[data.route].step[stepNumber]
			local action = step.action[actionNumber]

			-- Change State to "Waiting"
			ai.unit[data.id].state = "Waiting"

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
				ai.unit[data.id].state = "Moving"

			elseif action.type == "trigger" then

				-- Set Temp Global Data that needs to get passed to trigger
				udg_AI_TriggeringUnit = unit
				udg_AI_TriggeringId = data.id
				udg_AI_TriggeringState = data.state
				udg_AI_TriggeringRegion = step.rect
				udg_AI_TriggeringRoute = data.route
				udg_AI_TriggeringStep = data.stepNumber
				udg_AI_TriggeringAction = data.actionNumber

				ai.unit[data.id].state = "Waiting"

				-- Run the trigger (Ignoring Conditions)
				TriggerExecute(action.trigger)

				while ai.unit[data.id].state == "Waiting" do PolledWait(.5) end

				ai.unit[data.id].state = "Moving"
			end
		end

		return true
	end

	--- Set the Unit State
	---Set the Unit's Current state (This is an active step that will change the state and run a set of commands for that state)
	---Current list of states are {"Move", "Relax", "ReturnHome", "Wait"}
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
end

---Town States
-- @section townStates

---Town States Functions Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.townSTATE.Init()

	---comment
	---@param name any
	---@return boolean
	function ai.townSTATE.Relax(name)
		local town = ai.town[name]

		ai.town[name].state = "Relaxing"
		return true
	end

	---comment
	---@param name any
	---@return boolean
	function ai.townSTATE.Caution(name)
		local town = ai.town[name]

		ai.town[name].state = "Cautioning"
		return true
	end

	---comment
	---@param name any
	---@return boolean
	function ai.townSTATE.Alert(name)
		local town = ai.town[name]

		ai.town[name].state = "Alerting"
		return true
	end

	---comment
	---@param name any
	---@return boolean
	function ai.townSTATE.Pause(name)
		local town = ai.town[name]

		ai.town[name].state = "Pausing"
		return true
	end

	--- Town States Transient
	-- @section townStatesTransient

	---comment
	---@param name any
	---@return boolean
	function ai.townSTATE.Relaxing(name)

		return true
	end

	---comment
	---@param name any
	---@return boolean
	function ai.townSTATE.Cautioning(name)
		local town = ai.town[name]

		if town.unitEnemies > 10 then
			ai.town.State(name, "Alert")
		elseif town.unitEnemies == 0 then
			ai.town.State(name, "Relax")
		end

		return true
	end

	---comment
	---@param name any
	---@return boolean
	function ai.townSTATE.Alerting(name)
		local town = ai.town[name]

		if town.unitEnemies <= 10 then
			ai.town.State(name, "Caution")
		elseif town.unitEnemies == 0 then
			ai.town.State(name, "Relax")
		end

		return true
	end

	---comment
	---@param name any
	---@return boolean
	function ai.townSTATE.Pausing(name)

		print("Pausing")

		return true
	end

end

---Unit States
-- @section unitStates

---Unit States Functions Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.unitSTATE.Init()

	---Will pick a route from the units available routes or specified route and send them on the quest
	---@param unit any
	---@param route any @OPTIONAL | Random route picked from units routes | This is the route that the specified unit will go on.
	---@return boolean
	function ai.unitSTATE.Move(unit, route)

		udg_AI_TriggeringUnit = unit
		TriggerExecuteBJ(gg_trg_Hook_Move, true)

		local data = ai.unit[GetHandleId(unit)]

		if #data.routes == 0 and data.route == nil then return false end

		-- Pick a Route if one doesn't Exist
		if route == nil then route = data.routes[GetRandomInt(1, #data.routes)] end

		ai.unit.PickRoute(unit)
		ai.unit.MoveToNextStep(unit)

		return true
	end

	---comment
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Flee(unit)

		udg_AI_TriggeringUnit = unit
		TriggerExecuteBJ(gg_trg_Hook_Flee, true)

		Debugfunc(function()

			local u, distanceNew, landmark, landmarkPicked

			local data = ai.unit[GetHandleId(unit)]
			local distance = 99999999

			local x = GetUnitX(unit)
			local y = GetUnitY(unit)
			for i = 1, #ai.town[data.town].safehouse do

				landmark = ai.landmark[ai.town[data.town].safehouse[i]]

				distanceNew = DistanceBetweenCoordinates(x, y, landmark.x, landmark.y)
				if distanceNew < distance and landmark.alive == true and landmark.unitCount < landmark.maxCapacity then
					distance = distanceNew
					landmarkPicked = landmark
				end
			end

			if landmarkPicked ~= nil then
				ai.unit[data.id].xDest = landmarkPicked.x
				ai.unit[data.id].yDest = landmarkPicked.y
				ai.unit[data.id].landmark = landmarkPicked.name

				-- Reset speed and animation
				SetUnitMoveSpeed(unit, data.speedDefault)
				BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED, 270.00)
				AddUnitAnimationPropertiesBJ(false, "cinematic", unit)

				
				-- Get unit to run to the landmark
				IssuePointOrderById(unit, oid.move, landmarkPicked.x, landmarkPicked.y)
			end

			-- Set state to Fleeing
			ai.unit[data.id].alerted = true

			if IsUnitInRegion(landmarkPicked.region, unit) then
				ai.unit.State(unit, "Hide")
			else
				ai.unit.State(unit, "Fleeing")
			end

			
		end, "Flee")

		return true
	end

	---comment
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Hide(unit)

		udg_AI_TriggeringUnit = unit
		TriggerExecuteBJ(gg_trg_Hook_Hide, true)

		Debugfunc(function()
			local data = ai.unit[GetHandleId(unit)]
			local landmark = ai.landmark[data.landmark]

			if landmark.unitCount >= landmark.maxCapacity then
				ai.unit.State(unit, "Flee")

			else
				ShowUnitHide(unit)
				PauseUnit(unit, true)

				ai.landmark[data.landmark].unitCount = ai.landmark[data.landmark].unitCount + 1
				GroupAddUnit(ai.landmark[data.landmark].unitsInside, unit)

				ai.unit.State(unit, "Hiding")
			end
		end, "Hide")

		return true
	end

	---comment
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Return(unit)

		-- Run Trigger Hook
		udg_AI_TriggeringUnit = unit
		TriggerExecuteBJ(gg_trg_Hook_Return, true)

		local data = ai.unit[GetHandleId(unit)]

		Debugfunc(function()

			-- Show Unit again
			PauseUnit(unit, false)
			ShowUnitShow(unit)

			-- Remove unit from Landmark
			GroupRemoveUnit(ai.landmark[data.landmark].unitsInside)
			ai.landmark[data.landmark].unitCount = ai.landmark[data.landmark].unitCount - 1
			ai.unit[data.id].alerted = false

			-- If unit has a route to finish, send them on the route
			ai.unit.State(unit, "ReturnHome")

		end, "Return")

		return true
	end

	---Same as Wait but will periodically transition to other states based on the town activitiy probability  Currently transitions to "Moving"
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Relax(unit)

		udg_AI_TriggeringUnit = unit
		TriggerExecuteBJ(gg_trg_Hook_Relax, true)

		local data = ai.unit[GetHandleId(unit)]


		-- Set state to Relaxing, then do nothing
		ai.unit[data.id].state = "Relaxing"

		return true
	end

	---Will not change state unless Prompted, shift change or Sensing danger
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Wait(unit)

		udg_AI_TriggeringUnit = unit
		TriggerExecuteBJ(gg_trg_Hook_Wait, true)

		local data = ai.unit[GetHandleId(unit)]

		-- Set state to waiting, then do nothing
		ai.unit[data.id].state = "Waiting"

		return true
	end

	---The unit will stop what it's doing, clear out it's current route and begin to walk back to it's home position and facing angle
	---@param unit any
	---@return boolean
	function ai.unitSTATE.ReturnHome(unit)
		local data = ai.unit[GetHandleId(unit)]

		ai.unit[data.id].state = "ReturningHome"
		ai.unit[data.id].route = nil
		ai.unit[data.id].stepNumber = 0
		ai.unit[data.id].actionNumber = 0
		ai.unit[data.id].xDest = nil
		ai.unit[data.id].yDest = nil
		ai.unit[data.id].speed = nil

		IssuePointOrderById(unit, oid.move, data.xHome, data.yHome)

		return true
	end

	--- Unit States Transient.
	-- These states are never set manually.  Only ever set units to have full states.
	-- @section unitStates

	---Unit will check to see if it's walking if not, then it will move to it's next order
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

	---comment
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Hiding(unit)
		local data = ai.unit[GetHandleId(unit)]
		local town = ai.town[data.town]

		if town.state == "Relaxing" then ai.unit.State(unit, "Return") end

		return true
	end

	---comment
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Fleeing(unit)
		local data = ai.unit[GetHandleId(unit)]

		if ai.town[data.town].state == "Relax" then ai.unit.state(unit, "ReturnHome") end

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
				ai.unit[data.id].state = "Relax"
				local xNew, yNew = PolarProjectionCoordinates(x, y, 10, data.facingHome)
				IssuePointOrderById(unit, oid.move, xNew, yNew)
			end
		end

		return true
	end

	---This runs when a unit's state is changed to Relax.  Unit is not moving or doing anything.  Just standing.  At unit's tick, has a chance to tell the unit to go into another state.
	---@param unit any
	---@return boolean
	function ai.unitSTATE.Relaxing(unit)
		local data = ai.unit[GetHandleId(unit)]

		local prob = GetRandomInt(1, 100)

		if ai.town[data.town].activityProbability >= prob then

			-- Order Unit to Move onto one of it's routes
			if TableContains(data.states, "Move") then ai.unit.State(unit, "Move") end

		end

		return true
	end
end

---Intel Checks.
-- All of the Intelligence Checks for units
-- @section intel

---Intel Functions Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.intel.Init()

	---Intelligence for Town Pre State Check
	---@param name any
	---@return boolean
	function ai.intel.TownPre(name)
		Debugfunc(function()

			local town = ai.town[name]

			if town.hostileForce ~= nil and (town.state == "Alerting" or town.state == "Cautioning") then
				local u

				local g = CreateGroup()
				local g2 = CreateGroup()

				local enemies = 0

				-- Get all Units in the groups
				for i = 1, #town.rects, 1 do
					g2 = GetUnitsInRectAll(town.rects[i])

					GroupAddGroup(g2, g)
					DestroyGroup(g2)
				end

				-- Find all enemies in the Unit group
				u = FirstOfGroup(g)
				while u ~= nil do

					if IsUnitInForce(u, town.hostileForce) and IsUnitAliveBJ(u) then enemies = enemies + 1 end

					GroupRemoveUnit(g, u)
					u = FirstOfGroup(g)
				end
				DestroyGroup(g)

				-- Update Town Info
				ai.town[name].unitEnemies = enemies
			end

		end, "Town Pre")
		return true
	end

	---Intellince for town Post State Check
	---@param town any
	---@return boolean
	function ai.intel.TownPost(town) return true end

	---Update the Units Intel (Will run automatically at the unit's tick)
	---@param unit any
	function ai.intel.UnitPre(unit)

		Debugfunc(function()
			local data = ai.unit[GetHandleId(unit)]

			-- Find out if enemies are around if the Town is issueing a warning
			if ai.town[data.town].state == "Cautioning" and data.state ~= "Fleeing" and data.state ~= "Hiding" then
				local u

				local enemies = 0
				local alertedAllies = 0
				local g = CreateGroup()
				local l = GetUnitLoc(unit)

				g = GetUnitsInRangeOfLocAll(data.radius, l)
				RemoveLocation(l)

				u = FirstOfGroup(g)
				while u ~= nil and enemies == 0 do

					-- Look for alerted Allies or Enemy units
					if IsUnitInForce(u, ai.town[data.town].hostileForce) and IsUnitAliveBJ(u) then
						enemies = enemies + 1
					elseif IsUnitInGroup(u, ai.unitGroup) and ai.unit[GetHandleId(u)].alerted == true then
						alertedAllies = alertedAllies + 1
					end

					GroupRemoveUnit(g, u)
					u = FirstOfGroup(g)
				end
				DestroyGroup(g)

				ai.unit[data.id].enemies = enemies
				ai.unit[data.id].alertedAllies = alertedAllies

				if enemies > 0 or alertedAllies > 3 then ai.unit.State(unit, "Flee") end
			else
				ai.unit[data.id].enemies = 0
				ai.unit[data.id].alertedAllies = 0
			end
		end, "Intel")

		return true
	end

	---Runs a post check of intel after all states and Intel have been gathered at the end of a unit's tick
	---@param unit any
	---@return boolean
	function ai.intel.UnitPost(unit)
		local data = ai.unit[GetHandleId(unit)]

		ai.unit[data.id].orderLast = GetUnitCurrentOrder(unit)

		return true

	end
end

---Triggers
-- @section triggers

---Trigger Functions Init runs when ai.Init() is run
---@see ai.Init
---@return boolean
function ai.trig.Init()
	--
	-- 	TOWN Loops
	--

	---Trigger to loop through towns and get unit info.  (Loops every 5 seconds)
	ai.trig.TownLoop = CreateTrigger()
	TriggerRegisterTimerEventPeriodic(ai.trig.TownLoop, 5)
	DisableTrigger(ai.trig.TownLoop)

	TriggerAddAction(ai.trig.TownLoop, function()
		local town

		for i = 1, ai.townCount, 1 do
			town = ai.town[ai.townNames[i]]

			ai.intel.TownPre(town.name)
			ai.town.State(town.name, town.state)
			ai.intel.TownPost(town.name)
		end

	end)

	--- The Trigger that Loops through units to get Unit Intellegence
	ai.trig.UnitLoop = CreateTrigger()
	TriggerRegisterTimerEventPeriodic(ai.trig.UnitLoop, (ai.tick / ai.split))
	DisableTrigger(ai.trig.UnitLoop)

	TriggerAddAction(ai.trig.UnitLoop, function()

		-- Set up Local Variables
		local u, data
		local unitLoopCount = math.floor(CountUnitsInGroup(ai.unitGroup) / ai.split)

		-- Loop through the Units and check to see if they need anything
		for i = 1, unitLoopCount, 1 do
			u = FirstOfGroup(ai.unitGroupTick)

			-- Reset the group if it's empty
			if u == nil then
				DestroyGroup(ai.unitGroupTick)
				ai.unitGroupTick = CreateGroup()
				GroupAddGroup(ai.unitGroup, ai.unitGroupTick)
				u = FirstOfGroup(ai.unitGroupTick)
			end

			data = ai.unit[GetHandleId(u)]

			-- Run the routine for the unit's current state
			ai.intel.UnitPre(u)
			ai.unit.State(u, data.state)
			ai.intel.UnitPost(u)

			GroupRemoveUnit(ai.unitGroupTick, u)
		end
	end)

	--
	--  Unit Enters Route Region
	--

	--- Trigger Unit enters a Rect in a Route
	ai.trig.UnitEntersRoute = CreateTrigger()
	DisableTrigger(ai.trig.UnitEntersRoute)
	TriggerAddAction(ai.trig.UnitEntersRoute, function()

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

	--- Trigger Unit enters Landmark
	ai.trig.UnitEntersLandmark = CreateTrigger()
	DisableTrigger(ai.trig.UnitEntersLandmark)
	TriggerAddAction(ai.trig.UnitEntersLandmark, function()

		Debugfunc(function()

			local enteringRegion = GetTriggeringRegion()
			local enteringUnit = GetEnteringUnit()

			if ai.landmarkRegions[GetHandleId(enteringRegion)] ~= nil and IsUnitInGroup(enteringUnit, ai.unitGroup) then

				local landmark = ai.landmark[ai.landmarkRegions[GetHandleId(enteringRegion)]]
				local unit = ai.unit[GetHandleId(enteringUnit)]

				if landmark.name == unit.landmark and unit.state == "Fleeing" then
					local town = ai.town[unit.town]

					ai.unit.State(enteringUnit, "Hide")

				end

			end
		end, "EnterLandmark")
	end)

	--
	--  Unit Enters Town Region
	--

	--- Trigger Unit enters Town
	ai.trig.UnitEntersTown = CreateTrigger()
	DisableTrigger(ai.trig.UnitEntersTown)
	TriggerAddAction(ai.trig.UnitEntersTown, function()

		Debugfunc(function()
			local enteringRegion = GetTriggeringRegion()
			local id = GetHandleId(enteringRegion)

			PingMinimap(GetUnitX(GetEnteringUnit()), GetUnitY(GetEnteringUnit()), 6)
			if ai.townRegions[id] ~= nil then
				local enteringUnit = GetEnteringUnit()
				local townName = ai.townRegions[id]
				local town = ai.town[townName]

				if IsUnitInForce(enteringUnit, town.hostileForce) and town.state == "Relaxing" then
					ai.town.State(townName, "Caution")
				end
			end

		end, "Town Loop")
		return true
	end)
end

