udg_townVillageHostile = nil
udg_AI_TriggeringUnit = nil
udg_AI_TriggeringRegion = nil
udg_AI_TriggeringRoute = ""
udg_AI_TriggeringStep = 0
udg_AI_TriggeringAction = 0
udg_AI_TriggeringState = ""
udg_AI_TriggeringId = 0
udg_townCityHostile = nil
gg_rct_Region_000 = nil
gg_rct_Region_001 = nil
gg_rct_Region_002 = nil
gg_rct_Region_003 = nil
gg_rct_Region_004 = nil
gg_rct_Region_005 = nil
gg_rct_Region_006 = nil
gg_rct_Region_007 = nil
gg_rct_Region_008 = nil
gg_rct_Region_009 = nil
gg_rct_Region_010 = nil
gg_rct_Region_011 = nil
gg_rct_Region_012 = nil
gg_rct_Region_013 = nil
gg_rct_Region_014 = nil
gg_rct_Region_015 = nil
gg_rct_Region_016 = nil
gg_rct_Region_017 = nil
gg_rct_Region_018 = nil
gg_rct_Region_019 = nil
gg_rct_Region_020 = nil
gg_rct_Region_021 = nil
gg_rct_Region_022 = nil
gg_rct_Region_023 = nil
gg_rct_Region_024 = nil
gg_rct_Region_025 = nil
gg_rct_Region_026 = nil
gg_rct_Region_027 = nil
gg_rct_Region_028 = nil
gg_rct_Region_029 = nil
gg_rct_Region_030 = nil
gg_rct_Region_031 = nil
gg_rct_Region_032 = nil
gg_rct_Region_033 = nil
gg_rct_Region_034 = nil
gg_rct_Region_035 = nil
gg_rct_Region_036 = nil
gg_rct_Region_037 = nil
gg_rct_Region_038 = nil
gg_rct_Region_039 = nil
gg_rct_Region_040 = nil
gg_rct_Region_041 = nil
gg_rct_City_01 = nil
gg_rct_City_02 = nil
gg_rct_OuterVilage_01 = nil
gg_rct_CityRes01 = nil
gg_rct_CityRes02 = nil
gg_rct_CityRes03 = nil
gg_rct_CityRes04 = nil
gg_rct_CityRes05 = nil
gg_rct_CityRes06 = nil
gg_rct_CityRes07 = nil
gg_rct_CityRes08 = nil
gg_rct_CityRes09 = nil
gg_rct_VIllageRes01 = nil
gg_rct_VIllageRes02 = nil
gg_rct_VIllageRes03 = nil
gg_trg_Melee_Initialization = nil
gg_trg_Action_Test = nil
gg_trg_Send_Home = nil
gg_trg_Gather_Units = nil
gg_trg_Hook_Hide = nil
gg_trg_Hook_Flee = nil
gg_trg_Hook_Move = nil
gg_trg_Hook_Relax = nil
gg_trg_Hook_Wait = nil
gg_trg_Hook_Return = nil
gg_trg_Hook_ReturnHome = nil
function InitGlobals()
    udg_townVillageHostile = CreateForce()
    udg_AI_TriggeringRoute = ""
    udg_AI_TriggeringStep = 0
    udg_AI_TriggeringAction = 0
    udg_AI_TriggeringState = ""
    udg_AI_TriggeringId = 0
    udg_townCityHostile = CreateForce()
end

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

	---Goes to either the Units next Step, Action or Ends the route  (Use this in GUI 9912f the time)
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


---This contains all of the generic functions that can be used.  A lot of it is to make handlefree versions of normal blizzard commands 
---Returns true if the value is found in the table. Author: KickKing
---@param table table
---@param element any
---@return boolean @true if found, false if not
function TableContains(table, element)
	for _, value in pairs(table) do if value == element then return true end end
	return false
end

---Remove a value from a table
---@param table table
---@param value any
---@return boolean @true if successful
function TableRemoveValue(table, value) return table.remove(table, TableFind(table, value)) end

---Find the index of a value in a table.
---@param tab table
---@param el any
---@return number @Returns the index
function TableFind(tab, el) for index, value in pairs(tab) do if value == el then return index end end end

---Get the distance between 2 sets of Coordinates (Not handles used)
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function DistanceBetweenCoordinates(x1, y1, x2, y2) return SquareRoot(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1))) end

-- **Credit** KickKing
-- get distance without locations
---Get Distance between two units.  (Doesn't leak)
---@param unitA any
---@param unitB any
---@return number
function DistanceBetweenUnits(unitA, unitB)
	return DistanceBetweenCoordinates(GetUnitX(unitA), GetUnitY(unitA), GetUnitX(unitB), GetUnitY(unitB))
end

--- get angle between two sets of coordinates without locations
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number @angle between 0 and 360
function AngleBetweenCoordinates(x1, y1, x2, y2) return bj_RADTODEG * Atan2(y2 - y1, x2 - x1) end

---get angle between two units without locations
---@param unitA any @Unit 1
---@param unitB any @Unit 2
---@return number @angle between 0 and 360
function AngleBetweenUnits(unitA, unitB)
	return AngleBetweenCoordinates(GetUnitX(unitA), GetUnitY(unitA), GetUnitX(unitB), GetUnitY(unitB))
end

---Polar projection from point (Doesn't Leak)
---@param x number
---@param y number
---@param dist number
---@param angle number
---@return number @x
---@return number @y
function PolarProjectionCoordinates(x, y, dist, angle)
	local newX = x + dist * Cos(angle * bj_DEGTORAD)
	local newY = y + dist * Sin(angle * bj_DEGTORAD)
	return newX, newY
end

---raps your code in a "Try" loop so you can see errors printed in the log at runtime.  Author: Planetary
---@param func any
---@param name string @Name the same as your function name
function Debugfunc(func, name) -- Turn on runtime logging
	local passed, data = pcall(function()
		func()
		return "func " .. name .. " passed"
	end)
	if not passed then print("|cffff0000[ERROR]|r" .. name, passed, data) end
end

---Converts integer formated types into the 4 digit strings (Opposite of FourCC()) Author: Taysen
---@param num any
---@return any
function CC2Four(num) -- Convert from Handle ID to Four Char
	return string.pack(">I4", num)
end

--- Get a random xy in the specified rect
---@param rect any
---@return any
---@return any
function GetRandomCoordinatesInRect(rect)
	return GetRandomReal(GetRectMinX(rect), GetRectMaxX(rect)), GetRandomReal(GetRectMinY(rect), GetRectMaxY(rect))
end

---Get a random xy in the specified datapoints
---@param xMin number
---@param xMax number
---@param yMin number
---@param yMax number
---@return number
---@return number
function GetRandomCoordinatesInPoints(xMin, xMax, yMin, yMax) return GetRandomReal(xMin, xMax),
                                                                     GetRandomReal(yMin, yMax) end

---Wait until Order ends or until the amount of time specified
---@param unit any @This is the Unit to watch
---@param time any @OPTIONAL | 2 | The max amount of time to wait
---@param order any @OPTIONAL | oid.move | The order the continue to wait until it's no longer what the unit is doing
---@param tick any @OPTIONAL | 0.1 | The amount of time to wait between checks
---@return boolean
function WaitWhileOrder(unit, time, order, tick)

	-- Set Defaults
	time = time or 2
	order = order or oid.move
	tick = tick or 0.1

	-- Set Local Variables
	local i = 1
	local unitOrder = GetUnitCurrentOrder(unit)

	-- Loop
	while unitOrder == oid.move and i < time do
		unitOrder = GetUnitCurrentOrder(unit)
		PolledWait(tick)
		i = i + tick
	end

	return true
end

---A system that allow you to duplicate the functionality of auto-filling in the Object Editor
---@param level             number @How many Levels or iterations to use for this
---@param base              number @The number to start with
---@param previousFactor    number @Multiply the previous level by this value
---@param levelFactor       number @This value exponential adds to itself every level
---@param constant          number @This gets added every level
---@return                  number @The calculated Value
function ValueFactor(level, base, previousFactor, levelFactor, constant)

	local value = base

	if level > 1 then for i = 2, level do value = (value * previousFactor) + (i * levelFactor) + (constant) end end

	return value
end

--- A table of all of the Order ID's that exist in Warcraft 3 Author Nestharus (converted to LUA by KickKing)
oid = {
	OFFSET = 851970,
	absorb = 852529,
	acidbomb = 852662,
	acolyteharvest = 852185,
	AImove = 851988,
	ambush = 852131,
	ancestralspirit = 852490,
	ancestralspirittarget = 852491,
	animatedead = 852217,
	antimagicshell = 852186,
	attack = 851983,
	attackground = 851984,
	attackonce = 851985,
	attributemodskill = 852576,
	auraunholy = 852215,
	auravampiric = 852216,
	autodispel = 852132,
	autodispeloff = 852134,
	autodispelon = 852133,
	autoentangle = 852505,
	autoentangleinstant = 852506,
	autoharvestgold = 852021,
	autoharvestlumber = 852022,
	avatar = 852086,
	avengerform = 852531,
	awaken = 852466,
	banish = 852486,
	barkskin = 852135,
	barkskinoff = 852137,
	barkskinon = 852136,
	battleroar = 852099,
	battlestations = 852099,
	bearform = 852138,
	berserk = 852100,
	blackarrow = 852577,
	blackarrowoff = 852579,
	blackarrowon = 852578,
	blight = 852187,
	blink = 852525,
	blizzard = 852089,
	bloodlust = 852101,
	bloodlustoff = 852103,
	bloodluston = 852102,
	board = 852043,
	breathoffire = 852580,
	breathoffrost = 852560,
	build = 851994,
	burrow = 852533,
	cannibalize = 852188,
	carrionscarabs = 852551,
	carrionscarabsinstant = 852554,
	carrionscarabsoff = 852553,
	carrionscarabson = 852552,
	carrionswarm = 852218,
	chainlightning = 852119,
	channel = 852600,
	charm = 852581,
	chemicalrage = 852663,
	cloudoffog = 852473,
	clusterrockets = 852652,
	coldarrows = 852244,
	coldarrowstarg = 852243,
	controlmagic = 852474,
	corporealform = 852493,
	corrosivebreath = 852140,
	coupleinstant = 852508,
	coupletarget = 852507,
	creepanimatedead = 852246,
	creepdevour = 852247,
	creepheal = 852248,
	creephealoff = 852250,
	creephealon = 852249,
	creepthunderbolt = 852252,
	creepthunderclap = 852253,
	cripple = 852189,
	curse = 852190,
	curseoff = 852192,
	curseon = 852191,
	cyclone = 852144,
	darkconversion = 852228,
	darkportal = 852229,
	darkritual = 852219,
	darksummoning = 852220,
	deathanddecay = 852221,
	deathcoil = 852222,
	deathpact = 852223,
	decouple = 852509,
	defend = 852055,
	detectaoe = 852015,
	detonate = 852145,
	devour = 852104,
	devourmagic = 852536,
	disassociate = 852240,
	disenchant = 852495,
	dismount = 852470,
	dispel = 852057,
	divineshield = 852090,
	doom = 852583,
	drain = 852487,
	dreadlordinferno = 852224,
	dropitem = 852001,
	drunkenhaze = 852585,
	earthquake = 852121,
	eattree = 852146,
	elementalfury = 852586,
	ensnare = 852106,
	ensnareoff = 852108,
	ensnareon = 852107,
	entangle = 852147,
	entangleinstant = 852148,
	entanglingroots = 852171,
	etherealform = 852496,
	evileye = 852105,
	faeriefire = 852149,
	faeriefireoff = 852151,
	faeriefireon = 852150,
	fanofknives = 852526,
	farsight = 852122,
	fingerofdeath = 852230,
	firebolt = 852231,
	flamestrike = 852488,
	flamingarrows = 852174,
	flamingarrowstarg = 852173,
	flamingattack = 852540,
	flamingattacktarg = 852539,
	flare = 852060,
	forceboard = 852044,
	forceofnature = 852176,
	forkedlightning = 852586,
	freezingbreath = 852195,
	frenzy = 852561,
	frenzyoff = 852563,
	frenzyon = 852562,
	frostarmor = 852225,
	frostarmoroff = 852459,
	frostarmoron = 852458,
	frostnova = 852226,
	getitem = 851981,
	gold2lumber = 852233,
	grabtree = 852511,
	harvest = 852018,
	heal = 852063,
	healingspray = 852664,
	healingward = 852109,
	healingwave = 852501,
	healoff = 852065,
	healon = 852064,
	hex = 852502,
	holdposition = 851993,
	holybolt = 852092,
	howlofterror = 852588,
	humanbuild = 851995,
	immolation = 852177,
	impale = 852555,
	incineratearrow = 852670,
	incineratearrowoff = 852672,
	incineratearrowon = 852671,
	inferno = 852232,
	innerfire = 852066,
	innerfireoff = 852068,
	innerfireon = 852067,
	instant = 852200,
	invisibility = 852069,
	itemillusion = 852274,
	lavamonster = 852667,
	lightningshield = 852110,
	load = 852046,
	loadarcher = 852142,
	loadcorpse = 852050,
	loadcorpseinstant = 852053,
	locustswarm = 852556,
	lumber2gold = 852234,
	magicdefense = 852478,
	magicleash = 852480,
	magicundefense = 852479,
	manaburn = 852179,
	manaflareoff = 852513,
	manaflareon = 852512,
	manashieldoff = 852590,
	manashieldon = 852589,
	massteleport = 852093,
	mechanicalcritter = 852564,
	metamorphosis = 852180,
	militia = 852072,
	militiaconvert = 852071,
	militiaoff = 852073,
	militiaunconvert = 852651,
	mindrot = 852565,
	mirrorimage = 852123,
	monsoon = 852591,
	mount = 852469,
	mounthippogryph = 852143,
	move = 851986,
	nagabuild = 852467,
	neutraldetectaoe = 852023,
	neutralinteract = 852566,
	neutralspell = 852630,
	nightelfbuild = 851997,
	orcbuild = 851996,
	parasite = 852601,
	parasiteoff = 852603,
	parasiteon = 852602,
	patrol = 851990,
	phaseshift = 852514,
	phaseshiftinstant = 852517,
	phaseshiftoff = 852516,
	phaseshifton = 852515,
	phoenixfire = 852481,
	phoenixmorph = 852482,
	poisonarrows = 852255,
	poisonarrowstarg = 852254,
	polymorph = 852074,
	possession = 852196,
	preservation = 852568,
	purge = 852111,
	rainofchaos = 852237,
	rainoffire = 852238,
	raisedead = 852197,
	raisedeadoff = 852199,
	raisedeadon = 852198,
	ravenform = 852155,
	recharge = 852157,
	rechargeoff = 852159,
	rechargeon = 852158,
	rejuvination = 852160,
	renew = 852161,
	renewoff = 852163,
	renewon = 852162,
	repair = 852024,
	repairoff = 852026,
	repairon = 852025,
	replenish = 852542,
	replenishlife = 852545,
	replenishlifeoff = 852547,
	replenishlifeon = 852546,
	replenishmana = 852548,
	replenishmanaoff = 852550,
	replenishmanaon = 852549,
	replenishoff = 852544,
	replenishon = 852543,
	request_hero = 852239,
	requestsacrifice = 852201,
	restoration = 852202,
	restorationoff = 852204,
	restorationon = 852203,
	resumebuild = 851999,
	resumeharvesting = 852017,
	resurrection = 852094,
	returnresources = 852020,
	revenge = 852241,
	revive = 852039,
	reveal = 852270,
	roar = 852164,
	robogoblin = 852656,
	root = 852165,
	sacrifice = 852205,
	sanctuary = 852569,
	scout = 852181,
	selfdestruct = 852040,
	selfdestructoff = 852042,
	selfdestructon = 852041,
	sentinel = 852182,
	setrally = 851980,
	shadowsight = 852570,
	shadowstrike = 852527,
	shockwave = 852125,
	silence = 852592,
	sleep = 852227,
	slow = 852075,
	slowoff = 852077,
	slowon = 852076,
	smart = 851971,
	soulburn = 852668,
	soulpreservation = 852242,
	spellshield = 852571,
	spellshieldaoe = 852572,
	spellsteal = 852483,
	spellstealoff = 852485,
	spellstealon = 852484,
	spies = 852235,
	spiritlink = 852499,
	spiritofvengeance = 852528,
	spirittroll = 852573,
	spiritwolf = 852126,
	stampede = 852593,
	standdown = 852113,
	starfall = 852183,
	stasistrap = 852114,
	steal = 852574,
	stomp = 852127,
	stoneform = 852206,
	stop = 851972,
	submerge = 852604,
	summonfactory = 852658,
	summongrizzly = 852594,
	summonphoenix = 852489,
	summonquillbeast = 852595,
	summonwareagle = 852596,
	tankdroppilot = 852079,
	tankloadpilot = 852080,
	tankpilot = 852081,
	taunt = 852520,
	thunderbolt = 852095,
	thunderclap = 852096,
	tornado = 852597,
	townbelloff = 852083,
	townbellon = 852082,
	tranquility = 852184,
	transmute = 852665,
	unavatar = 852087,
	unavengerform = 852532,
	unbearform = 852139,
	unburrow = 852534,
	uncoldarrows = 852245,
	uncorporealform = 852494,
	undeadbuild = 851998,
	undefend = 852056,
	undivineshield = 852091,
	unetherealform = 852497,
	unflamingarrows = 852175,
	unflamingattack = 852541,
	unholyfrenzy = 852209,
	unimmolation = 852178,
	unload = 852047,
	unloadall = 852048,
	unloadallcorpses = 852054,
	unloadallinstant = 852049,
	unpoisonarrows = 852256,
	unravenform = 852156,
	unrobogoblin = 852657,
	unroot = 852166,
	unstableconcoction = 852500,
	unstoneform = 852207,
	unsubmerge = 852605,
	unsummon = 852210,
	unwindwalk = 852130,
	vengeance = 852521,
	vengeanceinstant = 852524,
	vengeanceoff = 852523,
	vengeanceon = 852522,
	volcano = 852669,
	voodoo = 852503,
	ward = 852504,
	waterelemental = 852097,
	wateryminion = 852598,
	web = 852211,
	weboff = 852213,
	webon = 852212,
	whirlwind = 852128,
	windwalk = 852129,
	wispharvest = 852214,
	scrollofspeed = 852285,
	cancel = 851976,
	moveslot1 = 852002,
	moveslot2 = 852003,
	moveslot3 = 852004,
	moveslot4 = 852005,
	moveslot5 = 852006,
	moveslot6 = 852007,
	useslot1 = 852008,
	useslot2 = 852009,
	useslot3 = 852010,
	useslot4 = 852011,
	useslot5 = 852012,
	useslot6 = 852013,
	skillmenu = 852000,
	stunned = 851973,
	instant1 = 851991,
	instant2 = 851987,
	instant3 = 851975,
	instant4 = 852019
}


function Config()

	Debugfunc(function()

		-- Add Towns
		-- Set up the town, set activity probabiliy per tick and the AI tick Multipler (3 percent chance to start moving, 1x)
		ai.town.New("city", 3)
		ai.town.Extend("city", gg_rct_City_01)
		ai.town.Extend("city", gg_rct_City_02)
		ai.town.HostileForce("city", udg_townCityHostile)

		-- Outer Village Town
		ai.town.New("village", 3)
		ai.town.Extend("village", gg_rct_OuterVilage_01)
		ai.town.HostileForce("village", udg_townCityHostile)

		-- Set up Safehouses
		-- City Safehouses
		ai.landmark.New("city", "city01", gg_rct_CityRes01, {"safehouse","residence"}, nil, 3)
		ai.landmark.New("city", "city02", gg_rct_CityRes02, {"safehouse","residence"}, nil, 3)
		ai.landmark.New("city", "city03", gg_rct_CityRes03, {"safehouse","residence"}, nil, 3)
		ai.landmark.New("city", "city04", gg_rct_CityRes04, {"safehouse","residence"}, nil, 2)
		ai.landmark.New("city", "city05", gg_rct_CityRes05, {"safehouse","residence"}, nil, 2)
		ai.landmark.New("city", "city06", gg_rct_CityRes06, {"safehouse","residence"}, nil, 2)
		ai.landmark.New("city", "city07", gg_rct_CityRes07, {"safehouse","residence"}, nil, 2)
		ai.landmark.New("city", "city08", gg_rct_CityRes08, {"safehouse","residence"}, nil, 2)
		ai.landmark.New("city", "city09", gg_rct_CityRes09, {"safehouse","residence"}, nil, 2)

		-- Village Safehouses
		ai.landmark.New("village", "village01", gg_rct_VIllageRes01, {"safehouse"}, nil, 2)
		ai.landmark.New("village", "village02", gg_rct_VIllageRes02, {"safehouse"}, nil, 2)
		ai.landmark.New("village", "village03", gg_rct_VIllageRes03, {"safehouse"}, nil, 2)

		-- CounterClockwise Route (Listed as a looping route,
		-- meaning units will start at the step closest to their
		-- location and then finish on that same step by looping
		-- through all of the steps)
		ai.route.New("city_01", true)
		ai.route.Step(gg_rct_Region_000, 100)
		ai.route.Step(gg_rct_Region_001, 100)
		ai.route.Step(gg_rct_Region_002, 100)
		ai.route.Step(gg_rct_Region_003, 100)
		ai.route.Step(gg_rct_Region_004, 100)
		ai.route.Step(gg_rct_Region_005, 100)
		ai.route.Step(gg_rct_Region_006, 100)
		ai.route.Step(gg_rct_Region_007, 100)
		ai.route.Step(gg_rct_Region_008, 100)
		ai.route.Step(gg_rct_Region_014, 100, "random")

		-- Unit will pause for 25 seconds and look at a region
		ai.route.Action(25, gg_rct_Region_028)

		-- After that, it will run this trigger for the unit
		ai.route.Trigger(gg_trg_Action_Test)

		ai.route.Step(gg_rct_Region_008, 100)
		ai.route.Step(gg_rct_Region_009, 100)
		ai.route.Step(gg_rct_Region_010, 100, "random")

		-- Unit will pause for 5 seconds
		ai.route.Action(10)
		ai.route.Trigger(gg_trg_Action_Test)
		ai.route.Step(gg_rct_Region_011, 100, "random")
		ai.route.Action(15)
		ai.route.Step(gg_rct_Region_012, 100, "random")
		ai.route.Action(15)
		ai.route.Step(gg_rct_Region_009, 100)
		ai.route.Step(gg_rct_Region_013, 100, "random")
		ai.route.Action(9)
		ai.route.Step(gg_rct_Region_009, 100)

		-- What to do at the end of the unit's route (Speed to have them go to their home position at)
		ai.route.Finish(100)

		--
		-- Clockwise Route
		ai.route.New("city_02", true)
		ai.route.Step(gg_rct_Region_040, 100)
		ai.route.Step(gg_rct_Region_039, 100)
		ai.route.Step(gg_rct_Region_038, 100)
		ai.route.Step(gg_rct_Region_037, 100, "random")
		ai.route.Action(7)
		ai.route.Trigger(gg_trg_Action_Test)
		ai.route.Step(gg_rct_Region_036, 100)
		ai.route.Step(gg_rct_Region_035, 100)
		ai.route.Step(gg_rct_Region_034, 100)
		ai.route.Step(gg_rct_Region_033, 100)
		ai.route.Step(gg_rct_Region_032, 100)
		ai.route.Step(gg_rct_Region_031, 100)
		ai.route.Step(gg_rct_Region_030, 100)
		ai.route.Step(gg_rct_Region_029, 100)
		ai.route.Step(gg_rct_Region_014, 100, "random")

		-- Unit will pause for 25 seconds and look at a region
		ai.route.Action(25, gg_rct_Region_028)

		-- After that, it will run this trigger for the unit
		ai.route.Trigger(gg_trg_Action_Test)
		ai.route.Step(gg_rct_Region_029, 100)
		ai.route.Finish(100)

		--
		-- Go To the other Town
		ai.route.New("Out", true)
		ai.route.Step(gg_rct_Region_019, 100)
		ai.route.Step(gg_rct_Region_020, 100)
		ai.route.Step(gg_rct_Region_021, 100)
		ai.route.Step(gg_rct_Region_022, 100)
		ai.route.Step(gg_rct_Region_023, 100)
		ai.route.Step(gg_rct_Region_041, 100)
		ai.route.Step(gg_rct_Region_024, 100)
		ai.route.Step(gg_rct_Region_026, 100)
		ai.route.Step(gg_rct_Region_025, 100)
		ai.route.Step(gg_rct_Region_019, 100)
		ai.route.Finish(100)

		-- Gather Units Together
		ai.route.New("gather", false)
		ai.route.Step(gg_rct_Region_014, 100, "random")
		ai.route.Action(90, gg_rct_Region_028)
		ai.route.Finish(100)

		--
		-- Add all units on the map to AI
		local g = CreateGroup()
		local g2 = CreateGroup()

		-- Find all units in the city
		g = GetUnitsInRectOfPlayer(gg_rct_City_01, Player(1))
		g2 = GetUnitsInRectOfPlayer(gg_rct_City_02, Player(1))
		GroupAddGroup(g2, g)
		DestroyGroup(g2)

		-- Loop through the units
		local u = FirstOfGroup(g)
		while u ~= nil do

			-- Add Unit (Will rename unit to the unit name specified)
			ai.unit.New("city", "villager", u, GetUnitName(u), "day")
			-- Add the routes that this unit has available to it when in the relax state
			ai.unit.AddRoute(u, "city_01")
			ai.unit.AddRoute(u, "city_02")
			-- ai.unit.AddRoute(u, "Out")

			GroupRemoveUnit(g, u)
			u = FirstOfGroup(g)
		end
		DestroyGroup(g)

		-- Get All units in the Village
		g = GetUnitsInRectOfPlayer(gg_rct_OuterVilage_01, Player(1))

		-- Loop through the units
		u = FirstOfGroup(g)
		while u ~= nil do

			-- Add Unit (Will rename unit to the unit name specified)
			ai.unit.New("village", "villager", u, GetUnitName(u), "day")

			-- Add the routes that this unit has available to it when in the relax state
			ai.unit.AddRoute(u, "Out")

			GroupRemoveUnit(g, u)
			u = FirstOfGroup(g)
		end
		DestroyGroup(g)

	end, "Setup")
end


function CreateUnitsForPlayer0()
    local p = Player(0)
    local u
    local unitID
    local t
    local life
    u = BlzCreateUnitWithSkin(p, FourCC("hfoo"), 1693.6, -2045.2, 301.507, FourCC("hfoo"))
end

function CreateUnitsForPlayer1()
    local p = Player(1)
    local u
    local unitID
    local t
    local life
    u = BlzCreateUnitWithSkin(p, FourCC("nvk2"), -1753.0, -2883.9, 184.851, FourCC("nvk2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvk2"), 1218.9, -154.0, 39.167, FourCC("nvk2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvk2"), 1781.5, -62.3, 279.050, FourCC("nvk2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 739.2, 1194.3, 150.737, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 400.7, 1227.9, 170.601, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), 1122.7, 701.0, 128.236, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), -278.5, 926.8, 350.090, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), -711.1, 1183.0, 290.707, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), 1712.0, 444.8, 184.444, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvil"), -339.8, -97.5, 6.185, FourCC("nvil"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvil"), -798.8, 512.6, 317.844, FourCC("nvil"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvil"), -1082.9, -124.7, 289.466, FourCC("nvil"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvil"), -2134.9, -2651.2, 174.611, FourCC("nvil"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), -821.2, -873.5, 176.764, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), -1615.0, -342.6, 282.994, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), -1239.8, 295.7, 163.460, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), -1372.7, 172.2, 196.507, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), -829.8, 855.3, 275.436, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), -439.1, 1740.9, 237.169, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 265.6, 1671.2, 37.805, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 568.5, 1499.4, 194.640, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), -2506.9, -2766.9, 21.325, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 384.0, -721.4, 249.628, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 1417.1, -655.0, 193.288, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("hpea"), -2005.1, -2731.9, 272.392, FourCC("hpea"))
    u = BlzCreateUnitWithSkin(p, FourCC("hpea"), -2206.8, -3172.9, 71.534, FourCC("hpea"))
end

function CreatePlayerBuildings()
end

function CreatePlayerUnits()
    CreateUnitsForPlayer0()
    CreateUnitsForPlayer1()
end

function CreateAllUnits()
    CreatePlayerBuildings()
    CreatePlayerUnits()
end

function CreateRegions()
    local we
    gg_rct_Region_000 = Rect(192.0, -768.0, 448.0, -512.0)
    gg_rct_Region_001 = Rect(1216.0, -832.0, 1440.0, -576.0)
    gg_rct_Region_002 = Rect(1440.0, -256.0, 1664.0, -64.0)
    gg_rct_Region_003 = Rect(1664.0, 320.0, 1856.0, 512.0)
    gg_rct_Region_004 = Rect(1504.0, 864.0, 1728.0, 1088.0)
    gg_rct_Region_005 = Rect(864.0, 928.0, 1152.0, 1184.0)
    gg_rct_Region_006 = Rect(320.0, 1440.0, 576.0, 1632.0)
    gg_rct_Region_007 = Rect(-160.0, 1440.0, 32.0, 1632.0)
    gg_rct_Region_008 = Rect(-832.0, 736.0, -544.0, 1024.0)
    gg_rct_Region_009 = Rect(-1056.0, -32.0, -768.0, 224.0)
    gg_rct_Region_010 = Rect(-1184.0, -832.0, -896.0, -576.0)
    gg_rct_Region_011 = Rect(-1568.0, -512.0, -1312.0, -256.0)
    gg_rct_Region_012 = Rect(-1472.0, -832.0, -1216.0, -544.0)
    gg_rct_Region_013 = Rect(-1408.0, 64.0, -1088.0, 384.0)
    gg_rct_Region_014 = Rect(-32.0, 96.0, 448.0, 640.0)
    gg_rct_Region_015 = Rect(1088.0, -1504.0, 1280.0, -1344.0)
    gg_rct_Region_016 = Rect(1280.0, -2912.0, 1504.0, -2688.0)
    gg_rct_Region_017 = Rect(928.0, -3296.0, 1152.0, -3072.0)
    gg_rct_Region_018 = Rect(96.0, -3424.0, 288.0, -3264.0)
    gg_rct_Region_019 = Rect(-608.0, -3264.0, -416.0, -3072.0)
    gg_rct_Region_020 = Rect(-1792.0, -3072.0, -1600.0, -2912.0)
    gg_rct_Region_021 = Rect(-2208.0, -2848.0, -2016.0, -2624.0)
    gg_rct_Region_022 = Rect(-2560.0, -2848.0, -2304.0, -2592.0)
    gg_rct_Region_023 = Rect(-2400.0, -3232.0, -2176.0, -3008.0)
    gg_rct_Region_024 = Rect(-1216.0, -2592.0, -1056.0, -2368.0)
    gg_rct_Region_025 = Rect(-928.0, -2272.0, -736.0, -2048.0)
    gg_rct_Region_026 = Rect(-1440.0, -2240.0, -1280.0, -2048.0)
    gg_rct_Region_027 = Rect(-1376.0, -2816.0, -1216.0, -2592.0)
    gg_rct_Region_028 = Rect(320.0, 480.0, 576.0, 704.0)
    gg_rct_Region_029 = Rect(192.0, -512.0, 416.0, -320.0)
    gg_rct_Region_030 = Rect(992.0, -736.0, 1248.0, -512.0)
    gg_rct_Region_031 = Rect(1344.0, -160.0, 1568.0, 96.0)
    gg_rct_Region_032 = Rect(1568.0, 320.0, 1792.0, 576.0)
    gg_rct_Region_033 = Rect(1408.0, 736.0, 1632.0, 992.0)
    gg_rct_Region_034 = Rect(736.0, 800.0, 1024.0, 1056.0)
    gg_rct_Region_035 = Rect(192.0, 1312.0, 480.0, 1568.0)
    gg_rct_Region_036 = Rect(-160.0, 1280.0, 64.0, 1504.0)
    gg_rct_Region_037 = Rect(-640.0, 1536.0, -352.0, 1792.0)
    gg_rct_Region_038 = Rect(-608.0, 1120.0, -352.0, 1344.0)
    gg_rct_Region_039 = Rect(-576.0, 576.0, -288.0, 800.0)
    gg_rct_Region_040 = Rect(-768.0, -128.0, -576.0, 96.0)
    gg_rct_Region_041 = Rect(-1408.0, -3200.0, -1184.0, -2976.0)
    gg_rct_City_01 = Rect(-1568.0, -1120.0, 2368.0, 2432.0)
    gg_rct_City_02 = Rect(-2688.0, -1696.0, 768.0, 832.0)
    gg_rct_OuterVilage_01 = Rect(-2976.0, -3648.0, -352.0, -1824.0)
    gg_rct_CityRes01 = Rect(-608.0, -480.0, -416.0, -320.0)
    gg_rct_CityRes02 = Rect(1376.0, -672.0, 1568.0, -512.0)
    gg_rct_CityRes03 = Rect(-256.0, 832.0, -64.0, 992.0)
    gg_rct_CityRes04 = Rect(-1056.0, 416.0, -864.0, 576.0)
    gg_rct_CityRes05 = Rect(1408.0, 608.0, 1600.0, 768.0)
    gg_rct_CityRes06 = Rect(384.0, -32.0, 576.0, 128.0)
    gg_rct_CityRes07 = Rect(-1408.0, 320.0, -1216.0, 480.0)
    gg_rct_CityRes08 = Rect(-1504.0, 64.0, -1312.0, 224.0)
    gg_rct_CityRes09 = Rect(-768.0, 1440.0, -576.0, 1600.0)
    gg_rct_VIllageRes01 = Rect(-2592.0, -2688.0, -2400.0, -2528.0)
    gg_rct_VIllageRes02 = Rect(-2400.0, -3264.0, -2208.0, -3104.0)
    gg_rct_VIllageRes03 = Rect(-2080.0, -2784.0, -1888.0, -2624.0)
end

function Trig_Melee_Initialization_Actions()
    MeleeStartingVisibility()
    FogEnableOff()
    FogMaskEnableOff()
    ForceAddPlayerSimple(Player(0), udg_townCityHostile)
        ai.Init(2, 7)
        Config()
        ai.Start()
end

function InitTrig_Melee_Initialization()
    gg_trg_Melee_Initialization = CreateTrigger()
    TriggerAddAction(gg_trg_Melee_Initialization, Trig_Melee_Initialization_Actions)
end

function Trig_Hook_Hide_Actions()
end

function InitTrig_Hook_Hide()
    gg_trg_Hook_Hide = CreateTrigger()
    TriggerAddAction(gg_trg_Hook_Hide, Trig_Hook_Hide_Actions)
end

function Trig_Hook_Flee_Actions()
end

function InitTrig_Hook_Flee()
    gg_trg_Hook_Flee = CreateTrigger()
    TriggerAddAction(gg_trg_Hook_Flee, Trig_Hook_Flee_Actions)
end

function Trig_Hook_Move_Actions()
end

function InitTrig_Hook_Move()
    gg_trg_Hook_Move = CreateTrigger()
    TriggerAddAction(gg_trg_Hook_Move, Trig_Hook_Move_Actions)
end

function Trig_Hook_Relax_Actions()
end

function InitTrig_Hook_Relax()
    gg_trg_Hook_Relax = CreateTrigger()
    TriggerAddAction(gg_trg_Hook_Relax, Trig_Hook_Relax_Actions)
end

function Trig_Hook_Wait_Actions()
end

function InitTrig_Hook_Wait()
    gg_trg_Hook_Wait = CreateTrigger()
    TriggerAddAction(gg_trg_Hook_Wait, Trig_Hook_Wait_Actions)
end

function Trig_Hook_Return_Actions()
end

function InitTrig_Hook_Return()
    gg_trg_Hook_Return = CreateTrigger()
    TriggerAddAction(gg_trg_Hook_Return, Trig_Hook_Return_Actions)
end

function Trig_Hook_ReturnHome_Actions()
end

function InitTrig_Hook_ReturnHome()
    gg_trg_Hook_ReturnHome = CreateTrigger()
    TriggerAddAction(gg_trg_Hook_ReturnHome, Trig_Hook_ReturnHome_Actions)
end

function Trig_Action_Test_Actions()
        local id = udg_AI_TriggeringId
    DisplayTextToForce(GetPlayersAll(), GetUnitName(udg_AI_TriggeringUnit))
    SetUnitLifePercentBJ(udg_AI_TriggeringUnit, 50.00)
    AddSpecialEffectTargetUnitBJ("overhead", udg_AI_TriggeringUnit, "Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl")
    DestroyEffectBJ(GetLastCreatedEffectBJ())
    TriggerSleepAction(2)
        ai.unit[id].stateCurrent = "TriggerFinished"
end

function InitTrig_Action_Test()
    gg_trg_Action_Test = CreateTrigger()
    TriggerAddAction(gg_trg_Action_Test, Trig_Action_Test_Actions)
end

function Trig_Send_Home_Actions()
        ai.town.UnitsSetState("city", "ReturnHome")
end

function InitTrig_Send_Home()
    gg_trg_Send_Home = CreateTrigger()
    TriggerRegisterPlayerChatEvent(gg_trg_Send_Home, Player(0), "-home", true)
    TriggerAddAction(gg_trg_Send_Home, Trig_Send_Home_Actions)
end

function Trig_Gather_Units_Actions()
        ai.town.UnitsSetRoute("city", "gather")
end

function InitTrig_Gather_Units()
    gg_trg_Gather_Units = CreateTrigger()
    TriggerRegisterPlayerChatEvent(gg_trg_Gather_Units, Player(0), "-gather", true)
    TriggerAddAction(gg_trg_Gather_Units, Trig_Gather_Units_Actions)
end

function InitCustomTriggers()
    InitTrig_Melee_Initialization()
    InitTrig_Hook_Hide()
    InitTrig_Hook_Flee()
    InitTrig_Hook_Move()
    InitTrig_Hook_Relax()
    InitTrig_Hook_Wait()
    InitTrig_Hook_Return()
    InitTrig_Hook_ReturnHome()
    InitTrig_Action_Test()
    InitTrig_Send_Home()
    InitTrig_Gather_Units()
end

function RunInitializationTriggers()
    ConditionalTriggerExecute(gg_trg_Melee_Initialization)
end

function InitCustomPlayerSlots()
    SetPlayerStartLocation(Player(0), 0)
    SetPlayerColor(Player(0), ConvertPlayerColor(0))
    SetPlayerRacePreference(Player(0), RACE_PREF_HUMAN)
    SetPlayerRaceSelectable(Player(0), true)
    SetPlayerController(Player(0), MAP_CONTROL_USER)
end

function InitCustomTeams()
    SetPlayerTeam(Player(0), 0)
end

function main()
    SetCameraBounds(-3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), -3328.0 + GetCameraMargin(CAMERA_MARGIN_LEFT), 3072.0 - GetCameraMargin(CAMERA_MARGIN_TOP), 3328.0 - GetCameraMargin(CAMERA_MARGIN_RIGHT), -3584.0 + GetCameraMargin(CAMERA_MARGIN_BOTTOM))
    SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl")
    NewSoundEnvironment("Default")
    SetAmbientDaySound("LordaeronSummerDay")
    SetAmbientNightSound("LordaeronSummerNight")
    SetMapMusic("Music", true, 0)
    CreateRegions()
    CreateAllUnits()
    InitBlizzard()
    InitGlobals()
    InitCustomTriggers()
    RunInitializationTriggers()
end

function config()
    SetMapName("TRIGSTR_001")
    SetMapDescription("TRIGSTR_003")
    SetPlayers(1)
    SetTeams(1)
    SetGamePlacement(MAP_PLACEMENT_USE_MAP_SETTINGS)
    DefineStartLocation(0, 1408.0, -1728.0)
    InitCustomPlayerSlots()
    SetPlayerSlotAvailable(Player(0), MAP_CONTROL_USER)
    InitGenericPlayerSlots()
end

