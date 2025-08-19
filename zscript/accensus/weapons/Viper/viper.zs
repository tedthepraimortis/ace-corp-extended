class HDViper : HDHandgun
{
	enum ViperFlags
	{
		VPF_JustUnload = 1,
		VPF_LightTrigger = 2,
		VPF_HeavyFrame = 4,
		VPF_ExtendedBarrel = 8
	}

	enum ViperProperties
	{
		VPProp_Flags,
		VPProp_Chamber,
		VPProp_Mag,
	}

	override void Tick()
	{
		if (WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel)
		{
			BarrelLength = default.BarrelLength + 4;
		}

		Super.Tick();
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner , bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }

	override double GunMass()
	{
		double BaseMass = 10.5;
		if (WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel)
		{
			BaseMass += 1.5;
		}
		if (WeaponStatus[VPProp_Flags] & VPF_HeavyFrame)
		{
			BaseMass *= 1.1;
		}
		return BaseMass;
	}

	override double WeaponBulk()
	{
		double BaseBulk = 85;
		int Mag = WeaponStatus[VPProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += HDViperMag.EncMagLoaded + Mag * ENC_50AM_LOADED;
		}
		if (WeaponStatus[VPProp_Flags] & VPF_LightTrigger)
		{
			BaseBulk -= 2;
		}
		if (WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel)
		{
			BaseBulk += 15;
		}
		if (WeaponStatus[VPProp_Flags] & VPF_HeavyFrame)
		{
			BaseBulk *= 1.20;
		}
		return BaseBulk;
	}

	override string, double GetPickupSprite()
	{
		string IconString = "";
		if (WeaponStatus[VPProp_Chamber] > 0)
		{
			IconString = WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel ? "VPRXY0" : "VPRGY0";
		}
		else
		{
			IconString = WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel ? "VPRXZ0" : "VPRGZ0";
		}
		return IconString, 1.0;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[VPProp_Chamber] = 2;
		WeaponStatus[VPProp_Mag] = 7;
	}

	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "trigger", 1) > 0)
		{
			WeaponStatus[VPProp_Flags] |= VPF_LightTrigger;
		}
		if (GetLoadoutVar(input, "hframe", 1) > 0)
		{
			WeaponStatus[VPProp_Flags] |= VPF_HeavyFrame;
		}
		if (GetLoadoutVar(input, "extended", 1) > 0)
		{
			WeaponStatus[VPProp_Flags] |= VPF_ExtendedBarrel;
		}

		InitializeWepStats();
	}

	override void ForceBasicAmmo()
	{
		owner.A_TakeInventory("HD50AM_Ammo");
		owner.A_TakeInventory("HDViperMag");
		owner.A_GiveInventory("HDViperMag");
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory("HD50AM_Ammo", 1))
			{
				owner.A_DropInventory("HD50AM_Ammo", amt * 10);
			}
			else
			{
				owner.A_DropInventory("HDViperMag", amt);
			}
		}
	}

	override string GetHelpText()
	{
		LocalizeHelp();
		return 
		LWPHELP_FIRESHOOT
		..LWPHELP_ALTRELOAD.."/"..LWPHELP_FIREMODE..Stringtable.Localize("$VPR_HELPTEXT_1")
		..LWPHELP_RELOAD..Stringtable.Localize("$VPR_HELPTEXT_2")
		..LWPHELP_USE.."+"..LWPHELP_RELOAD..Stringtable.Localize("$VPR_HELPTEXT_3")
		..LWPHELP_MAGMANAGER
		..LWPHELP_UNLOADUNLOAD;
	}

	override string PickupMessage()
	{
		string HFrameStr = WeaponStatus[VPProp_Flags] & VPF_HeavyFrame ? Stringtable.localize("$PICKUP_VIPER_HEAVYFRAME") : "";
		string ExBarrelStr = WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel ? Stringtable.localize("$PICKUP_VIPER_EXTENDEDBARREL") : "";
		string LTriggerStr = WeaponStatus[VPProp_Flags] & VPF_LightTrigger ? Stringtable.Localize("$PICKUP_VIPER_LIGHTTRIGGER") : "";

		return Stringtable.localize("$PICKUP_VIPER_PREFIX")..HFrameStr..ExBarrelStr..LTriggerStr..Stringtable.localize("$TAG_VIPER")..Stringtable.localize("$PICKUP_VIPER_SUFFIX");
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDViperMag")));
			if (NextMagLoaded >= 7)
			{
				sb.DrawImage("VPMGA0", (-46, -3),sb. DI_SCREEN_CENTER_BOTTOM, scale: (2.0, 2.0));
			}
			else if (NextMagLoaded <= 0)
			{
				sb.DrawImage("VPMGB0", (-46, -3), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLoaded ? 0.6 : 1.0, scale: (2.0, 2.0));
			}
			else
			{
				sb.DrawBar("VPMGNORM", "VPMGGREY", NextMagLoaded, 7, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv("HDViperMag"), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.DrawWepNum(hdw.WeaponStatus[VPProp_Mag], 7);

		if(hdw.WeaponStatus[VPProp_Chamber] == 2)
		{
			sb.DrawRect(-19, -11, 3, 1);
		}
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 13, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 1.3;
		//bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("VIPRFRNT", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.8, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("VIPRBACK", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.9, 0.7));
	}

	private action void A_UpdateSlideFrame()
	{
		let psp = player.GetPSprite(PSP_WEAPON);
		psp.frame = invoker.WeaponStatus[VPProp_Chamber] == 0 ? 2 : 0;
	}

	private action void A_UpdateReloadSprite()
	{
		let psp = player.GetPSprite(PSP_WEAPON);
		psp.sprite = GetSpriteIndex(invoker.WeaponStatus[VPProp_Chamber] == 0 ? "VPRE" : "VPRR");
	}


	Default
	{
		+WEAPON.NOAUTOFIRE
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 2;
		Weapon.SlotPriority 4;
		HDWeapon.BarrelSize 13, 0.35, 0.5;
		Scale 0.5;
		Tag "$TAG_VIPER";
		HDWeapon.Refid HDLD_VIPER;
		HDWeapon.loadoutcodes "
			\cuhframe - 0/1, Trades weight for lessened recoil.
			\cuextended - 0/1, Higher projectile velocity but heavier gun.
			\cutrigger - 0/1, Lighter Trigger";
	}

	States
	{
		RegisterSprites:
			VPRR A 0; VPRE A 0;

		Spawn:
			VPRX Y 0 NoDelay A_JumpIf(invoker.WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel, 2);
			VPRG Y 0;
			#### # -1
			{
				frame = (invoker.WeaponStatus[VPProp_Chamber] == 0 ? 25 : 24);
			}
			Stop;
		Ready:
			VPRG A 1
			{
				A_UpdateSlideFrame();
				A_WeaponReady(WRF_ALL);
			}
			Goto ReadyEnd;
		Select0:
			VPRG A 0 A_UpdateSlideFrame();
			Goto Select0Small;
		Deselect0:
			VPRG A 0 A_UpdateSlideFrame();
			Goto Deselect0Small;
		User3:
			#### A 0 A_MagManager("HDViperMag");
			Goto Ready;

		Fire:
			#### # 0
			{
				if (invoker.WeaponStatus[VPProp_Chamber] == 2)
				{
					SetWeaponState("Shoot");
				}
				else if (invoker.WeaponStatus[VPProp_Mag] > 0)
				{
					SetWeaponState("ChamberManual");
				}
			}
			Goto Nope;
		Shoot:
			#### B 1
			{
				if (HDPlayerPawn(self))
				{
					HDPlayerPawn(self).gunbraced = false;
				}
			}
			#### B 1 Offset(0, 36)
			{
				A_Overlay(PSP_FLASH, 'Flash');
				A_Light1();
				A_StartSound("Viper/Fire", CHAN_WEAPON);

				bool ExtBarrel = invoker.WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel;

				double VelMult = 1.0;
				if (ExtBarrel)
				{
					VelMult += 0.15;
				}
				HDBulletActor.FireBullet(self, "HDB_50AM", spread: 1.0, speedfactor: frandom(0.99, 1.03) * VelMult);
				A_AlertMonsters();
				A_ZoomRecoil(1.05);

				double ClimbMult = 1.0;
				if (invoker.WeaponStatus[VPProp_Flags] & VPF_LightTrigger)
				{
					ClimbMult -= 0.5;
				}
				if (ExtBarrel)
				{
					ClimbMult -= 0.12;
				}
				if (invoker.WeaponStatus[VPProp_Flags] & VPF_HeavyFrame)
				{
					ClimbMult *= 0.75;
				}
				A_MuzzleClimb(-frandom(0.9, 2.8) * ClimbMult, -frandom(5.0, 7.0) * ClimbMult);

				invoker.WeaponStatus[VPProp_Chamber] = 1;
			}
			#### C 1 Offset(0, 44)
			{
				if (invoker.WeaponStatus[VPProp_Chamber] == 1)
				{
					A_EjectCasing('HDSpent50AM',frandom(-1,2),(frandom(0.2,0.3),-frandom(7,7.5),frandom(0,0.2)),(0,0,-2));
					invoker.WeaponStatus[VPProp_Chamber] = 0;
				}
				
				if (invoker.WeaponStatus[VPProp_Mag] <= 0)
				{
					A_StartSound("weapons/pistoldry", 8, CHANF_OVERLAP, 0.9);
					SetWeaponState("Nope");
				}
				else
				{
					A_Light0();
					invoker.WeaponStatus[VPProp_Chamber] = 2;
					invoker.WeaponStatus[VPProp_Mag]--;
					A_Refire();
				}
			}
			Goto Ready;
		Hold:
			Goto Nope;

		Flash:
			VPRF A 0 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;

		Reload:
			#### # 0
			{
				invoker.WeaponStatus[VPProp_Flags] &=~ VPF_JustUnload;
				bool noMags = HDMagAmmo.NothingLoaded(self, 'HDViperMag');
				if (invoker.WeaponStatus[VPProp_Mag] >= 7)
				{
					SetWeaponState('Nope');
				}
				else if (invoker.WeaponStatus[VPProp_Mag] <= 0 && (PressingUse() || noMags))
				{
					if (CheckInventory('HD50AM_Ammo', 1))
					{
						SetWeaponState('LoadChamber');
					}
					else
					{
						SetWeaponState('Nope');
					}
				}
				else if (noMags)
				{
					SetWeaponState('Nope');
				}
			}
			Goto RemoveMag;

		Unload:
			#### # 0
			{
				invoker.WeaponStatus[VPProp_Flags] |= VPF_JustUnload;
				if (invoker.WeaponStatus[VPProp_Mag] >= 0)
				{
					SetWeaponState('RemoveMag');
				}
				else if (invoker.WeaponStatus[VPProp_Chamber] > 0)
				{
					SetWeaponState('ChamberManual');
				}
			}
			Goto Nope;
		RemoveMag:
			#### # 2 Offset(0, 34) A_SetCrosshair(21);
			#### # 2 Offset(1, 38);
			#### # 3 Offset(2, 42);
			#### # 4 Offset(3, 46) A_StartSound("Viper/MagOut", 8, CHANF_OVERLAP);
			#### # 0
			{
				int Mag = invoker.WeaponStatus[VPProp_Mag];
				invoker.WeaponStatus[VPProp_Mag] = -1;
				if (Mag == -1)
				{
					SetWeaponState("MagOut");
				}
				else if((!PressingUnload() && !PressingReload()) || A_JumpIfInventory("HDViperMag", 0, "null"))
				{
					HDMagAmmo.SpawnMag(self, "HDViperMag", Mag);
					setweaponstate("MagOut");
				}
				else{
					HDMagAmmo.GiveMag(self, "HDViperMag", Mag);
					A_StartSound("weapons/pocket", 9);
					setweaponstate("PocketMag");
				}
			}
		PocketMag:
			#### ### 6 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			Goto MagOut;
		MagOut:
			#### # 0
			{
				if (invoker.WeaponStatus[VPProp_Flags] & VPF_JustUnload)
				{
					SetWeaponState("ReloadEnd");
				}
				else
				{
					SetWeaponState("LoadMag");
				}
			}
		LoadMag:
			#### # 5 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 0 A_StartSound("weapons/pocket", 9);
			#### # 6 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 4;
			#### # 0
			{
				let Mag = HDMagAmmo(FindInventory("HDViperMag"));
				if (Mag)
				{
					invoker.WeaponStatus[VPProp_Mag] = mag.TakeMag(true);
					A_StartSound("Viper/MagIn", 8);
				}
			}
			Goto ReloadEnd;
		ReloadEnd:
			#### # 3 Offset(3, 46);
			#### # 2 Offset(2, 42);
			#### # 2 Offset(2, 38);
			#### # 1 Offset(1, 34);
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[VPProp_Flags] & VPF_JustUnload), "ChamberManual");
			Goto Nope;

		ChamberManual:
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[VPProp_Flags] & VPF_JustUnload) && (invoker.WeaponStatus[VPProp_Chamber] == 2 || invoker.WeaponStatus[VPProp_Mag] <= 0), "Nope");
			#### # 5 Offset(0, 34);
			#### C 6 Offset(0, 37)
			{
				if (invoker.WeaponStatus[VPProp_Chamber] > 0)
				{
					A_MuzzleClimb(frandom(0.4, 0.5), -frandom(0.6, 0.8));
					A_StartSound("Viper/SlideBack", 8);
					int chamber = invoker.WeaponStatus[VPProp_Chamber];
					invoker.WeaponStatus[VPProp_Chamber] = 0;
					switch (Chamber)
					{
						case 1: A_EjectCasing('HDSpent50AM',frandom(-1,2),(frandom(0.2,0.3),-frandom(7,7.5),frandom(0,0.2)),(0,0,-2));
						case 2: A_SpawnItemEx('HD50AM_Ammo', cos(pitch * 12), 0, height - 9 - sin(pitch) * 12, 1, 2, 3, 0); break;
					}
				}

				if (invoker.WeaponStatus[VPProp_Mag] > 0)
				{
					invoker.WeaponStatus[VPProp_Chamber] = 2;
					invoker.WeaponStatus[VPProp_Mag]--;
					A_StartSound("Viper/SlideForward", 9);
				}
			}
			#### # 4 Offset(0, 35);
			Goto Nope;
		LoadChamber:
			#### # 0 A_JumpIf(invoker.WeaponStatus[VPProp_Chamber] > 0, "Nope");
			#### C 1 Offset(0, 36) A_StartSound("weapons/pocket",9);
			#### C 1 Offset(2, 40);
			#### C 2 Offset(2, 50);
			#### C 2 Offset(3, 60);
			#### C 2 Offset(5, 90);
			#### C 2 Offset(7, 80);
			#### C 3 Offset(10, 90);
			#### C 3 Offset(8, 96);
			#### C 4 Offset(6, 88)
			{
				if (CheckInventory("HD50AM_Ammo", 1))
				{
					A_StartSound("Viper/SlideForward", 8);
					A_TakeInventory('HD50AM_Ammo', 1, TIF_NOTAKEINFINITE);
					invoker.WeaponStatus[VPProp_Chamber] = 2;
				}
			}
			#### A 2 Offset(5, 76);
			#### A 1 Offset(4, 64);
			#### A 1 Offset(3, 56);
			#### A 1 Offset(2, 48);
			#### A 2 Offset(1, 38);
			#### A 3 Offset(0, 34);
			Goto ReadyEnd;
	}
}

class ViperRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDViperMag", -3, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("HDViperMag", -1, flags: SXF_NOCHECKPOSITION);
				let wpn = HDViper(Spawn("HDViper", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);
				if (!random(0, 3)){
					wpn.WeaponStatus[wpn.VPProp_Flags] |= wpn.VPF_LightTrigger;
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.VPProp_Flags] |= wpn.VPF_HeavyFrame;
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.VPProp_Flags] |= wpn.VPF_ExtendedBarrel;
				}
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}

class HDViperMag : HDMagAmmo
{
	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_VIPERMAG_PREFIX")..Stringtable.localize("$TAG_VIPERMAG")..Stringtable.localize("$PICKUP_VIPERMAG_SUFFIX");
	}

	override string, string, name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "VPMGA0" : "VPMGB0", "PRNDA0", "HD50AM_Ammo", 1.25;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDViper");
	}

	const EncMag = 17;
	const EncMagEmpty = EncMag * 0.6;
	const EncMagLoaded = EncMag * 0.2;

	Default
	{
		HDMagAmmo.MaxPerUnit 7;
		HDMagAmmo.InsertTime 12;
		HDMagAmmo.ExtractTime 12;
		HDMagAmmo.RoundType "HD50AM_Ammo";
		//HDMagAmmo.RoundBulk ENC_50AM;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "$TAG_VIPERMAG";
		HDPickup.RefId HDLD_VIPERMAG;

	}

	States
	{
		Spawn:
			VPMG A -1;
			Stop;
		SpawnEmpty:
			VPMG B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}
