class ScorpionSpawner : IdleDummy
{
	states
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("BrontornisRound", 1, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("BrontornisRound", -3,flags: SXF_NOCHECKPOSITION);
				let wpn = HDWeapon(Spawn('HDScorpion', pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}
				
				HDF.TransferSpecials(self, wpn);
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}

class HDScorpion : HDWeapon
{
	enum ScorpionProperties
	{
		SCRProp_Chamber,
		SCRProp_Mag,
		SCRProp_Heat,
		SCRProp_LoadType,
		SCRProp_Hand,
		SCRProp_Dot,
		SCRProp_Grime
	}

	override bool AddSpareWeapon(actor newowner) {return AddSpareWeaponRegular(newowner);}
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass()
	{
		double Extra = 1.5 * WeaponStatus[SCRProp_Mag] + (WeaponStatus[SCRProp_Chamber] == 2 ? 1.5 : 0);
		return 18 + Extra;
	}
	action void A_ChamberGrit(int amt,bool onlywhileempty=false){
		int ibg = invoker.weaponstatus[SCRProp_Grime];
		if(!onlywhileempty||invoker.weaponstatus[SCRProp_Chamber]<1)ibg+=amt;
		else if(!random(0,4))ibg++;
		invoker.weaponstatus[SCRProp_Grime]=clamp(ibg,0,100);
		A_Log(string.format("Scorpion grit level: %i",invoker.weaponstatus[SCRProp_Grime]));
	}
	int jamchance(){
		int jc=
		weaponstatus[SCRProp_Grime]
		+(weaponstatus[SCRProp_Heat]>>2)
		+weaponstatus[SCRProp_Chamber];
		return jc;
	}
	override double WeaponBulk()
	{
		return 200 + (WeaponStatus[SCRProp_Chamber] > 1 ? ENC_BRONTOSHELLLOADED : 0) + WeaponStatus[SCRProp_Mag] * ENC_BRONTOSHELLLOADED;
	}

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_SCORPION_PREFIX")..Stringtable.localize("$TAG_SCORPION")..Stringtable.localize("$PICKUP_SCORPION_SUFFIX");
	}

	override string, double GetPickupSprite()
	{
		return "SCRPZ0", 0.5;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[SCRProp_Chamber] = 2;
		WeaponStatus[SCRProp_Mag] = MaxMag;
		WeaponStatus[SCRProp_Heat] = 0;
	}
	override void LoadoutConfigure(string input)
	{
		WeaponStatus[SCRProp_Chamber] = 2;
		WeaponStatus[SCRProp_Mag] = MaxMag;
	}
	override void Tick()
	{
		Super.Tick();
		DrainHeat(SCRProp_Heat, 12);
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.HudLevel == 1)
		{
			sb.DrawImage("BROCA0", (-48, -10), sb.DI_SCREEN_CENTER_BOTTOM, scale: (0.7, 0.7));
			sb.DrawNum(hpl.CountInv("BrontornisRound"), -45, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}

		sb.DrawWepNum(hpl.CountInv("BrontornisRound"), (HDCONST_MAXPOCKETSPACE / ENC_BRONTOSHELL), posy: -2);

		int Chamber = hdw.WeaponStatus[SCRProp_Chamber];
		if (Chamber > 0)
		{
			sb.DrawRect(-16, -13, Chamber == 2 ? -5 : -2, 3);
		}

		for (int i = hdw.WeaponStatus[SCRProp_Mag]; i > 0; --i)
		{
			sb.drawrect(-15 - i * 5, -8, 4, 3);
		}
	}

	override string GetHelpText()
	{
		LocalizeHelp();
		return 
		LWPHELP_FIRESHOOT
		..LWPHELP_ALTFIRE..Stringtable.Localize("$SCRP_HELPTEXT_1")
		..LWPHELP_RELOAD..Stringtable.Localize("$SCRP_HELPTEXT_2")
		..LWPHELP_UNLOADUNLOAD;
	}

	override void SetReflexReticle(int which) { weaponstatus[SCRProp_Dot] = which; }

	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
			int cx,cy,cw,ch;
		[cx,cy,cw,ch]=Screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-64+bob.y,32,76,
			sb.DI_SCREEN_CENTER
		);
		sb.drawimage(
			"bsfrntsit",bob*1.14,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
		sb.SetClipRect(cx,cy,cw,ch);

		sb.drawimage(
			"bsbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9
		);

		if(scopeview){
			double degree=6.;
			int scaledwidth=89;
			int scaledyoffset=(scaledwidth>>1)+16;
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			sb.SetClipRect(
				bob.x-(scaledwidth>>1),bob.y+scaledyoffset-(scaledwidth>>1),
				scaledwidth,scaledwidth,
				sb.DI_SCREEN_CENTER
			);

			sb.fill(color(255,0,0,0),
				bob.x-44,scaledyoffset+bob.y-44,
				88,88,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);

			texman.setcameratotexture(hpc,"HDXCAM_BOSS",degree);
			let cam     = texman.CheckForTexture("HDXCAM_BOSS",TexMan.Type_Any);
			let reticle = texman.CheckForTexture("bossret1",TexMan.Type_Any);

			vector2 frontoffs=(0,scaledyoffset)+bob*3;

			double camSize  = texman.GetSize(cam);
			sb.DrawCircle(cam, frontoffs, 0.125,usePixelRatio:true);

			//[2022-09-17] there's a glitch in GZDoom where if the reticle would be drawn completely off screen,
			//the cliprect is ignored. The figure is a product of trial and error.
			if((bob.y/fov)<0.4){
				let reticleScale = camSize / texman.GetSize(reticle);
				if(hdw.weaponstatus[0]&BOSSF_FRONTRETICLE){
					sb.DrawCircle(reticle, frontoffs, .5*reticleScale, bob*(1/degree)*5-bob, 1.6*(1/degree));
				}else{
					sb.DrawCircle(reticle, (0,scaledyoffset)+bob, .5*reticleScale,uvScale:.5);
				}
			}

			//let holeScale    = camSize / texman.GetSize(hole);
			//let hole    = texman.CheckForTexture("scophole",TexMan.Type_Any);
			//sb.DrawCircle(hole, (0, scaledyoffset) + bob, .5 * holeScale, bob * 5, 1.5);


			screen.SetClipRect(cx,cy,cw,ch);

			sb.drawimage(
				"bossscope",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(1.24,1.24)
			);

		}
		// the scope display is in 10ths of an arcminute.
		// one dot = 6 arcminutes.
	}

	
	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			owner.A_DropInventory("BrontornisRound", 1);
		}
	}

	const MaxMag = 5;

	Default
	{
		Weapon.SelectionOrder 60;
		Weapon.SlotNumber 7;
		Weapon.SlotPriority 2;
		Weapon.Kickback 100;
		Weapon.BobRangeX 0.21;
		Weapon.BobRangeY 0.86;
		Scale 0.3;
		HDWeapon.BarrelSize 45, 1.4, 2;
		Tag "$TAG_SCORPION";
		HDWeapon.Refid HDLD_SCORPION;
	}

	States
	{
		Spawn:
			SCRP Z -1;
			Stop;
		Ready:
			SCRP A 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;
		Select0:
			SCRP A 0;
			Goto Select0BFG;
		Deselect0:
			SCRP A 0;
			Goto Deselect0BFG;
		User3:
			#### A 0 A_MagManager("PickupManager");
			Goto Ready;
		Fire:
			#### A 0
			{
				if (invoker.WeaponStatus[SCRProp_Chamber] < 2)
				{
					SetWeaponState("Nope");
					return;
				}
			}
			#### A 1 Offset(0, 34)
			{
				A_GiveInventory("IsMoving", GunBraced() ? 2 : 7);

				if (!bINVULNERABLE && (CountInv("IsMoving") > 6 || floorz < pos.z))
				{
					GiveBody(max(0, 11 - health));
					DamageMobj(invoker, self, 10, "bashing");
					A_GiveInventory("IsMoving", 5);
					A_ChangeVelocity(cos(pitch) * -frandom(2, 4), 0, sin(pitch) * frandom(2, 4), CVF_RELATIVE);
				}

				A_Overlay(PSP_FLASH, 'Flash');

				A_Light1();
				A_StartSound("Scorpion/Fire", CHAN_WEAPON);

				HDBulletActor.FireBullet(self, "HDB_bronto", speedfactor: 1.15);
				invoker.WeaponStatus[SCRProp_Chamber] = 1;
				invoker.WeaponStatus[SCRProp_Heat] += 32;
				invoker.WeaponStatus[SCRProp_Grime] += 10;
			}
			#### A 1
			{
				A_ZoomRecoil(0.5);
				A_Light0();
			}
			#### A 0
			{
				double RecoilSide = frandompick(-0.5, 0.5);
				double RecoilMult = 1.0;
				if (GunBraced())
				{
					HDPlayerPawn(self).gunbraced = false;
					A_ChangeVelocity(-frandom(0.4, 0.8)  * cos(pitch), 0, frandom(0.4, 0.8) * sin(pitch), CVF_RELATIVE);
					A_MuzzleClimb(RecoilSide * 0.5 * RecoilMult, -frandom(1.0, 1.2) * RecoilMult, RecoilSide * 0.5 * RecoilMult, -frandom(1.0, 1.2) * RecoilMult);
				}
				else
				{
					A_ChangeVelocity(-frandom(1.0, 1.6)  * cos(pitch), 0, frandom(1.0, 1.6) * sin(pitch), CVF_RELATIVE);
					A_MuzzleClimb(RecoilSide * RecoilMult, -frandom(1.0, 1.2) * RecoilMult, RecoilSide * RecoilMult, -frandom(1.0, 1.2) * RecoilMult);
					A_MuzzleClimb(RecoilSide * RecoilMult, -frandom(1.0, 1.2) * RecoilMult, RecoilSide * RecoilMult, -frandom(1.0, 1.2) * RecoilMult, wepdot: true);
					GiveBody (max(0,11-health));
					DamageMobJ (invoker, self, 10, "bashing");
				}
 			}
			Goto Nope;

		Flash:
			SCRP B 1 Bright
			{
				HDFlashAlpha(0, true);
			}
			goto lightdone;

		AltFire:
			#### A 1 Offset(0, 34) A_WeaponBusy();
			#### C 1 Offset(1, 35);
			#### D 1 Offset (2, 36) A_JumpIf(invoker.weaponstatus[BOSSS_CHAMBER]>2,"startjamderp");
			#### E 1 Offset(3, 37) A_MuzzleClimb(-frandom(0.06,0.1),-frandom(0.3,0.5));
			#### F 1 Offset(4, 38) A_ChamberGrit(randompick(0,0,1,1,2,3,4),true);
			#### G 0 A_Refire("chamber");
			goto ready;

		AltHold:
			SCRP E 1 A_WeaponReady(WRF_NOFIRE);
			#### E 1{
				A_ClearRefire();
				bool ChamberEmpty = invoker.WeaponStatus[SCRProp_Chamber]<1;
				if (PressingUnload())
				{
					if(ChamberEmpty)
					{
						return resolvestate("altholdclean");
					}
					else
					{
						invoker.WeaponStatus[SCRProp_LoadType] = 0;
						return resolvestate("loadchamber");
					}
				}
				else if(PressingReload())
				{
					if(!ChamberEmpty)
					{
						invoker.WeaponStatus[SCRProp_LoadType] = 0;
						return resolvestate("loadchamber");
					}
					else if (CheckInventory("BrontornisRound", 1))
					{
						invoker.WeaponStatus[SCRProp_LoadType] = 1;
						return resolvestate("loadchamber");
					}
				}

				if (PressingAltFire())
				{
					return ResolveState("AltHold");
				}

				return resolvestate("altholdend");
			}
		AltHoldEnd:
			#### H 2 A_StartSound("Scorpion/BoltFwd", 8);
			#### HGEDC 2;
			Goto Ready;
		Chamber:
			#### G 4 Offset(4, 38);
			#### G 3 Offset(6, 42)
			{
				A_StartSound("Scorpion/BoltBack", 8);
				if (GunBraced())
				{
					A_MuzzleClimb(frandom(-0.1, 0.3), frandom(-0.1, 0.3));
				}
				else
				{
					A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.4, 0.8));
				}
			}
			#### G 2 Offset(6, 42)
			{
				switch (invoker.WeaponStatus[SCRProp_Chamber])
				{
					case 2: A_SpawnItemEx("BrontornisRound", cos(pitch) * 2, 0, height - 10 - sin(pitch) * 2, vel.x, vel.y, vel.z - frandom(-1, 1), random(-3, 3), SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH | SXF_TRANSFERTRANSLATION); break;
					case 1: A_SpawnItemEx("TerrorCasing", cos(pitch) * 8, 1, height - 15 - sin(pitch) * 8, cos(pitch) * cos(angle - 80) * 6 + vel.x, cos(pitch) * sin(angle - 80) * 6 + vel.y, -sin(pitch) * 4 + vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH | SXF_TRANSFERTRANSLATION); break;
				}
				
				if (invoker.WeaponStatus[SCRProp_Mag] > 0)
				{  
					invoker.WeaponStatus[SCRProp_Chamber] = 2;
					invoker.WeaponStatus[SCRProp_Mag]--;
				}
				else
				{
					invoker.WeaponStatus[SCRProp_Chamber] = 0;
				}
			}
			#### H 2 Offset(7, 44);
			#### I 2 Offset(6, 46);
			#### I 1 Offset(5, 42);
			#### I 1 Offset(3, 38);
			#### I 1 Offset(1, 34);
			#### I 1 A_WeaponReady(WRF_NOFIRE);
			#### I 0 A_Refire("AltHold");
			Goto AltHoldEnd;

		LoadChamber:
			#### # 1 Offset(2, 36) A_ClearRefire();
			#### # 1 Offset(3, 38);
			#### # 1 Offset(5, 42);
			#### # 1 Offset(8, 48) A_StartSound("weapons/pocket", 9);
			#### # 1 Offset(9, 52) A_MuzzleClimb(frandom(-0.2, 0.2), 0.2, frandom(-0.2, 0.2),0.2, frandom(-0.2, 0.2), 0.2);
			#### # 1 Offset(8, 60);
			#### # 1 Offset(7, 72);
			#### # 1 Offset(6, 80);
			#### # 1 Offset(6, 88);
			TNT1 # 25;
			TNT1 # 4
			{
				A_StartSound("Scorpion/BossLoad", 8, volume: 0.7);
				switch (invoker.WeaponStatus[SCRProp_LoadType])
				{
					case 0:
						int Chamber = invoker.WeaponStatus[SCRProp_Chamber];
						invoker.WeaponStatus[SCRProp_Chamber] = 0;
						if (Chamber < 2 || A_JumpIfInventory("BrontornisRound", 0, "null"))
						{
							Class<actor> EjectClass = Chamber == 2 ? "BrontornisRound" : "TerrorCasing";
							actor rrr = Spawn(EjectClass, pos + (cos(angle) * 10, sin(angle) * 10,  height - 12), ALLOW_REPLACE);
							rrr.angle = angle;
							rrr.A_ChangeVelocity(1, 2, 1, CVF_RELATIVE);
						}
						else
						{
							HDF.Give(self, "BrontornisRound", 1);
						}
						A_ChamberGrit(randompick(0,0,0,0,-1,1),true);
						break;
					case 1:
						A_TakeInventory("BrontornisRound", 1, TIF_NOTAKEINFINITE);
						invoker.WeaponStatus[SCRProp_Chamber] = 2;
						break;
				}
			} 
			SCRP # 2 Offset(6, 80);
			#### # 2 Offset(7, 72);
			#### # 2 Offset(8, 60);
			#### # 1 Offset(7, 52);
			#### # 1 Offset(5, 42);
			#### # 1 Offset(3, 38);
			#### # 1 Offset(3, 35);
			Goto AltHold;
		AltHoldClean:
			SCRP E 1 offset(2,36) A_ClearRefire();
			#### E 1 offset(3,38);
			#### E 1 offset(5,41) A_Log(StringTable.Localize("$BOSS_CLEANS"),true);
			#### E 1 offset(8,44) A_StartSound("weapons/pocket",9);
			#### E 1 offset(7,50) A_MuzzleClimb(frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2,wepdot:false);
			TNT1 A 3 A_StartSound("weapons/pocket",10);
			TNT1 AAAA 4 A_MuzzleClimb(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),wepdot:false);
			TNT1 A 3 A_StartSound("weapons/pocket",9);
			TNT1 AAAA 4 A_MuzzleClimb(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),wepdot:false);
			TNT1 A 40{
				A_StartSound("weapons/pocket",9);
				int amt=invoker.weaponstatus[SCRProp_Grime];
				string amts=StringTable.Localize("$BOSS_CLEAN1");
				if(amt>80)amts=StringTable.Localize("$BOSS_CLEAN2");
				else if(amt>60)amts=StringTable.Localize("$BOSS_CLEAN3");
				else if(amt>40)amts=StringTable.Localize("$BOSS_CLEAN4");
				else if(amt>20)amts=StringTable.Localize("$BOSS_CLEAN5");

				/*static const */string cleanverbs[]={"$BOSS_EXTRACT","$BOSS_SCRAPEOFF","$BOSS_WIPEAWAY","$BOSS_CAREREMOVE","$BOSS_DUMPOUT","$BOSS_PICKOUT","$BOSS_BLOWOFF","$BOSS_SHAKEOUT","$BOSS_SCRUBOFF","$BOSS_FISH"};
				/*static const */string contaminants[]={"$BOSS_SOMEDUST","$BOSS_ALODUST","$BOSS_ABOPOWDER","$BOSS_DAOPOWDER","$BOSS_SEXGREASE","$BOSS_ALOSOOT","$BOSS_SOMEIRON","$BOSS_HAIR","$BOSS_EYELASH","$BOSS_BLOOD","$BOSS_RUST","$BOSS_CRUMB","$BOSS_DEADSOME","$BOSS_ASHES","$BOSS_SKIN","$BOSS_FLUID","$BOSS_WOWSOME","$BOSS_BOOGER","$BOSS_FECAL","$BOSS_BULLETSIMPACT","$BOSS_JAM","$BOSS_HUSK","$BOSS_SFLESH","$BOSS_CRYSTAL","$BOSS_SPACEANT","$BOSS_TRANSISTOR","$BOSS_TINBOSS","$BOSS_FILM"};
				/*static const */string actionparts[]={"$BOSS_BOLTCAR","$BOSS_MAINEXTRACTOR","$BOSS_AUXEXTRACTOR","$BOSS_CAMPIN","$BOSS_BOLTHEAD","$BOSS_STRIKER","$BOSS_SPRING","$BOSS_EJECTSLOT","$BOSS_STRIKERSPRING","$BOSS_EJSPRING"};
				for(int i=amt;i>0;i-=random(16,32))amts.appendformat(StringTable.Localize("$BOSS_FINLINE"),
					StringTable.Localize(cleanverbs[random(0,cleanverbs.size()-1)]),
					StringTable.Localize(contaminants[random(0,random(0,contaminants.size()-1))]),
					StringTable.Localize(actionparts[random(0,random((actionparts.size()>>1),actionparts.size()-1))])
				);
				amts=HDMath.BuildVariableString(amts);
				amts.appendformat("\n");

				amt=randompick(-3,-5,-5,-random(16,32));

				A_ChamberGrit(amt,true);
				amt=invoker.weaponstatus[SCRProp_Grime];
				if(amt>40)amts.appendformat(StringTable.Localize("$BOSS_CLENF1"));
				else if(amt>30)amts.appendformat(StringTable.Localize("$BOSS_CLENF2"));
				else if(amt>20)amts.appendformat(StringTable.Localize("$BOSS_CLENF3"));
				else if(amt>10)amts.appendformat(StringTable.Localize("$BOSS_CLENF4"));
				else amts.appendformat(StringTable.Localize("$BOSS_CLENF5"));
				A_Log(amts,true);
			}
			SCRP E 1 offset(7,52);
			#### E 1 offset(8,48);
			#### E 1 offset(5,42);
			#### E 1 offset(3,38);
			#### E 1 offset(2,36);
			goto althold;
		jam:
			SCRP A 0{
				int chm=invoker.weaponstatus[SCRProp_Chamber];
				if(chm<1)setweaponstate("chamber");
				else if(chm<3)invoker.weaponstatus[SCRProp_Chamber]+=2;
			}
		startjamderp:
			#### C 0 A_StartSound("Scorpion/RifleClick2",8,CHANF_OVERLAP);
			#### D 1 offset(0,34);
			#### E 2 offset(1,35);
			#### F 2 offset(3,37)A_MuzzleClimb(frandom(-0.5,0.6),frandom(-0.3,0.6));
			#### G 0 SetWeaponState("jamderp");

		jamderp:
			#### G 0 A_StartSound("Scorpion/RifleClick2",8,CHANF_OVERLAP);
			#### G 1 offset(0,34);
			#### G 2 offset(1,35);
			#### G 2 offset(3,37)A_MuzzleClimb(frandom(-0.5,0.6),frandom(-0.3,0.6));
			#### G 3 offset(4,38){
				A_MuzzleClimb(frandom(-0.5,0.6),frandom(-0.3,0.6));
				if(random(0,invoker.jamchance())<12){
					setweaponstate("chamber");
					if(invoker.weaponstatus[SCRProp_Chamber]>2)  
						invoker.weaponstatus[SCRProp_Chamber]-=2;
				}
			}
			#### G 2 offset(4,38);
			#### G 3 offset(2,36);
			#### G 0 A_Refire("jamderp");
			goto ready;
		Reload:
			#### A 0
			{
				if (invoker.WeaponStatus[SCRProp_Mag] == MaxMag)
				{
					SetWeaponState("ReloadDone");
				}
			}
			#### A 2 Offset(0, 34);
			#### A 2 Offset(2, 36);
			#### A 2 Offset(4, 40);
			#### A 4 Offset(8, 42)
			{
				A_StartSound("Scorpion/RifleClick2", 8, CHANF_OVERLAP, 0.9, pitch: 0.95);
				A_MuzzleClimb(-frandom(0.4, 0.8), frandom(0.4,  1.4));
			}
			#### A 8 Offset(14, 46)
			{
				A_StartSound("Scorpion/RifleLoad", 8, CHANF_OVERLAP);
				A_MuzzleClimb(-frandom(0.4, 0.8), frandom(0.4, 1.4));
			}
		LoadHand:
			#### A 0 A_JumpIfInventory("BrontornisRound", 1, "LoadHandLoop");
			Goto ReloadDone;
		LoadHandLoop:
			#### A 4
			{
				if (!CheckInventory("BrontornisRound", 1) || invoker.WeaponStatus[SCRProp_Mag] == MaxMag)
				{
					SetWeaponState("ReloadDone");
					return;
				}
				A_TakeInventory("BrontornisRound", 1, TIF_NOTAKEINFINITE);
				invoker.WeaponStatus[SCRProp_Hand] = 1;
				A_StartSound("weapons/pocket", 9);
			}
		LoadOne:
			#### A 5 Offset(16, 50) A_JumpIf(invoker.WeaponStatus[SCRProp_Hand] < 1, "LoadHandNext");
			#### A 7 Offset(14, 46)
			{
				invoker.WeaponStatus[SCRProp_Hand]--;
				invoker.WeaponStatus[SCRProp_Mag]++;
				A_StartSound("Scorpion/RifleClick2", 8);
			}
			Loop;
		LoadHandNext:
			#### A 16 Offset(16, 48)
			{
				if (PressingReload() || PressingFire() || PressingAltFire() || PressingZoom() || !CheckInventory("BrontornisRound", 1))
				{
					SetWeaponState("ReloadDone");
					return;
				}
			}
			Goto LoadHandLoop;
		ReloadDone:
			#### A 1 Offset(4, 40);
			#### A 1 Offset(2, 36);
			#### A 1 Offset(0, 34);
			Goto nope;
		Unload:
			#### A 0
			{
				if (invoker.WeaponStatus[SCRProp_Mag] < 1)
				{
					SetWeaponState("Nope");
				}
			}
			#### A 1 Offset(0, 34);
			#### A 1 Offset(2, 36);
			#### A 1 Offset(4, 40);
			#### A 2 Offset(8, 42)
			{
				A_MuzzleClimb(-frandom(0.4, 0.8),frandom(0.4, 1.4));
				A_StartSound("Scorpion/RifleClick2", 8);
			}
			#### A 4 Offset (14, 46){

				A_MuzzleClimb(-frandom(0.4, 0.8), frandom(0.4,  1.4));
				A_StartSound("Scorpion/RifleLoad", 8);
			}
		UnloadLoop:
			#### A 12 Offset(3, 41)
			{
				if (invoker.WeaponStatus[SCRProp_Mag] < 1)
				{
					SetWeaponState("UnloadDone");
					return;
				}
				A_StartSound("Scorpion/RifleClick2", 8);
				invoker.WeaponStatus[SCRProp_Mag]--;

				if (A_JumpIfInventory("BrontornisRound", 0, "null"))
				{
					A_SpawnItemEx("BrontornisRound", cos(pitch) * 2, 0, height - 10 - sin(pitch) * 2, vel.x, vel.y, vel.z - frandom(-1, 1), random(-3, 3), SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH | SXF_TRANSFERTRANSLATION);
				}
				else
				{
					A_GiveInventory("BrontornisRound", 1);
				}
			}
			#### A 4 Offset(2, 42);
			#### A 0
			{
				if (PressingReload() || PressingFire() || PressingAltFire() || PressingZoom() || !CheckInventory("BrontornisRound", 1))
				{
					SetWeaponState("UnloadDone");
				}
			}
			Loop;
		UnloadDone:
			#### A 2 Offset(2, 42);
			#### A 3 Offset(3, 41);
			#### A 1 Offset(4, 40) A_StartSound("Scorpion/RifleClick", 8);
			#### A 1 Offset(2, 36);
			#### A 1 Offset(0, 34);
			Goto ready;
	}
}
