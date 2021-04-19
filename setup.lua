function INIT_Config()

	Debugfunc(function()

		-- Add Towns
		-- Set up the town, set activity probabiliy per tick and the AI tick Multipler (3% chance to start moving, 1x)
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

			-- ai.unit.New(townName, AIType, Unit, UnitName, Shift)
			-- ai.unit.AddRoute(Unit, RouteName)

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

