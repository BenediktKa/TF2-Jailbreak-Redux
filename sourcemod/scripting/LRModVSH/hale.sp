//defines

//models
// #define HaleModel		"models/player/saxton_hale/saxton_hale.mdl"
// #define HaleModelPrefix		"models/player/saxton_hale/saxton_hale"
#define HaleModel				"models/player/saxton_test4/saxton_hale_test4.mdl"

//materials
static const char HaleMatsV2[][] = {
	"materials/models/player/saxton_test4/eyeball_l.vmt",
	"materials/models/player/saxton_test4/eyeball_r.vmt",
	"materials/models/player/saxton_test4/halebody.vmt",
	"materials/models/player/saxton_test4/halebody.vtf",
	"materials/models/player/saxton_test4/halebodyexponent.vtf",
	"materials/models/player/saxton_test4/halehead.vmt",
	"materials/models/player/saxton_test4/halehead.vtf",
	"materials/models/player/saxton_test4/haleheadexponent.vtf",
	"materials/models/player/saxton_test4/halenormal.vtf",
	"materials/models/player/saxton_test4/halephongmask.vtf"
	//"materials/models/player/saxton_test4/halegibs.vmt",
	//"materials/models/player/saxton_test4/halegibs.vtf"
};


//Saxton Hale voicelines
#define HaleComicArmsFallSound	"saxton_hale/saxton_hale_responce_2.wav"
#define HaleLastB		"vo/announcer_am_lastmanalive"
#define HaleKSpree		"saxton_hale/saxton_hale_responce_3.wav"
#define HaleKSpree2		"saxton_hale/saxton_hale_responce_4.wav"	//this line is broken and unused
#define HaleRoundStart		"saxton_hale/saxton_hale_responce_start" //1-5
#define HaleJump		"saxton_hale/saxton_hale_responce_jump"			//1-2
#define HaleRageSound		"saxton_hale/saxton_hale_responce_rage"		   //1-4
#define HaleKillMedic		"saxton_hale/saxton_hale_responce_kill_medic.wav"
#define HaleKillSniper1		"saxton_hale/saxton_hale_responce_kill_sniper1.wav"
#define HaleKillSniper2		"saxton_hale/saxton_hale_responce_kill_sniper2.wav"
#define HaleKillSpy1		"saxton_hale/saxton_hale_responce_kill_spy1.wav"
#define HaleKillSpy2		"saxton_hale/saxton_hale_responce_kill_spy2.wav"
#define HaleKillEngie1		"saxton_hale/saxton_hale_responce_kill_eggineer1.wav"
#define HaleKillEngie2		"saxton_hale/saxton_hale_responce_kill_eggineer2.wav"
#define HaleKSpreeNew		"saxton_hale/saxton_hale_responce_spree"  //1-5
#define HaleWin			"saxton_hale/saxton_hale_responce_win"		  //1-2
#define HaleLastMan		"saxton_hale/saxton_hale_responce_lastman"  //1-5
#define HaleFail		"saxton_hale/saxton_hale_responce_fail"			//1-3
#define HaleJump132		"saxton_hale/saxton_hale_132_jump_" //1-2
#define HaleStart132		"saxton_hale/saxton_hale_132_start_"   //1-5
#define HaleKillDemo132		"saxton_hale/saxton_hale_132_kill_demo.wav"
#define HaleKillEngie132	"saxton_hale/saxton_hale_132_kill_engie_" //1-2
#define HaleKillHeavy132	"saxton_hale/saxton_hale_132_kill_heavy.wav"
#define HaleKillScout132	"saxton_hale/saxton_hale_132_kill_scout.wav"
#define HaleKillSpy132		"saxton_hale/saxton_hale_132_kill_spie.wav"
#define HaleKillPyro132		"saxton_hale/saxton_hale_132_kill_w_and_m1.wav"
#define HaleSappinMahSentry132	"saxton_hale/saxton_hale_132_kill_toy.wav"
#define HaleKillKSpree132	"saxton_hale/saxton_hale_132_kspree_"	//1-2
#define HaleKillLast132		"saxton_hale/saxton_hale_132_last.wav"
#define HaleStubbed132		"saxton_hale/saxton_hale_132_stub_"  //1-4

#define HALESPEED		340.0

#define HALE_JUMPCHARGE		(25*1.0)
#define HALERAGEDIST		800.0
#define HALE_WEIGHDOWN_TIME	3.0


methodmap CHale < JailBoss
{
	public CHale(const int ind, bool uid = false)
	{
		if (uid)
			return view_as<CHale>( JailBoss(ind, true) );
		return view_as<CHale>( JailBoss(ind) );
	}

	public void PlaySpawnClip()
	{
		Format(snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleRoundStart, GetRandomInt(1, 10));
		EmitSoundToAll(snd);
	}

	public void Think ()
	{
		this.DoGenericThink();
		int buttons = GetClientButtons(this.index);

		if ( ((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && (this.flCharge >= 0.0) )
		{
			if (this.flCharge+2.5 < HALE_JUMPCHARGE)
				this.flCharge += 1.25;
			else this.flCharge = HALE_JUMPCHARGE;
		}
		else if (this.flCharge < 0.0)
			this.flCharge += 1.25;
		else {
			float EyeAngles[3]; GetClientEyeAngles(this.index, EyeAngles);
			if ( this.flCharge > 1.0 && EyeAngles[0] < -5.0 ) {
				float vel[3]; GetEntPropVector(this.index, Prop_Data, "m_vecVelocity", vel);
				vel[2] = 750 + this.flCharge * 13.0;

				SetEntProp(this.index, Prop_Send, "m_bJumping", 1);
				vel[0] *= (1+Sine(this.flCharge * FLOAT_PI / 50));
				vel[1] *= (1+Sine(this.flCharge * FLOAT_PI / 50));
				TeleportEntity(this.index, nullvec, nullvec, vel);
				this.flCharge = -100.0;
				Format(snd, PLATFORM_MAX_PATH, "%s%i.wav", GetRandomInt(0, 1) ? HaleJump : HaleJump132, GetRandomInt(1, 2));
				
				EmitSoundToAll(snd, this.index);
				EmitSoundToAll(snd, this.index);
			}
			else this.flCharge = 0.0;
		}
	}
	public void SetModel ()
	{
		SetVariantString(HaleModel);
		AcceptEntityInput(this.index, "SetCustomModel");
		SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		//SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.25);
	}

	public void Death ()
	{
		Format(snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleFail, GetRandomInt(1, 3));
		EmitSoundToAll(snd);
	}

	public void Equip ()
	{
		this.PreEquip();
		char attribs[128];

		Format(attribs, sizeof(attribs), "68 ; 2.0 ; 2 ; 3.1 ; 259 ; 1.0 ; 252 ; 0.6 ; 214 ; %d", GetRandomInt(999, 9999));
		int SaxtonWeapon = this.SpawnWeapon("tf_weapon_shovel", 5, 100, 5, attribs);
		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
	}
	public void RageAbility()
	{
		TF2_AddCondition(this.index, view_as<TFCond>(42), 4.0);
		if ( !GetEntProp(this.index, Prop_Send, "m_bIsReadyToHighFive")
			&& !IsValidEntity(GetEntPropEnt(this.index, Prop_Send, "m_hHighFivePartner")) )
		{
			TF2_RemoveCondition(this.index, TFCond_Taunting);
			this.SetModel(); //MakeModelTimer(null); // should reset Hale's animation
		}

		this.DoGenericStun(HALERAGEDIST);

		Format(snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleRageSound, GetRandomInt(1, 4));
		EmitSoundToAll(snd, this.index); EmitSoundToAll(snd, this.index);
	}
	
	public void KilledPlayer(const JailBoss victim, Event event)
	{
		event.SetString("weapon", "fists");
		if( !GetRandomInt(0, 2) ) {
			TFClassType playerclass = TF2_GetPlayerClass(victim.index);
			switch( playerclass ) {
				case TFClass_Scout:	strcopy(snd, PLATFORM_MAX_PATH, HaleKillScout132);
				case TFClass_Pyro:	strcopy(snd, PLATFORM_MAX_PATH, HaleKillPyro132);
				case TFClass_DemoMan:	strcopy(snd, PLATFORM_MAX_PATH, HaleKillDemo132);
				case TFClass_Heavy:	strcopy(snd, PLATFORM_MAX_PATH, HaleKillHeavy132);
				case TFClass_Medic:	strcopy(snd, PLATFORM_MAX_PATH, HaleKillMedic);
				case TFClass_Sniper: {
					if( GetRandomInt(0, 1) )
						strcopy(snd, PLATFORM_MAX_PATH, HaleKillSniper1);
					else strcopy(snd, PLATFORM_MAX_PATH, HaleKillSniper2);
				}
				case TFClass_Spy: {
					int see = GetRandomInt(0, 2);
					if( see )
						strcopy(snd, PLATFORM_MAX_PATH, HaleKillSpy1);
					else if( see == 1 )
						strcopy(snd, PLATFORM_MAX_PATH, HaleKillSpy2);
					else strcopy(snd, PLATFORM_MAX_PATH, HaleKillSpy132);
				}
				case TFClass_Engineer: {
					int see = GetRandomInt(0, 3);
					if( !see )
						strcopy(snd, PLATFORM_MAX_PATH, HaleKillEngie1);
					else if( see == 1 )
						strcopy(snd, PLATFORM_MAX_PATH, HaleKillEngie2);
					else Format(snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillEngie132, GetRandomInt(1, 2));
				}
			}
			EmitSoundToAll(snd, this.index); EmitSoundToAll(snd, this.index);
		}

		float curtime = GetGameTime();
		if( curtime <= this.flKillSpree )
			this.iKills++;
		else this.iKills = 0;

		if( this.iKills == 3 && GetLivingPlayers(RED) != 1 ) {
			int randsound = GetRandomInt(0, 7);
			if( !randsound || randsound == 1 )
				strcopy(snd, PLATFORM_MAX_PATH, HaleKSpree);
			else if( randsound < 5 && randsound > 1 )
				Format(snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, GetRandomInt(1, 5));
			else Format(snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, GetRandomInt(1, 2));
			EmitSoundToAll(snd, this.index); EmitSoundToAll(snd, this.index);
			this.iKills = 0;
		}
		else this.flKillSpree = curtime+5;
	}
	public void Help()
	{
		if ( IsVoteInProgress() )
			return ;
		char helpstr[] = "Saxton Hale:\nSuper Jump: Right-click, look up, and release.\nWeigh-down: After 3 seconds in midair, look down and hold crouch\nRage (stun): Call for medic (e) when the Rage is full to stun nearby enemies.";
		Panel panel = new Panel();
		panel.SetTitle (helpstr);
		panel.DrawItem( "Exit" );
		panel.Send(this.index, HintPanel, 10);
		delete (panel);
	}
	public void LastPlayerSoundClip()
	{
		switch( GetRandomInt(0, 5) ) {
			case 0: strcopy(snd, PLATFORM_MAX_PATH, HaleComicArmsFallSound);
			case 1: Format(snd, PLATFORM_MAX_PATH, "%s0%i.wav", HaleLastB, GetRandomInt(1, 4));
			case 2: strcopy(snd, PLATFORM_MAX_PATH, HaleKillLast132);
			default: Format(snd, PLATFORM_MAX_PATH, "%s%i.wav", HaleLastMan, GetRandomInt(1, 5));
		}
		EmitSoundToAll(snd);
	}
};

public CHale ToCHale (const JailBoss guy)
{
	return view_as< CHale >(guy);
}

public void AddHaleToDownloads()
{
	char s[PLATFORM_MAX_PATH];
	int i;
	
	PrepareModel(HaleModel);
	DownloadMaterialList(HaleMatsV2, sizeof(HaleMatsV2));

	PrepareSound(HaleComicArmsFallSound);
	PrepareSound(HaleKSpree);
	
	for( i=1 ; i <= 4 ; i++ ) {
		Format(s, PLATFORM_MAX_PATH, "%s0%i.wav", HaleLastB, i);
		PrecacheSound(s, true);
	}

	PrepareSound(HaleKillMedic);
	PrepareSound(HaleKillSniper1);
	PrepareSound(HaleKillSniper2);
	PrepareSound(HaleKillSpy1);
	PrepareSound(HaleKillSpy2);
	PrepareSound(HaleKillEngie1);
	PrepareSound(HaleKillEngie2);
	PrepareSound(HaleKillDemo132);
	PrepareSound(HaleKillHeavy132);
	PrepareSound(HaleKillScout132);
	PrepareSound(HaleKillSpy132);
	PrepareSound(HaleKillPyro132);
	PrepareSound(HaleKillDemo132);
	PrepareSound(HaleKillDemo132);
	PrepareSound(HaleKillDemo132);
	PrepareSound(HaleKillDemo132);
	PrepareSound(HaleKillDemo132);
	PrepareSound(HaleSappinMahSentry132);
	PrepareSound(HaleKillLast132);
	
	for( i=1 ; i <= 5 ; i++ ) {
		if( i <= 2 ) {
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump, i);
			PrepareSound(s);

			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleWin, i);
			PrepareSound(s);

			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleJump132, i);
			PrepareSound(s);

			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillEngie132, i);
			PrepareSound(s);

			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKillKSpree132, i);
			PrepareSound(s);
		}
		if( i <= 3 ) {
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleFail, i);
			PrepareSound(s);
		}

		if( i <= 4 ) {
			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRageSound, i);
			PrepareSound(s);

			Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStubbed132, i);
			PrepareSound(s);
		}

		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleRoundStart, i);
		PrepareSound(s);

		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleKSpreeNew, i);
		PrepareSound(s);

		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleLastMan, i);
		PrepareSound(s);

		Format(s, PLATFORM_MAX_PATH, "%s%i.wav", HaleStart132, i);
		PrepareSound(s);
	}
}

public void AddHaleToMenu ( Menu& menu )
{
	menu.AddItem("0", "Saxton Hale");
}

public void EnableSG(const int iid)
{
	int i = EntRefToEntIndex(iid);
	if (IsValidEdict(i) && i > MaxClients)
	{
		char s[32]; GetEdictClassname(i, s, sizeof(s));
		if ( StrEqual(s, "obj_sentrygun") ) {
			SetEntProp(i, Prop_Send, "m_bDisabled", 0);
			int higher = MaxClients+1;
			for (int ent=2048 ; ent>higher ; --ent) {
				if (!IsValidEdict(ent) || ent <= 0)
					continue;

				char s2[32]; GetEdictClassname(ent, s2, sizeof(s2));
				if (StrEqual(s2, "info_particle_system") && GetOwner(ent) == i)
					AcceptEntityInput(ent, "Kill");
			}
		}
	}
}
