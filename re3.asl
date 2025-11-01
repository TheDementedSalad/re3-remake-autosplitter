//Resident Evil 3 Remake Autosplitter
//By CursedToast & VideoGameRoulette 04/03/2020
//Revised version by TheDementedSalad 14 April 2024
//Special thanks to Squirrelies for collaborating in finding memory values.
//Last updated 13 April 2024

state("re3"){}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.Settings.CreateFromXml("Components/RE3make.Settings.xml");
}

init
{
	IntPtr TimelineEventManager = vars.Helper.ScanRel(3, "48 8b 05 ?? ?? ?? ?? 48 85 c0 0f 84 ?? ?? ?? ?? 48 8b 90 ?? ?? ?? ?? 48 85 d2 74 ?? 48 8b ce");
	IntPtr InventoryManager = vars.Helper.ScanRel(3, "48 8b 3d ?? ?? ?? ?? 48 83 78 ?? ?? 0f 85 ?? ?? ?? ?? 48 85 ff 0f 84");
	IntPtr GameClock = vars.Helper.ScanRel(3, "48 8b 05 ?? ?? ?? ?? 48 85 c0 0f 84 ?? ?? ?? ?? c6 40 ?? ?? 48 8b 43 ?? 48 39 78");
	IntPtr EnvironmentStandbyManager = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 8b cb 48 85 d2 0f 84 ?? ?? ?? ?? 41 b1 ?? c6 44 24");
	IntPtr MainFlowManager = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 85 d2 74 ?? 48 8b cb e8 ?? ?? ?? ?? 48 8b 43 ?? 4c 8b 70");
	IntPtr FadeManager = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 45 33 c0 48 8b cb 48 85 d2 74 ?? f3 0f 10 1d");
	IntPtr Difficulty = vars.Helper.ScanRel(3, "48 8b 2d ?? ?? ?? ?? 48 8b d6 48 8b cf");
	IntPtr GameRankSystem = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 83 78 ?? ?? 75 ?? 41 0f b6 40");
	
	//_CurrentChapter
	vars.Helper["EventID"] = vars.Helper.MakeString(TimelineEventManager, 0xD8, 0x60, 0x14);
	vars.Helper["EventID"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["isGame"] = vars.Helper.Make<bool>(GameClock, 0x50);
	vars.Helper["isDemo"] = vars.Helper.Make<bool>(GameClock, 0x51);
	vars.Helper["isPause"] = vars.Helper.Make<bool>(GameClock, 0x53);
	vars.Helper["GameElapsedTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x18);
	vars.Helper["DemoSpendingTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x20);
	vars.Helper["PauseSpendingTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x30);
	vars.Helper["MapID"] = vars.Helper.Make<short>(EnvironmentStandbyManager, 0xA8, 0x10);
	vars.Helper["GameStartValue"] = vars.Helper.Make<byte>(MainFlowManager, 0x54);
	vars.Helper["SoundStateValue"] = vars.Helper.Make<byte>(MainFlowManager, 0x68);
	vars.Helper["DiffNo"] = vars.Helper.Make<byte>(Difficulty, 0xC0, 0x78);
	vars.Helper["DA"] = vars.Helper.Make<float>(GameRankSystem, 0x5C);
	vars.Helper["Fade3"] = vars.Helper.Make<bool>(FadeManager, 0x50, 0x30, 0x18, 0x68);

	
	if (TimelineEventManager == IntPtr.Zero || InventoryManager == IntPtr.Zero || GameClock == IntPtr.Zero || EnvironmentStandbyManager == IntPtr.Zero || MainFlowManager == IntPtr.Zero)
	{
		const string Msg = "Not all required addresses could be found by scanning.";
		throw new Exception(Msg);
	}
	
	vars.Inv = InventoryManager;
	vars.Clock = GameClock;
	vars.DA = GameRankSystem;

	vars.completedSplits = new HashSet<string>();
	
	current.inventory = new int[20].Select((_, i)
		=> new DeepPointer(vars.Inv, 0x50, 0x98, 0x10, 0x20 + (i * 8), 0x18, 0x10, 0x10).Deref<int>(game))
		.ToArray();
}

update
{
	//print(modules.First().ModuleMemorySize.ToString());
	
	vars.Helper.Update();
	vars.Helper.MapPointers();
	
	// Track inventory IDs
    current.inventory = new int[20].Select((_, i)
		=> new DeepPointer(vars.Inv, 0x50, 0x98, 0x10, 0x20 + (i * 8), 0x18, 0x10, 0x10).Deref<int>(game))
		.ToArray();
	
	if(settings["NoInt"]){
		if(!settings["NoIntHard"]){
			if(current.MapID == 134 && current.SoundStateValue == 9 && old.SoundStateValue == 10){
				game.WriteValue<long>(game.ReadPointer(game.ReadPointer((IntPtr)vars.Clock) + 0x60) + 0x18, 0);
				game.WriteValue<long>(game.ReadPointer(game.ReadPointer((IntPtr)vars.Clock) + 0x60) + 0x20, 0);
				game.WriteValue<long>(game.ReadPointer(game.ReadPointer((IntPtr)vars.Clock) + 0x60) + 0x30, 0);
			}
		}
		
		if(settings["NoIntHard"]){
			if(current.MapID == 134 && current.SoundStateValue == 9 && old.SoundStateValue == 10){
				game.WriteValue<long>(game.ReadPointer(game.ReadPointer((IntPtr)vars.Clock) + 0x60) + 0x18, 6500000);
				game.WriteValue<long>(game.ReadPointer(game.ReadPointer((IntPtr)vars.Clock) + 0x60) + 0x20, 0);
				game.WriteValue<long>(game.ReadPointer(game.ReadPointer((IntPtr)vars.Clock) + 0x60) + 0x30, 0);
			}
		}
		
		if(current.MapID == 134 && !current.Fade3 && old.Fade3 || current.MapID == 134 && current.DiffNo != old. DiffNo){
			switch ((byte)current.DiffNo){
				case 0:
					game.WriteValue<float>(game.ReadPointer((IntPtr)vars.DA) + 0x5C, 2500);
					break;
				case 1:
					game.WriteValue<float>(game.ReadPointer((IntPtr)vars.DA) + 0x5C, 5500);
					break;
				case 2:
					game.WriteValue<float>(game.ReadPointer((IntPtr)vars.DA) + 0x5C, 9000);
					break;
				case 3:
					game.WriteValue<float>(game.ReadPointer((IntPtr)vars.DA) + 0x5C, 10620);
					break;
				case 4:
					game.WriteValue<float>(game.ReadPointer((IntPtr)vars.DA) + 0x5C, 11620);
					break;
			}
		}
	}
}

onStart
{
	vars.completedSplits.Clear();
}

start
{	
	// isNewGameStart conditions
    return string.IsNullOrEmpty(current.EventID) && old.EventID == "EV000" || current.MapID == 134 && current.SoundStateValue == 9 && old.SoundStateValue == 10;
}

split
{
	string setting = "";
	
	int[] currentInventory = (current.inventory as int[]);
	int[] oldInventory = (old.inventory as int[]);

	if(!currentInventory.SequenceEqual(oldInventory)){
		int[] delta = (currentInventory as int[]).Where((v, i) => v != oldInventory[i]).ToArray();

		foreach (int item in delta){
			if(item != 0){
				setting = string.Format("Item_" + item);
			}
		}
	}
	
	var removedItems = oldInventory.Except(currentInventory);

	if (removedItems.Contains(217)){
		setting = string.Format("ItemR_217");
	}
	
	if(current.MapID != old.MapID){
		setting = string.Format("Map_" + current.MapID);
	}
	
	if(current.EventID != old.EventID && !string.IsNullOrEmpty(current.EventID)){
		setting = string.Format("Event_" + current.EventID);
	}
	
	// Debug. Comment out before release.
    if (!string.IsNullOrEmpty(setting))
    vars.Log(setting);

	if (settings.ContainsKey(setting) && settings[setting] && vars.completedSplits.Add(setting)){
		return true;
	}
	
	if(current.SoundStateValue == 12 && old.SoundStateValue != 12){
		return true;
	}
}

gameTime
{
	return TimeSpan.FromSeconds((current.GameElapsedTime - current.DemoSpendingTime - current.PauseSpendingTime) / 1000000.0);
}

isLoading
{
	return true;
}

reset
{	
	return current.GameStartValue == 1 && old.GameStartValue == 0 || current.MapID == 134 && current.SoundStateValue == 9 && old.SoundStateValue == 10;
}
