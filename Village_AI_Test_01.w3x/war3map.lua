udg_townVillageForce = nil
udg_AI_TriggeringUnit = nil
udg_AI_TriggeringRegion = nil
udg_AI_TriggeringRoute = ""
udg_AI_TriggeringStep = 0
udg_AI_TriggeringAction = 0
udg_AI_TriggeringState = ""
udg_AI_TriggeringId = 0
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
gg_trg_Melee_Initialization = nil
gg_trg_Action_Test = nil
gg_trg_Gather_Units = nil
gg_trg_Send_Home = nil
function InitGlobals()
    udg_townVillageForce = CreateForce()
    udg_AI_TriggeringRoute = ""
    udg_AI_TriggeringStep = 0
    udg_AI_TriggeringAction = 0
    udg_AI_TriggeringState = ""
    udg_AI_TriggeringId = 0
end

---@diagnostic disable: lowercase-global
--------------
-- Village AI
-- Credit: Mark Wright (KickKing)
-- v0.1.0
--------------
--
--
--
--
---Init Village AI
---@param overallTick number
---@param overallSplit number
function INIT_AI(overallTick, overallSplit)

    -- Set Overall Tick if a value isn't specified
    overallTick = overallTick or 2
    overallSplit = overallSplit or 5

    -- Set up Table
    ai = {
        town = {},
        townNames = {},
        unit = {},
        landmark = {},
        landmarkNames = {},
        route = {rects = {}},
        trig = {},
        unitSTATE = {},
        townSTATE = {},
        region = {},
        landmarkSTATE = {},
        tick = overallTick,
        split = overallSplit,
        unitGroup = CreateGroup()
    }

    --------
    --  LANDMARK ACTIONS
    --------

    ---Add a new landmark
    ---@param town string
    ---@param name string
    ---@param rect table
    ---@param types table
    ---@param unit table
    ---@param radius number
    ---@param maxCapacity number
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
        for i = 1, #ai.landmark[name].types do
            ai.town[town][ai.landmark[name].type[i]] = name
        end

    end

    --------
    --  TOWN ACTIONS
    --------

    ---Adds a new town to the map.  (NEEDS to be extended with additional RECTs)
    ---@param name string
    ---@param activityProbability number
    ---@param tickMultiplier number
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
            states = {
                "Auto", "Normal", "Danger", "Pause", "Paused", "Abadon",
                "Gather"
            },

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

    function ai.town.Extend(name, rect)
        RegionAddRect(ai.town[name].region, rect)

        return true
    end

    function ai.town.State(town, state)

        if TableContains(ai.town[town].states, state) then
            ai.town[town].state = state
            ai.town[town].stateCurrent = state

            ai.townSTATE[state](town)

            return true
        end

        return false
    end

    function ai.town.HostileForce(town, force)

        ai.town[town].force = force
        return true

    end

    function ai.town.VulnerableUnits(town, flag)

        ForGroup(ai.town[town].units, function()
            local unit = GetEnumUnit()

            SetUnitInvulnerable(unit, flag)
        end)

        return true

    end

    function ai.town.UnitsSetRoute(town, route)
        ForGroup(ai.town[town].units, function()
            local unit = GetEnumUnit()

            print("Gather")
            Debugfunc(function()
                ai.unit.PickRoute(unit, route)
                ai.unit.MoveToNextStep(unit, true)
            end, "Gather")
            print("Gathering")
        end)
    end

    function ai.town.UnitsSetState(town, state)
        ForGroup(ai.town[town].units, function()
            local unit = GetEnumUnit()

            ai.unit.State(unit, state)
        end)
    end

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

    function ai.town.UnitsSetLife(town, low, high)

        ForGroup(ai.town[town].units, function()
            local unit = GetEnumUnit()
            local percentLife = GetRandomInt(low, high)

            SetUnitLifePercentBJ(unit, percentLife)
        end)

        return true
    end

    --------
    --  REGION ACTIONS
    --------

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
            TriggerRegisterEnterRegionSimple(ai.trig.UnitEntersRegion,
                                             ai.region[id].region)
        end

    end

    function ai.region.GetRandom(id)
        local data = ai.region[id]

        return GetRandomReal(data.xMin, data.xMax),
               GetRandomReal(data.yMin, data.yMax)
    end

    function ai.region.GetCenter(id) return ai.region[id].x, ai.region[id].y end

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

    --------
    --  ROUTE ACTIONS
    --------

    ---Adds a route that villagers can take when Moving
    ---@param name  string  @Route Name
    ---@param loop  boolean @Whether or not the route is a loop
    ---@param type  string  @inTown or outOfTown
    ---@return      boolean @True if successful
    function ai.route.New(name, loop, type)

        ai.routeSetup = name
        -- Set up the route Vars
        ai.route[name] = {
            name = name,
            type = type,
            step = {},
            stepCount = 0,
            endSpeed = nil,
            loop = loop
        }

        return true
    end

    ---Adds at the end of the selected route, a new place for a unit to move to.
    ---@param rect          rect    @The Rect (GUI Region) that the unit will walk to
    ---@param speed         number  @OPTIONAL: Walk/Run speed of unit.  (under 100 will walk) Default is unit default speed
    ---@param point         string  @OPTIONAL: [center, random] Picks either the center of the Rect or a random point in the rect. (Default Center)
    ---@param order         number  @OPTIONAL: the order to use to move.  Default of move
    ---@param animationTag  string  @OPTIONAL: an anim tag to add to the unit while walking
    ---@return              boolean @True if successful
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

        ai.route[route].step[stepCount] =
            {
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

    ---Adds an additional action to the picked route step
    ---@param time number
    ---@param lookAtRect rect
    ---@param animation string
    ---@param loop boolean
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
        ai.route[route].step[stepCount].action[actionCount] =
            {
                type = "action",
                time = time,
                lookAtRect = lookAtRect,
                animation = animation,
                loop = loop
            }

        return true

    end

    function ai.route.Trigger(trigger)
        -- Update the action Count for the Route
        local route = ai.routeSetup
        local stepCount = ai.route.StepCount(route)
        local actionCount = ai.route.ActionCount(route, stepCount) + 1

        -- Add the action to the Step in the Route
        ai.route[route].step[stepCount].actionCount = actionCount
        ai.route[route].step[stepCount].action[actionCount] =
            {type = "trigger", trigger = trigger}
    end

    function ai.route.Funct(funct)
        -- Update the action Count for the Route
        local route = ai.routeSetup
        local stepCount = ai.route.StepCount(route)
        local actionCount = ai.route.ActionCount(route, stepCount) + 1

        -- Add the action to the Step in the Route
        ai.route[route].step[stepCount].actionCount = actionCount
        ai.route[route].step[stepCount].action[actionCount] =
            {type = "function", funct = funct}

        return true
    end

    function ai.route.Finish(speed)
        speed = speed or nil

        ai.route[ai.routeSetup].endSpeed = speed

        return true
    end

    function ai.route.StepCount(route) return ai.route[route].stepCount end

    function ai.route.ActionCount(route, step)
        return ai.route[route].step[step].actionCount
    end

    --------
    --  UNIT ACTIONS
    --------

    -- Adds a unit that exists into the fold to be controlled by the AI. Defaults to Day shift.
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
            ai.unit[handleId].states = {
                "Relax", "Move", "Sleep", "ReturnHome", "Moving",
                "ReturningHome", "Waiting"
            }
            ai.unit[handleId].stateCurrent = "Relax"

        end

        return true
    end

    function ai.unit.AddRoute(unit, route)
        local handleId = GetHandleId(unit)

        if ai.route[route] ~= nil then
            table.insert(ai.unit[handleId].routes, route)
            return true
        end

        return false

    end

    function ai.unit.RemoveRoute(unit, route)
        local handleId = GetHandleId(unit)
        local routes = ai.unit[handleId].routes

        if TableContains(routes, route) then
            ai.unit[handleId].routes = TableRemoveValue(routes, route)
            return true
        end

        return false
    end

    --- Kill the Unit
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
    ---@param flag boolean @If true the unit will pause, if false the unit will unpause
    function ai.unit.Pause(unit, flag)
        local handleId = GetHandleId(unit)

        PauseUnit(unit, flag)
        ai.unit[handleId].paused = flag

        return true
    end

    --- Pick a Route from the Units avalable routes and set it up
    ---@param unit any @REQUIRED The Unit in the AI system
    ---@param route string @OPTIONAL if you want a specific route chosen else it will pick one
    ---@param stepNumber integer @OPTIONAL if you want a specific Step chosen else it will start at the beginning
    ---@param actionNumber integer @OPTIONAL if you want a specific Action chosen else it will start at the beginning
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
                    regionX, regionY = ai.region.GetCenter(
                                           routeData.step[i].regionId)

                    newDistance = DistanceBetweenCoordinates(x, y, regionX,
                                                             regionY)

                    if distance > newDistance and
                        not ai.region.ContainsUnit(routeData.step[i].regionId,
                                                   unit) then
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
            ai.unit[data.id].xDest, ai.unit[data.id].yDest =
                ai.region.GetRandom(step.regionId)
        else
            ai.unit[data.id].xDest, ai.unit[data.id].yDest =
                ai.region.GetCenter(step.regionId)
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
        IssuePointOrderById(unit, step.order, ai.unit[data.id].xDest,
                            ai.unit[data.id].yDest)

        return true
    end

    --- Run the units next Route Action
    function ai.unit.NextAction(unit)
        local data = ai.unit[GetHandleId(unit)]

        -- Get Default Variable
        local tick = 0.1

        local stepNumber = data.stepNumber
        local actionNumber = data.actionNumber + 1

        -- If There doesn't exist the current step cancel
        if stepNumber == nil then return end
        if stepNumber > ai.route[data.route].stepCount or stepNumber == 0 then
            return false
        end

        -- If there are no more actions, return
        if actionNumber > ai.route[data.route].step[stepNumber].actionCount then
            return false
        end

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
                    local facingAngle = AngleBetweenCoordinates(x, y,
                                                                GetRectCenterX(
                                                                    action.lookAtRect),
                                                                GetRectCenterY(
                                                                    action.lookAtRect))

                    -- Get Position 10 units away in the correct direction
                    local xNew, yNew = PolarProjectionCoordinates(x, y, 10,
                                                                  facingAngle)

                    -- Move unit to direction
                    IssuePointOrderById(unit, oid.move, xNew, yNew)

                    -- Wait for unit to stop Moving or 2 seconds
                    WaitWhileOrder(unit, 4)
                end

                if action.animation ~= nil then
                    SetUnitAnimation(unit, action.animation)

                    -- Loop Animation if checked
                    if action.loop then
                        for i = 1, math.floor(action.time) do
                            QueueUnitAnimation(unit, action.animation)
                        end
                    end

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

                while ai.unit[data.id].stateCurrent == "Waiting" do
                    PolledWait(.5)
                end

                ai.unit[data.id].stateCurrent = "Moving"
            end
        end

        return true
    end

    --- Set the Unit State
    function ai.unit.State(unit, state)
        local data = ai.unit[GetHandleId(unit)]

        if TableContains(ai.unit[data.id].states, state) then
            ai.unit[data.id].state = state

            ai.unitSTATE[state](unit)

            return true
        end

        return false
    end

    --- Update the Units intel
    function ai.unit.Intel(unit)

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

    function ai.unit.Post(unit)
        local data = ai.unit[GetHandleId(unit)]

        ai.unit[data.id].orderLast = GetUnitCurrentOrder(unit)
        return true

    end

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
            if ai.unit[data.id].looped and ai.unit[data.id].stepNumber >
                data.stepNumberStart then

                local speed = ai.route[data.route].endSpeed or data.speedDefault

                if speed < 100 then
                    BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED,
                                          100.00)
                    AddUnitAnimationPropertiesBJ(true, "cinematic", unit)
                    ai.unit[data.id].walk = true
                else
                    BlzSetUnitRealFieldBJ(unit, UNIT_RF_ANIMATION_WALK_SPEED,
                                          270.00)
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

                        local speed = ai.route[data.route].endSpeed or
                                          data.speedDefault

                        if speed < 100 then
                            BlzSetUnitRealFieldBJ(unit,
                                                  UNIT_RF_ANIMATION_WALK_SPEED,
                                                  100.00)
                            AddUnitAnimationPropertiesBJ(true, "cinematic", unit)
                            ai.unit[data.id].walk = true
                        else
                            BlzSetUnitRealFieldBJ(unit,
                                                  UNIT_RF_ANIMATION_WALK_SPEED,
                                                  270.00)
                            AddUnitAnimationPropertiesBJ(false, "cinematic",
                                                         unit)
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

    --------
    --  UNIT STATES
    --------

    --
    --- MOVE STATE
    function ai.unitSTATE.Move(unit)
        local data = ai.unit[GetHandleId(unit)]

        if #data.routes == 0 and data.route == nil then return false end

        local route = data.routes[GetRandomInt(1, #data.routes)]

        ai.unit.PickRoute(unit)
        ai.unit.MoveToNextStep(unit)

        return true
    end

    --
    --- RELAX STATE
    function ai.unitSTATE.Relax(unit)
        local data = ai.unit[GetHandleId(unit)]

        local prob = GetRandomInt(1, 100)

        if ai.town[data.town].activityProbability >= prob then

            -- Order Unit to Move onto one of it's routes
            if TableContains(data.states, "Move") then
                ai.unit.State(unit, "Move")
            end

        end

    end

    --- RETURN HOME
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

    --------
    --  UNIT STATES TRANSIENT
    --------

    --- Moving State
    function ai.unitSTATE.Moving(unit)
        local data = ai.unit[GetHandleId(unit)]

        if GetUnitCurrentOrder(unit) ~= oid.move and data.orderLast ~= oid.Move then
            ai.unit.MoveToNextStep(unit)
        end

        return true
    end

    --- Waiting State
    function ai.unitSTATE.Waiting(unit)

        -- Do nothing, come on now, what did you think was going to be here??
        return true
    end

    --- Returning Home State
    function ai.unitSTATE.ReturningHome(unit)
        local data = ai.unit[GetHandleId(unit)]

        local x = GetUnitX(unit)
        local y = GetUnitY(unit)

        if GetUnitCurrentOrder(unit) ~= oid.move then
            if not RectContainsUnit(data.rectHome, unit) then
                IssuePointOrderById(unit, oid.move, data.xHome, data.yHome)

            else
                ai.unit[data.id].stateCurrent = "Relax"
                local xNew, yNew = PolarProjectionCoordinates(x, y, 10,
                                                              data.facingHome)
                IssuePointOrderById(unit, oid.move, xNew, yNew)
            end
        end

        return true
    end

    --------
    --  TRIGGERS
    --------

    --------
    --  UNIT LOOPS
    --------

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
            if ai.unit[data.id].loop >
                (data.tick * ai.town[data.town].tickMultiplier) then
                ai.unit[data.id].loop = 0

                -- Run the routine for the unit's current state
                ai.unit.Intel(u)
                ai.unit.State(u, data.stateCurrent)
                ai.unit.Post(u)

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

    --------
    --  INIT
    --------

    --- Start Running the AI
    function ai.Start()

        -- Add Tick Event and Start Unit Loop Inteligence
        EnableTrigger(ai.trig.UnitLoop)

        -- Enable Unit Route Management
        EnableTrigger(ai.trig.UnitEntersRegion)

    end

    --- Stop Running the AI
    function ai.Stop()

        -- Stop Unit Intelligence
        DisableTrigger(ai.trig.UnitLoop)

        -- Enable Unit Route Management
        DisableTrigger(ai.trig.UnitEntersRegion)

    end
end

--
-- Functions
--
-- **Credit** KickKing
-- Returns true if the value is found in the table
function TableContains(table, element)
    for _, value in pairs(table) do if value == element then return true end end
    return false
end

-- **Credit** KickKing
-- Remove a value from a table
function TableRemoveValue(table, value)
    return table.remove(table, TableFind(table, value))
end

-- **Credit** KickKing
-- Find the indext of a value in a table
function TableFind(tab, el)
    for index, value in pairs(tab) do if value == el then return index end end
end

-- **Credit** KickKing
-- get distance without locations
function DistanceBetweenCoordinates(x1, y1, x2, y2)
    return SquareRoot(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)))
end

-- **Credit** KickKing
-- get distance without locations
function DistanceBetweenUnits(unitA, unitB)
    return DistanceBetweenCoordinates(GetUnitX(unitA), GetUnitY(unitA),
                                      GetUnitX(unitB), GetUnitY(unitB))
end

--- **Credit** KickKing
---get angle without locations
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number @angle between 0 and 360
function AngleBetweenCoordinates(x1, y1, x2, y2)
    return bj_RADTODEG * Atan2(y2 - y1, x2 - x1)
end

-- **Credit** KickKing
---get angle without locations
---@param unitA handle @Unit 1
---@param unitB handle @Unit 2
---@return number @angle between 0 and 360
function AngleBetweenUnits(unitA, unitB)
    return AngleBetweenCoordinates(GetUnitX(unitA), GetUnitY(unitA),
                                   GetUnitX(unitB), GetUnitY(unitB))
end

-- **Credit** KickKing
-- Polar projection with Locations
function PolarProjectionCoordinates(x, y, dist, angle)
    local newX = x + dist * Cos(angle * bj_DEGTORAD)
    local newY = y + dist * Sin(angle * bj_DEGTORAD)
    return newX, newY
end

-- ** Credit** Planetary
-- Wraps your code in a "Try" loop so you can see errors printed in the log at runtime
function Debugfunc(func, name) -- Turn on runtime logging
    local passed, data = pcall(function()
        func()
        return "func " .. name .. " passed"
    end)
    if not passed then print("|cffff0000[ERROR]|r" .. name, passed, data) end
end

-- **CREDIT** Taysen
-- Converts integer formated types into the 4 digit strings (Opposite of FourCC())
function CC2Four(num) -- Convert from Handle ID to Four Char
    return string.pack(">I4", num)
end

-- **CREDIT** Bribe
-- Timer Utils
do
    local data = {}
    function SetTimerData(whichTimer, dat) data[whichTimer] = dat end

    -- GetData functionality doesn't even require an argument.
    function GetTimerData(whichTimer)
        if not whichTimer then whichTimer = GetExpiredTimer() end
        return data[whichTimer]
    end

    -- NewTimer functionality includes optional parameter to pass data to timer.
    function NewTimer(dat)
        local t = CreateTimer()
        if dat then data[t] = dat end
        return t
    end

    -- Release functionality doesn't even need for you to pass the expired timer.
    -- as an arg. It also returns the user data passed.
    function ReleaseTimer(whichTimer)
        if not whichTimer then whichTimer = GetExpiredTimer() end
        local dat = data[whichTimer]
        data[whichTimer] = nil
        PauseTimer(whichTimer)
        DestroyTimer(whichTimer)
        return dat
    end
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
function GetRandomCoordinatesInPoints(xMin, xMax, yMin, yMax)
    return GetRandomReal(xMin, xMax), GetRandomReal(yMin, yMax)
end

--- Wait until Order ends or until the amount of time specified
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

---Credit KickKing -A system that allow you to duplicate the functionality of auto-filling in the Object Editor
---@param level             number @How many Levels or iterations to use for this
---@param base              number @The number to start with
---@param previousFactor    number @Multiply the previous level by this value
---@param levelFactor       number @This value exponential adds to itself every level
---@param constant          number @This gets added every level
---@return                  number @The calculated Value
function ValueFactor(level, base, previousFactor, levelFactor, constant)

    local value = base

    if level > 1 then
        for i = 2, level do
            value = (value * previousFactor) + (i * levelFactor) + (constant)
        end
    end

    return value
end

-- **Credit** Nestharus (Converted to Lua and turned into object by KickKing)
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


function INIT_Config()

    Debugfunc(function()
        -- Add Towns
        -- Set up the town, set activity probabiliy per tick and the AI tick Multipler (3, 1x)
        ai.town.New("city", 3, 1)

        -- Set the player group that the town finds Hostile
        ai.town.HostileForce("city", udg_townVillageForce)

        -- CounterClockwise Route (Listed as a looping route,
        -- meaning units will start at the step closest to their
        -- location and then finish on that same step by looping
        -- through all of the steps)
        ai.route.New("city_01", true, "inTown")
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
        ai.route.New("city_02", true, "inTown")
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
        ai.route.New("Out", true, "inTown")
        ai.route.Step(gg_rct_Region_031, 100)
        ai.route.Step(gg_rct_Region_032, 100)
        ai.route.Step(gg_rct_Region_033, 100)
        ai.route.Step(gg_rct_Region_034, 100)
        ai.route.Step(gg_rct_Region_035, 100)
        ai.route.Step(gg_rct_Region_036, 100)
        ai.route.Step(gg_rct_Region_038, 100)
        ai.route.Step(gg_rct_Region_039, 100)
        ai.route.Step(gg_rct_Region_040, 100)
        ai.route.Step(gg_rct_Region_029, 100)
        ai.route.Step(gg_rct_Region_030, 100)
        ai.route.Step(gg_rct_Region_015, 100)
        ai.route.Step(gg_rct_Region_016, 100)
        ai.route.Step(gg_rct_Region_018, 100)
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
        ai.route.Step(gg_rct_Region_018, 100)
        ai.route.Step(gg_rct_Region_017, 100)
        ai.route.Step(gg_rct_Region_016, 100)
        ai.route.Step(gg_rct_Region_015, 100)
        ai.route.Step(gg_rct_Region_030, 100)
        ai.route.Step(gg_rct_Region_002, 100)
        ai.route.Step(gg_rct_Region_003, 100)
        ai.route.Step(gg_rct_Region_004, 100)
        ai.route.Step(gg_rct_Region_005, 100)
        ai.route.Finish(100)



        -- Gather Units Together
        ai.route.New("gather", false, "inTown")
        ai.route.Step(gg_rct_Region_014, 100, "random")
        ai.route.Action(90, gg_rct_Region_028)
        ai.route.Finish(100)
        --
        -- Add all units on the map to AI
        local g = CreateGroup()

        -- Find all units
        g = GetUnitsInRectAll(GetPlayableMapRect())

        -- Loop through the units
        local u = FirstOfGroup(g)
        while u ~= nil do

            -- Add Unit (Will rename unit to the unit name specified)
            ai.unit.New("city", "villager", u, GetUnitName(u), "day")

            -- Add the routes that this unit has available to it when in the relax state
            ai.unit.AddRoute(u, "city_01")
            ai.unit.AddRoute(u, "city_02")
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
    u = BlzCreateUnitWithSkin(p, FourCC("hkni"), 25.9, -326.9, 91.112, FourCC("hkni"))
    u = BlzCreateUnitWithSkin(p, FourCC("hkni"), 1099.9, -399.0, 126.621, FourCC("hkni"))
    u = BlzCreateUnitWithSkin(p, FourCC("hpea"), 677.2, -606.0, 272.392, FourCC("hpea"))
    u = BlzCreateUnitWithSkin(p, FourCC("hpea"), 1272.1, 145.3, 71.534, FourCC("hpea"))
    u = BlzCreateUnitWithSkin(p, FourCC("hfoo"), 1005.5, 160.6, 36.948, FourCC("hfoo"))
    u = BlzCreateUnitWithSkin(p, FourCC("hfoo"), 923.4, -346.7, 144.387, FourCC("hfoo"))
    u = BlzCreateUnitWithSkin(p, FourCC("hfoo"), 1476.3, -1598.1, 313.614, FourCC("hfoo"))
    u = BlzCreateUnitWithSkin(p, FourCC("hfoo"), 1185.4, -2129.8, 54.878, FourCC("hfoo"))
    u = BlzCreateUnitWithSkin(p, FourCC("hspt"), -811.7, -581.3, 185.389, FourCC("hspt"))
end

function CreateNeutralPassive()
    local p = Player(PLAYER_NEUTRAL_PASSIVE)
    local u
    local unitID
    local t
    local life
    u = BlzCreateUnitWithSkin(p, FourCC("nvk2"), 1431.1, 224.5, 184.851, FourCC("nvk2"))
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
    u = BlzCreateUnitWithSkin(p, FourCC("nvil"), 547.3, -525.3, 174.611, FourCC("nvil"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), -821.2, -873.5, 176.764, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), -1615.0, -342.6, 282.994, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvl2"), -1239.8, 295.7, 163.460, FourCC("nvl2"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), -1372.7, 172.2, 196.507, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), -829.8, 855.3, 275.436, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), -439.1, 1740.9, 237.169, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 265.6, 1671.2, 37.805, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 568.5, 1499.4, 194.640, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 24.4, 177.2, 21.325, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 384.0, -721.4, 249.628, FourCC("nvlw"))
    u = BlzCreateUnitWithSkin(p, FourCC("nvlw"), 1417.1, -655.0, 193.288, FourCC("nvlw"))
end

function CreatePlayerBuildings()
end

function CreatePlayerUnits()
    CreateUnitsForPlayer0()
end

function CreateAllUnits()
    CreatePlayerBuildings()
    CreateNeutralPassive()
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
end

function Trig_Melee_Initialization_Actions()
    MeleeStartingVisibility()
    FogEnableOff()
    FogMaskEnableOff()
        INIT_AI(3, 5)
        INIT_Config()
        ai.Start()
end

function InitTrig_Melee_Initialization()
    gg_trg_Melee_Initialization = CreateTrigger()
    TriggerAddAction(gg_trg_Melee_Initialization, Trig_Melee_Initialization_Actions)
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
    DefineStartLocation(0, -1280.0, -640.0)
    InitCustomPlayerSlots()
    SetPlayerSlotAvailable(Player(0), MAP_CONTROL_USER)
    InitGenericPlayerSlots()
end

