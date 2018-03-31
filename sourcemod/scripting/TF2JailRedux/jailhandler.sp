#define GravSound 		"vo/scout_sf12_badmagic11.mp3"
#define HHH 			"models/bots/headless_hatman.mdl"	// Taken from flaminsarge's bethehorsemann don't crucify me
#define AXE 			"models/weapons/c_models/c_bigaxe/c_bigaxe.mdl"
#define SPAWN 			"ui/halloween_boss_summoned_fx.wav"
#define SPAWNRUMBLE 	"ui/halloween_boss_summon_rumble.wav"
#define SPAWNVO 		"vo/halloween_boss/knight_spawn.wav"
#define BOO 			"vo/halloween_boss/knight_alert.wav"
#define DEATH 			"ui/halloween_boss_defeated_fx.wav"
#define DEATHVO 		"vo/halloween_boss/knight_death02.wav"
#define DEATHVO2 		"vo/halloween_boss/knight_dying.wav"
#define LEFTFOOT 		"player/footsteps/giant1.wav"
#define RIGHTFOOT 		"player/footsteps/giant2.wav"
#define Extinguish		"player/flame_out.wav"
#define Engulf			"misc/flame_engulf.wav"
#define SuicideSound	"weapons/csgo_awp_shoot.wav"
#define GunSound		"vo/heavy_meleedare02.mp3"
#define TinySound		"vo/scout_sf12_badmagic28.mp3"
#define NO 				"vo/heavy_no02.mp3"

/** 
 *	Simply add your new lr name to the enum to register it with function calls and switch statements
 *	Add them to the calls accordingly 
*/
enum /** LRs **/
{
	// RegularGameplay = -1,
	Suicide = 0,	//
	Custom = 1,		// These 2 shouldn't register with gameplay orientation and are kept out of randlr
	FreedaySelf = 2,
	FreedayOther = 3,
	FreedayAll = 4,
	GuardMelee = 5,
	HHHDay = 6,
	TinyRound = 7,
	HotPrisoner = 8,
	Gravity = 9,
	RandomKill = 10,
	Warday = 11,
	ClassWars = 12,
	// VSH = 13			// DO NOT SET ANY NEW LRS UNDER THESE NUMBERS UNLESS YOU DISABLE OR ADJUST THE SUB PLUGIN CONVARS!
	// PH = 14,			// THEY WILL OVERLAP!
};
/** 
 *	When adding a new lr, increase the LRMAX to the proper/latest enum value
 *	Reminder that random lr grabs a random int from 2 to LRMAX
 *	Having breaks or skips within the enum will result in nothing happening the following round if that number is selected
 *	hPlugins.Length increases by 1 every time you 'TF2JailRedux_RegisterPlugin()' with a sub-plugin
 *	Sub-Plugins *should* be completely manageable as their own plugin, with no need to touch this one
*/
#define LRMAX		ClassWars + (hPlugins.Length)

#include "TF2JailRedux/jailbase.sp"
#include "TF2JailRedux/jailgamemode.sp"

JailGameMode gamemode;	// Must be declared AFTER methodmap, but BEFORE any methods are used

/** 
 *	SINCE THE PYRO UPDATE, FORCING PLAYERS AS THE SNIPER CLASS CAN AND WILL CAUSE SERVER CRASHES
*/
int arrClass[8] = { 1, 3, 4, 5, 6, 7, 8, 9 };

/** 
 *	ArrayList of LR usage
 *	You can determine the maximum picks per round under AddLRToMenu()
 *	Size is automatically managed
*/
 ArrayList arrLRS;
// int arrLRS[LRMAX + 1] = {	/* Plus 1 to counterbalance the 0 in the enum*/ 	};

/** 
 *	Add your LR name to the array, referred back to in AddLRToMenu()
*/
char strLRNames[][] = {
	"Suicide",
	"Custom",
	"Freeday for Yourself",
	"Freeday for Others",
	"Freeday for All",
	"Guards Melee Only",
	"Headless Horsemann Day",
	"Tiny Round",
	"Hot Prisoner",
	"Low Gravity",
	"Sniper!",
	"Warday",
	"Class Wars"
	// "",	// VSH
	// ""	// PH
	// Be aware of sub-plugin indices
};

/** 
 *	Calls on map start, don't forget 'Prepare' stocks precache and set downloads at the same time! 
*/
public void ManageDownloads()
{
	PrecacheSound("vo/announcer_ends_60sec.mp3", true);
	PrecacheSound("vo/announcer_ends_30sec.mp3", true);
	PrecacheSound("vo/announcer_ends_10sec.mp3", true);

	for (int s = 1; s <= 5; s++)
	{
		Format(snd, PLATFORM_MAX_PATH, "vo/announcer_ends_%isec.mp3", s);
		PrecacheSound(snd, true);
	}

	PrecacheSound(GravSound, true);
	PrecacheModel(HHH, true);
	PrecacheModel(AXE, true);
	PrecacheSound(SPAWN, true);
	PrecacheSound(SPAWNRUMBLE, true);
	PrecacheSound(SPAWNVO, true);
	PrecacheSound(BOO, true);
	PrecacheSound(DEATH, true);
	PrecacheSound(DEATHVO, true);
	PrecacheSound(DEATHVO2, true);
	PrecacheSound(LEFTFOOT, true);
	PrecacheSound(RIGHTFOOT, true);
	PrecacheSound(Extinguish, true);
	PrecacheSound(Engulf, true);
	PrecacheSound(SuicideSound, true);
	PrecacheSound(GunSound, true);
	PrecacheSound(TinySound, true);
	PrecacheSound(NO, true);

	iLaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	iHalo = PrecacheModel("materials/sprites/glow01.vmt", true);

	PrecacheSound("misc/rd_finale_beep01.wav", true);
	Call_OnDownloads();
}
/*
 *	Starting variables for clients entering the server
 *	This is just for forwards to get/set with inherited properties without either firing too early with OnClientPutInServer()
 *	Or having to use OnClientPostAdminCheck()
*/
public void ManageClientStartVariables(const JailFighter base)
{
	Call_OnClientInduction(base);
}
/** 
 *	Calls on map end, resets for lr variables
*/
public void ManageMapResetVariables(const JailFighter player)
{
	if (player.bIsHHH)
		player.UnHorsemann();
		
	ResetModelProps(player.index);
	player.SetCustomModel("");
	//RemoveModel(player.index);
}
/**
 *	Another reset, but calls on disconnect for safety
*/
public void ManageClientDisconnect(const JailFighter player)
{
	if (player.bIsWarden)
	{
		player.WardenUnset();
		PrintCenterTextAll("Warden has disconnected!");
		gamemode.bWardenExists = false;
	}
}
/**
 *	Fires on both client disconnect and round start
 *	Yet again another way to make a new forward
*/
public void ResetVariables(const JailFighter base, const bool compl)
{
	base.iCustom = 0;
	base.iKillCount = 0;
	base.bIsWarden = false;
	base.bIsFreeday = false;
	base.bLockedFromWarden = false;
	base.bIsHHH = false;
	base.bInJump = false;
	base.bUnableToTeleport = false;
	base.bEvilBeamed = false;
	base.flSpeed = 0.0;
	base.flKillSpree = 0.0;
	if (compl)
	{
		base.bIsMuted = false;
		base.bIsQueuedFreeday = false;
		base.bIsVIP = false;
		base.bIsAdmin = false;
	}

	Call_OnVariableReset(base);
}
/**
 *	Add lr to the LR menu obviously
*/
public void AddLRToMenu(Menu &menu)
{
	char strName[32], strID[4], strValue[16];
	int i, max, value, def = cvarTF2Jail[LRDefault].IntValue;

	menu.AddItem("-1", "Random LR");
	for (i = 0; i <= LRMAX; i++)
	{
		max = def;
		strValue[0] = '\0';
		strName[0] = '\0';
		// if (i == Warday)	// If you want a certain last request to have a different max, do something like this
			// max = 3;
		Call_OnMenuAdd(i, max, strName);

		if (max)
		{
			value = arrLRS.Get(i);
			Format(strValue, sizeof(strValue), " (%i/%i)", value, max);
		}

		if (i < sizeof(strLRNames))	// If not a sub-plugin
			Format(strName, sizeof(strName), "%s%s", strName, strLRNames[i][0]);
		Format(strName, sizeof(strName), "%s%s", strName, strValue);	// Forward pre-formats strName

		IntToString(i, strID, sizeof(strID));
		menu.AddItem(strID, strName, (max && value >= max) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT); // Disables the LR selection if the max is too high
	}
/**
 *	According to this, you have to have your sub-plugin(s) LR as the last in the enum... always... probably
 *	If you have more than one, you have to distinguish which plugin has which enum value and stick with it
 *	Secondly, you have to format strLRNames yourself on the menu item 
 *	arrLRs is able to handle lr counts in this plugin but make sure you use the ArrayList in your OnLRPicked() forward
*/
}
/**
 *	Add a 'short' description to your last request for the !listlrs command
*/
public void AddLRToPanel(Menu &panel)
{
	panel.AddItem("0", "Suicide- Kill yourself on the spot");
	panel.AddItem("1", "Custom- Type your own last request");
	panel.AddItem("2", "Freeday for Yourself- Give yourself a freeday");
	char strFreeday[64]; Format(strFreeday, sizeof(strFreeday), "Freeday for Others- Give up to %i freedays to others", cvarTF2Jail[FreedayLimit].IntValue);
	panel.AddItem("3", strFreeday);
	panel.AddItem("4", "Freeday for All- Give everybody a freeday");
	panel.AddItem("5", "Guards Melee Only- Those guns are for babies!");
	panel.AddItem("6", "Headless Horsemann Day- Turns all players into the HHH");
	panel.AddItem("7", "Tiny Round- Honey I shrunk the players");
	panel.AddItem("8", "Hot Prisoner- Prisoners are too hot to touch");
	panel.AddItem("9", "Low Gravity- Where did the gravity go");
	panel.AddItem("10", "Sniper- A hired gun to take out some folks");
	panel.AddItem("11", "Warday- Team Deathmatch");
	panel.AddItem("12", "Class Wars- Class versus class Warday");

	Call_OnPanelAdd(panel);
}
/** 
 *	Called when player is given lr and is selecting. Place your lr under the MenuAction_Select case
 *	Use the already given lr's as a guide if you need help
 *	CheckSet() is purely used for safety
*/
public int ListLRsMenu(Menu menu, MenuAction action, int client, int select)
{
	if (!IsClientValid(client) || !IsPlayerAlive(client))
		return;
		
	switch (action)
	{
		case MenuAction_Select:
		{
			JailFighter base;
			char strIndex[4]; menu.GetItem(select, strIndex, sizeof(strIndex));
			if (cvarTF2Jail[RemoveFreedayOnLR].BoolValue)
			{
				for (int i = MaxClients; i; --i)
				{
					if (!IsClientInGame(i))
						continue;
					base = JailFighter(i);
					if (!base.bIsFreeday)
						continue;
						
					base.RemoveFreeday();
				}
				CPrintToChatAll("{crimson}[TF2Jail]{burlywood} Last request has been chosen. Freedays have been stripped.");
			}
			base = JailFighter(client);
			gamemode.bIsLRInUse = true;
			int request = StringToInt(strIndex), value;
			if (request != -1)	// If the selection isn't random
				value = arrLRS.Get(request);

			switch (request)
			{
				case -1:	// Random
				{
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen a {default}Random Last Request{burlywood} as their last request!", client);
					int randlr = GetRandomInt(2, LRMAX);
					gamemode.iLRPresetType = randlr;
					arrLRS.Set( randlr, arrLRS.Get(randlr)+1 );
					if (randlr == FreedaySelf)
						base.bIsQueuedFreeday = true;
					else if (randlr == FreedayOther)
						for (int i = 0; i < 3; i++)
							JailFighter(GetRandomPlayer(RED)).bIsQueuedFreeday = true;
				}
				case Suicide:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen to kill themselves. What a shame...", client);
					SetPawnTimer(KillThatBitch, (GetRandomFloat(0.5, 7.0)), client);	// Meme lol
					arrLRS.Set( request, value+1 );
				}
				case Custom:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen to type out their LR in chat.", client);
					gamemode.iLRPresetType = Custom;
					arrLRS.Set( request, value+1 );
					base.iCustom = base.userid;
				}
				case FreedaySelf:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen {default}Freeday for Themselves{burlywood} next round.", client);
					gamemode.iLRPresetType = FreedaySelf;
					base.bIsQueuedFreeday = true;
					arrLRS.Set( request, value+1 );
				}
				case FreedayOther:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N is picking Freedays for next round...", client);
					FreedayforClientsMenu(client);
					gamemode.iLRPresetType = FreedayOther;
					arrLRS.Set( request, value+1 );
				}
				case FreedayAll:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen to grant a {default}Freeday for All{burlywood} next round.", client);
					gamemode.iLRPresetType = FreedayAll;
					arrLRS.Set( request, value+1 );
				}
				case GuardMelee:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen to strip the guards of their weapons.", client);
					gamemode.iLRPresetType = GuardMelee;
					arrLRS.Set( request, value+1 );
				}
				case HHHDay:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen {default}Horseless Headless Horsemann Kill Round{burlywood} next round.", client);
					gamemode.iLRPresetType = HHHDay;
					arrLRS.Set( request, value+1 );
				}
				case TinyRound:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen {default}Super Small{burlywood} for everyone.", client);
					gamemode.iLRPresetType = TinyRound;
					arrLRS.Set( request, value+1 );
				}
				case HotPrisoner:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen to ignite all of the prisoners next round!", client);
					gamemode.iLRPresetType = HotPrisoner;
					arrLRS.Set( request, value+1 );
				}
				case Gravity:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen {default}Low Gravity{burlywood} as their last request.", client);
					gamemode.iLRPresetType = Gravity;
					arrLRS.Set( request, value+1 );
				}
				case RandomKill:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen to hire a Sniper for the next round!", client);
					gamemode.iLRPresetType = RandomKill;
					arrLRS.Set( request, value+1 );
				}
				case Warday:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen to do a {default}Warday{burlywood}.", client);
					gamemode.iLRPresetType = Warday;
					arrLRS.Set( request, value+1 );
				}
				case ClassWars:
				{
					if (!CheckSet(client, value, cvarTF2Jail[LRDefault].IntValue))
						return;
					CPrintToChatAll("{crimson}[TF2Jail]{burlywood} %N has chosen {default}Class Warfare{burlywood} as their last request.", client);
					gamemode.iLRPresetType = ClassWars;
					arrLRS.Set( request, value+1 );
				}
				default:
				{
					// arrLRS.Set( request, value+1 );
					Call_OnLRPicked(base, request, value, arrLRS);		// Menu functions aren't needed
					// I went through so much effort to give this extra parameter even though you could easily get that value in your own plugin...
				}
			}
		}
		case MenuAction_End:delete menu;
	}
}
/**
 *	Displays lr HUD text during the round, Format() the name accordingly
*/
public void ManageHUDText()
{
	char strHudName[128];
	switch (gamemode.iLRType)
	{
		case -1: {	}
		//case FreedaySelf, FreedayOther:Format(strHudName, sizeof(strHudName), "");	// Should be blank
		case Custom:		strcopy(strHudName, sizeof(strHudName), strCustomLR);
		case FreedayAll:	strcopy(strHudName, sizeof(strHudName), "Freeday For All");
		case GuardMelee:	strcopy(strHudName, sizeof(strHudName), "Guards Melee Only");
		case HHHDay:		strcopy(strHudName, sizeof(strHudName), "Headless Horsemann Day");
		case TinyRound:		strcopy(strHudName, sizeof(strHudName), "Tiny Round");
		case HotPrisoner:	strcopy(strHudName, sizeof(strHudName), "Hot Prisoners");
		case Gravity:		strcopy(strHudName, sizeof(strHudName), "Low Gravity");
		case RandomKill:	strcopy(strHudName, sizeof(strHudName), "Sniper!");
		case Warday:		strcopy(strHudName, sizeof(strHudName), "Warday");
		case ClassWars:		strcopy(strHudName, sizeof(strHudName), "Class Warfare");
		default: 			Call_OnLRTextHud(strHudName);
	}

	if (strHudName[0] != '\0')
		SetTextNode(hTextNodes[1], strHudName, EnumTNPS[1][fCoord_X], EnumTNPS[1][fCoord_Y], EnumTNPS[1][fHoldTime], EnumTNPS[1][iRed], EnumTNPS[1][iGreen], EnumTNPS[1][iBlue], EnumTNPS[1][iAlpha], EnumTNPS[1][iEffect], EnumTNPS[1][fFXTime], EnumTNPS[1][fFadeIn], EnumTNPS[1][fFadeOut]);
}
/**
 *	Called directly when a player spawns, be sure to note iRoundState(s) if being specific
*/
public void ManageSpawn(const JailFighter base, Event event)
{
	// int client = base.index;

	Call_OnPlayerSpawned(base, event);
}
/**
 *	Manage each player just after spawn
*/
public void PrepPlayer(const int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	JailFighter base = JailFighter(client);

	TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Item1);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Item2);
	base.EmptyWeaponSlots();	// We call this last so the spawned weapons are registered with the function

	Call_OnPlayerPrepped(base);
}
/**
 *	Calls on lr round start for each living player
*/
public void OnLRActivate(const JailFighter player)
{
	int client = player.index;

	switch (gamemode.iLRType)
	{
		case FreedaySelf, FreedayOther:
		{
			if (player.bIsQueuedFreeday)
				CPrintToChatAll("{burlywood}Freeday is now active for {default}%N{burlywood}.", client);
		}
		case GuardMelee:
		{
			if (TF2_GetClientTeam(client) == TFTeam_Blue)
			{
				player.StripToMelee();
				if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 44 || GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 648)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					player.SpawnWeapon("tf_weapon_bat", 0, 1, 0, "");
					SetEntityHealth(client, 125);
				}
			}
		}
		case HHHDay:player.MakeHorsemann();	// Fuck server commands, hard coding feels more solid
		case TinyRound:SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.3);
		case HotPrisoner:
		{
			if (TF2_GetClientTeam(client) == TFTeam_Red)
			{
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 255, 75, 75, 255);
			}
		}
		case Warday, ClassWars:ResetPlayer(client);
	}

	if (gamemode.bIsWarday)
	{
		if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 589 && GetClientTeam(client) == BLU)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			player.SpawnWeapon("tf_weapon_wrench", 7, 1, 0, "");
		}

		int _4wep = GetPlayerWeaponSlot(client, 4);
		if (_4wep > MaxClients && IsValidEdict(_4wep) && GetEntProp(_4wep, Prop_Send, "m_iItemDefinitionIndex") == 60)
		{
			TF2_RemoveWeaponSlot(client, 4);
			player.SpawnWeapon("tf_weapon_invis", 30, 1, 0, "");
		}
	}
	Call_OnLRRoundActivate(player);
}
/**
 *	Calls without including players, so we don't fire the same thing for every player
*/
public void ManageRoundStart()
{
	switch (gamemode.iLRType)
	{
		case FreedayAll:
		{
			gamemode.bIsWardenLocked = true;
			gamemode.bIsFreedayRound = true;
			CPrintToChatAll("{burlywood}Freeday is now active for {default}ALL players{burlywood}.");
		}
		case GuardMelee:EmitSoundToAll(GunSound);
		case HHHDay:
		{
			gamemode.bIsWardenLocked = true;
			gamemode.bIsWarday = true;
			gamemode.bDisableCriticals = true;
			CPrintToChatAll("{burlywood}BOO!");
			EmitSoundToAll(SPAWN);
			EmitSoundToAll(SPAWNRUMBLE);
		}
		case TinyRound:
		{
			EmitSoundToAll(TinySound);
			CPrintToChatAll("{burlywood} SuperSmall for everyone activated.");
			gamemode.bIsWardenLocked = true;
		}
		case Gravity:
		{
			CPrintToChatAll("{burlywood}Where did the gravity go?");
			EmitSoundToAll(GravSound);
			hEngineConVars[2].SetInt(100);
		}
		case HotPrisoner:
		{
			CPrintToChatAll("{burlywood}I'm too hot! Hot damn!");
			EmitSoundToAll(Engulf);
		}
		case RandomKill:
		{
			CPrintToChatAll("{burlywood}Look out! Sniper!");
			SDKHooks_TakeDamage(GetRandomClient(), 0, 0, 9001.0, DMG_DIRECT|DMG_BULLET, _, _, _);	// Lol rip, no fun for this guy
			EmitSoundToAll(SuicideSound);
			SetPawnTimer(RandSniper, GetRandomFloat(30.0, 60.0), gamemode.iRoundCount);
		}
		case Warday:
		{
			CPrintToChatAll("{burlywood} *War kazoo sounds*");
			gamemode.bIsWarday = true;
			gamemode.bIsWardenLocked = true;
			// EmitSoundToAll(WardaySound);
		}
		case ClassWars:
		{
			int iClassRED = arrClass[GetRandomInt(0, 7)];
			int iClassBLU = arrClass[GetRandomInt(0, 7)];
			for (int i = MaxClients; i; --i)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i))
					continue;

				if (GetClientTeam(i) == RED)
					TF2_SetPlayerClass(i, view_as< TFClassType >(iClassRED));
				else TF2_SetPlayerClass(i, view_as< TFClassType >(iClassBLU));
			}
			gamemode.bIsWarday = true;
			gamemode.bIsWardenLocked = true;
		}
	}
	Call_OnManageRoundStart();
}
/** 
 *	Calls on round end obviously, resets should be put here as well 
*/
public void ManageRoundEnd(const JailFighter base)
{
	switch(gamemode.iLRType)
	{
		case HHHDay:
		{
			if (base.bIsHHH)
				SetPawnTimer(UnHorsemannify, 1.0, base);	//base.UnHorsemann();
		}
		case TinyRound:SetPawnTimer(ResetModelProps, 1.0, base.index);
		case HotPrisoner:
		{
			if (TF2_GetClientTeam(base.index) == TFTeam_Red)
				SetEntityRenderColor(base.index, 255, 255, 255, 255);
		}
	}
	Call_OnLRRoundEnd(base);
}
/**
 *	Calls on round end without players so we don't fire again for every player
*/
public void ManageOnRoundEnd(Event event)
{
	switch (gamemode.iLRType)
	{
		case HHHDay:
		{
			EmitSoundToAll(DEATH);
			EmitSoundToAll(DEATHVO);
			EmitSoundToAll(DEATHVO2);
		}
		case Gravity:hEngineConVars[2].SetInt(800);
		case HotPrisoner:EmitSoundToAll(Extinguish);
		case RandomKill:SetPawnTimer(EndRandSniper, GetRandomFloat(0.1, 0.3), gamemode.iRoundCount);
		default: {	}
	}
	Call_OnManageRoundEnd(event);
}
/**
 *	Manage jail cell behavior on round start; choose OPEN/CLOSE/LOCK/UNLOCK
*/
public void ManageCells()
{
	switch (gamemode.iLRType)
	{
		case FreedayAll, 
			TinyRound, 
			HHHDay, 
			Warday, 
			ClassWars
			:gamemode.DoorHandler(OPEN);
		/*case example:gamemode.DoorHandler(OPEN or CLOSE or LOCK or UNLOCK);*/
	}
}
/**
 *	If you want something specific to happen to warden on get, stick it here
*/
public void ManageWarden(const JailFighter base)
{
	switch (gamemode.iLRType)
	{
		default: {	}
	}
	Call_OnWardenGet(base);
}
/**
 *	Called on model collision between players, Red player in this case is the 'toucher'
*/
public void ManageRedTouchBlue(const JailFighter toucher, const JailFighter touchee)
{
	switch (gamemode.iLRType)
	{
		case HotPrisoner:
		{
			//TF2_AddCondition(touchee.index, TFCond_OnFire, 8.0);
			TF2_IgnitePlayer(touchee.index, toucher.index);
			SDKHooks_TakeDamage(touchee.index, 0, 0, 1.0, DMG_BURN, _, _, _);	
		}
		default: {	}
	}
	Call_OnClientTouch(toucher, touchee);
}
/**
 *	Set Friendly Fire timer on round start
*/
public void ManageFFTimer()
{
	switch (gamemode.iLRType)
	{
		case 
			HHHDay, 
			TinyRound
		:SetPawnTimer(EnableFFTimer, 10.0, gamemode.iRoundCount);
		default: {	}
	}
}
/**
 *	Register what happens when a player receives a TFCond condition
*/
public void TF2_OnConditionAdded(int client, TFCond cond)
{	
	switch (cond)
	{
		case TFCond_Disguising, TFCond_Disguised:
		{
			switch (cvarTF2Jail[Disguising].IntValue)
			{
				case 0:TF2_RemoveCondition(client, cond);
				case 1:if (GetClientTeam(client) == BLU) TF2_RemoveCondition(client, cond);
				case 2:if (GetClientTeam(client) == RED) TF2_RemoveCondition(client, cond);
			}
		}
		case TFCond_Charging:
		{
			switch (cvarTF2Jail[NoCharge].IntValue)
			{
				case 1:if (GetClientTeam(client) == BLU) TF2_RemoveCondition(client, cond);
				case 2:if (GetClientTeam(client) == RED) TF2_RemoveCondition(client, cond);
				case 3:TF2_RemoveCondition(client, cond);
			}
		}
	}
}
/**
 *	Vice versa as above
*/
/*public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	switch (cond)
	{
		default: {	}
	}
}*/

/** 
 *	Think: Code called every 0.1 seconds per client, aka poor man's SDKHook_Think
 *	If lr requires the same think properties from both teams, set it under both team thinks
 *	Thinks overlap on WardenThink and BlueThink so be wary of this
*/
/**
 *	Red Team think
*/
public void ManageRedThink(const JailFighter player)
{
	switch (gamemode.iLRType)
	{
		default: {	}
	}
	Call_OnRedThink(player);
}
/**
 *	Manage complete Blue Team think 
*/
public void ManageBlueThink(const JailFighter player)
{
	switch (gamemode.iLRType)
	{
		default:if (!gamemode.bDisableCriticals && cvarTF2Jail[CritType].IntValue == 1)
			TF2_AddCondition(player.index, TFCond_Buffed, 0.2);
	}
	Call_OnBlueThink(player);
}
/**
 *	Blue Team think. Does NOT include warden
*/
/*public void ManageBlueNotWardenThink(const JailFighter player)
{
	switch (gamemode.iLRType)
	{
		default: {	}
	}
	Call_OnBlueNotWardenThink(player);
}*/
/**
 *	Warden think only
*/
public void ManageWardenThink(const JailFighter player)
{
	switch (gamemode.iLRType)
	{
		default: {	}
	}
	Call_OnWardenThink(player);
}
/**
 *	Sound hooking for certain scenarios
*/
public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (!bEnabled.BoolValue || !IsClientValid(entity))
		return Plugin_Continue;
		
	JailFighter base = JailFighter(entity);
	switch (gamemode.iLRType)
	{
		case HHHDay:
		{
			if (base.bIsHHH)
			{
				if (!strncmp(sample, "vo", 2, false))
					return Plugin_Handled;
				
				if (strncmp(sample, "player/footsteps/", 17, false) != -1)
				{
					if (StrContains(sample, "1.wav", false) != -1 || StrContains(sample, "3.wav", false) != -1) 
						sample = LEFTFOOT;
					else if (StrContains(sample, "2.wav", false) != -1 || StrContains(sample, "4.wav", false) != -1) 
						sample = RIGHTFOOT;
					EmitSoundToAll(sample, entity);
					return Plugin_Changed;
				}
			}
		}
		default: {	}
	}
	return Plugin_Continue;
}
/**
 *	PreThink management, will not fire for dead players
*/
public void ManageOnPreThink(const JailFighter base, int buttons)
{
	switch (gamemode.iLRType)
	{
		default: {	}
	}

	Call_OnPreThink(base, buttons);
}
/**
 *	Calls when a a player is hurt without SDKHooks
*/
public void ManageHurtPlayer(const JailFighter attacker, const JailFighter victim, Event event)
{
	int damage = event.GetInt("damageamount");
	int custom = event.GetInt("custom");
	int weapon = event.GetInt("weaponid");
	
	switch (gamemode.iLRType)
	{
		default: {	}
	}
	Call_OnHurtPlayer(victim, attacker, damage, custom, weapon, event);
}
/** 
 *	Calls when damage is taken/given during lr with SDKHooks
*/
public Action ManageOnTakeDamage(const JailFighter victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	switch (gamemode.iLRType)
	{
		default:
		{
			if (IsClientValid(attacker))
			{
				JailFighter base = JailFighter(attacker);
				if (base.bIsFreeday)
				{	// Registers with Razorbacks ^^
					base.RemoveFreeday();
					PrintCenterTextAll("%N has attacked a guard and lost their freeday!", attacker);
				}

				if (victim.bIsFreeday && !base.bIsWarden)
				{
					damage *= 0.0;
					return Plugin_Changed;
				}

				if (GetClientTeam(attacker) == BLU && cvarTF2Jail[CritType].IntValue == 2 && !gamemode.bDisableCriticals && !TF2_IsPlayerCritBuffed(attacker))
				{
					damagetype |= DMG_CRIT;
					return Plugin_Changed;
				}
			}
		}
	}
	return Call_OnHookDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
}
/**
 *	Called when a player dies obviously
*/
public void ManagePlayerDeath(const JailFighter attacker, const JailFighter victim, Event event)
{
	switch (gamemode.iLRType)
	{
		case HHHDay:
		{
			if (victim.bIsHHH)
			{
				EmitSoundToAll(DEATHVO, victim.index);
				SetPawnTimer(UnHorsemannify, 0.2, victim);
				// victim.UnHorsemann();
			}
		}
		case RandomKill:
		{
			if ((attacker.index <= 0 && event.GetInt("damagebits") & DMG_BULLET) || attacker.index == victim.index)
			{
				event.SetString("weapon", "sniperrifle");
				EmitSoundToAll(SuicideSound);
			}
		}
	}

	Call_OnPlayerDied(victim, attacker, event);
}
/**
 *	Whenever a player dies POST, this is called
*/
public void CheckLivingPlayers()
{
	if (gamemode.iRoundState < StateRunning || gamemode.iTimeLeft < 0)
		return;

	if (!gamemode.bOneGuardLeft)
	{
		if (GetLivingPlayers(BLU) == 1)
		{
			if (cvarTF2Jail[RemoveFreedayOnLastGuard].BoolValue)
			{
				JailFighter base;
				for (int i = MaxClients; i; --i)
				{
					if (!IsClientInGame(i))
						continue;

					base = JailFighter(i);
					if (base.bIsFreeday)
						base.RemoveFreeday();
				}
			}
			gamemode.bOneGuardLeft = true;

			Action action = Plugin_Continue;
			Call_OnLastGuard(action);

			if (action == Plugin_Continue)
				PrintCenterTextAll("One guard left...");

			else if (action == Plugin_Stop)
				return;	// Avoid multi-calls if necessary
		}
	}
	if (!gamemode.bOnePrisonerLeft)
	{
		if (GetLivingPlayers(RED) == 1)
		{
			gamemode.bOnePrisonerLeft = true;

			Action action = Plugin_Continue;
			Call_OnLastPrisoner(action);

			if (action == Plugin_Stop)
				return;
		}
	}
	Call_OnCheckLivingPlayers();
}
/**
 *	Determines if a player's attack is to be critical
*/
/*public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool & result)
{
	if (!bEnabled.BoolValue)
		return Plugin_Continue;

 	if (!IsClientValid(client))
 		return Plugin_Continue;

 	JailFighter base = JailFighter(client);
 	switch (gamemode.iLRType)
 	{ 	}
 	return Plugin_Continue;
}*/
/**
 *	Sticking this in Handler just in case someone wants to be incredibly specific with their lr 
*/
public void ManageEntityCreated(int ent, const char[] classname)
{
	if (StrContains(classname, "tf_ammo_pack", false) != -1)
		SDKHook(ent, SDKHook_Spawn, OnEntSpawn);

	if (cvarTF2Jail[KillPointServerCommand].BoolValue && StrContains(classname, "point_servercommand", false) != -1)
		RequestFrame(RemoveEnt, EntIndexToEntRef(ent));

	if (StrContains(classname, "rune") != - 1)	// oWo what's this?
		RequestFrame(RemoveEnt, EntIndexToEntRef(ent));
	
	if (cvarTF2Jail[DroppedWeapons].BoolValue && StrEqual(classname, "tf_dropped_weapon"))
		RequestFrame(RemoveEnt, EntIndexToEntRef(ent));

	if (StrEqual(classname, "func_breakable") && cvarTF2Jail[VentHit].BoolValue)
		RequestFrame(HookVent, EntIndexToEntRef(ent));
}
/**
 *	Self explanatory, set the gamemode.iTimeLeft to whatever time (in seconds) you desire
*/
public void ManageTimeLeft()
{
	switch (gamemode.iLRType)
	{
		default:gamemode.iTimeLeft = cvarTF2Jail[RoundTime].IntValue;
	}
	Call_OnManageTimeLeft();
}
/**
 *	Unique to the player Custom lr, formats the public char sCustomLR
*/
public void OnClientSayCommand_Post(int client, const char[] sCommand, const char[] cArgs)
{
	JailFighter base = JailFighter(client);
	if (base.iCustom > 0)
	{
		strcopy(strCustomLR, sizeof(strCustomLR), cArgs);
		CPrintToChat(client, "{crimson}[TF2Jail]{burlywood} Your custom last request is {fullred}%s", strCustomLR);
		base.iCustom = 0;
	}
}
/**
 *	Manage the warden menu applications
*/
public void ManageWardenMenu(Menu & menu)
{
	menu.AddItem("0", "Open Cells");
	menu.AddItem("1", "Close Cells");
	menu.AddItem("2", "Enable/Disable FF");
	menu.AddItem("3", "Enable/Disable Collisions");
	if (cvarTF2Jail[Markers].BoolValue)
		menu.AddItem("4", "Marker");
	if (cvarTF2Jail[WardenLaser].BoolValue)
		menu.AddItem("5", "Laser");

	Call_OnWMenuAdd(menu);
}
/**
 *	Handle warden menu selections
*/
 public int WardenMenuHandler(Menu menu, MenuAction action, int client, int select)
 {
 	if (!IsClientValid(client))
 		return;

 	if (!IsPlayerAlive(client))
 		return;

 	switch (action)
	{
		case MenuAction_Select:
		{
			JailFighter player = JailFighter(client);
			if (!player.bIsWarden)
			{
				CPrintToChat(client, "{crimson}[TF2Jail]{burlywood} You are not warden.");
				return;
			}
			char index[32]; menu.GetItem(select, index, sizeof(index));
			int val = StringToInt(index);
			switch (val)
			{
				case 0:
				{
					if (!gamemode.bCellsOpened)
					{
						gamemode.DoorHandler(OPEN);
						CPrintToChatAll("{crimson}[TF2Jail]{burlywood} Warden has opened cells.");
						gamemode.bCellsOpened = true;
					}
					else CPrintToChat(client, "{crimson}[TF2Jail]{burlywood} Cells are already open.");
					player.WardenMenu();
				}
				case 1:
				{
					if (gamemode.bCellsOpened)
					{
						gamemode.DoorHandler(CLOSE);
						CPrintToChatAll("{crimson}[TF2Jail]{burlywood} Warden has closed cells.");
						gamemode.bCellsOpened = false;
					}
					else CPrintToChat(client, "{crimson}[TF2Jail]{burlywood} Cells are not open.");
					player.WardenMenu();
				}
				case 2:
				{
					if (hEngineConVars[0].BoolValue == false)
					{
						hEngineConVars[0].SetBool(true);
						CPrintToChatAll("{crimson}[TF2Jail]{burlywood} Warden has enabled Friendly-Fire!");
					}
					else 
					{
						hEngineConVars[0].SetBool(false);
						CPrintToChatAll("{crimson}[TF2Jail]{burlywood} Warden has disabled Friendly-Fire.");
					}
					player.WardenMenu();
				}
				case 3:
				{
					if (hEngineConVars[1].BoolValue == false)
					{
						hEngineConVars[1].SetBool(true);
						CPrintToChatAll("{crimson}[TF2Jail]{burlywood} Warden has enabled collisions!");
					}
					else
					{
						hEngineConVars[1].SetBool(false);
						CPrintToChatAll("{crimson}[TF2Jail]{burlywood} Warden has disabled collisions.");
					}
					player.WardenMenu();
				}
				case 4:
				{
					if (cvarTF2Jail[Markers].BoolValue) 
					{
						if (gamemode.bMarkerExists)
						{
							CPrintToChat(client, "{crimson}[TF2Jail]{burlywood} Slow down there cowboy.");
							player.WardenMenu();
							return;
						}
						CreateMarker(client);
					}
					player.WardenMenu();
				}
				case 5:
				{
					if (cvarTF2Jail[WardenLaser].BoolValue)
					{
						if (player.bLasering)
						{
							player.bLasering = false;
							CPrintToChat(client, "{crimson}[TF2Jail]{burlywood} You have turned Warden Lasers {default}off{burlywood}.");
						}
						else
						{
							player.bLasering = true;
							CPrintToChat(client, "{crimson}[TF2Jail]{burlywood} You have turned Warden Lasers {default}on{burlywood}. Hold reload to activate.");
						}
					}
					player.WardenMenu();
				}
				default:Call_OnWMenuSelect(player, index);	// In case you set something wacky in the first AddItem() parameter
			}
		}
		case MenuAction_End:delete menu;
	}
 }
/** 
 *	This is all VSH stuff. Doing this to make more of a grasp with forwards
 *
 *	Since when can people build buildings? Oh wait map buildings
*/
public void ManageBuildingDestroyed(const JailFighter base, const int building, const int objecttype, Event event)
{
	switch (gamemode.iLRType) 
	{
		default: {	}
	}
	Call_OnBuildingDestroyed(base, building, event);
}
/**
 *	If airblast is disabled then leave this alone obviously
*/
public void ManageOnAirblast(const JailFighter airblaster, const JailFighter airblasted, Event event)
{
	switch (gamemode.iLRType) 
	{
		default: {  }
	}
	Call_OnObjectDeflected(airblasted, airblaster, event);
}
/**
 *	Calls when a player is wetted, kinky. Memes aside remember that this also called with Mad Milk and Sydney Sleeper headshots/charged shots
*/
public void ManageOnPlayerJarated(const JailFighter jarateer, const JailFighter jarateed, Event event)
{
	switch (gamemode.iLRType)
	{
		default: {	}
	}
	Call_OnPlayerJarated(jarateer, jarateed, event);
}
/**
 *	In my opinion mediguns shouldn't exist in JB, but hey do whatcha want
*/
public void ManageUberDeployed(const JailFighter patient, const JailFighter medic, Event event)
{
	switch (gamemode.iLRType)
	{
		default: {	}
	}
	Call_OnUberDeployed(patient, medic, event);
}
/**
 *	Music that can play during your LR, use the commented example as reference.
 *	If you add a song to any LR, you MUST return Plugin_Continue else the music won't work at all
*/
public Action ManageMusic(char song[PLATFORM_MAX_PATH], float & time)
{
	switch (gamemode.iLRType)
	{
		/* case example:
		{
			song = "SomeBadassSong.mp3";
			time = 9001.0;
			return Plugin_Continue;
		}*/
		default:return Call_OnPlayMusic(song, time);
	}
	return Plugin_Handled;
}
/**
 *	Manage what happens when the round time hits 0
 *	You can override the basic round end function which forces Blue to win by returning anything but Plugin_Continue
*/
public Action ManageTimeEnd()
{
	switch (gamemode.iLRType)
	{
		default:return Call_OnTimeEnd();
	}
	return Plugin_Continue;
}