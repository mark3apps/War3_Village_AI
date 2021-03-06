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

