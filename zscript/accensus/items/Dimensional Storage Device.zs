enum DSDProperties {

	// From HDStorageItemStats
	// ------------------------

	// SISTAT_ININDEX   = 1,
	// SISTAT_SELINDEX  = 2,
	// SISTAT_HOWMANY   = 3,
	// SISTAT_SCROLL    = 4,

	// SI_WEPICONSLOT   = HDWEP_STATUSSLOTS + 1,
	// SI_WEPBULKSLOT   = HDWEP_STATUSSLOTS + 2,
	// SI_MAXROWS       = 10,
	// SI_MAXBUNCH      = 20,
	// SI_SCROLLCYCLE   = (2 << 9),

	DSDPROP_EXTRAPOINTS = 5,
	DSDPROP_BATTERY     = 6,
	DSDPROP_MERGING     = 7,

	DSDACT_INSERT       = 1,
	DSDACT_EXTRACT      = 2,
}

class DSDInterface : HDStorageItem {

	Default {
		+Inventory.INVBAR
		+Weapon.WIMPY_WEAPON
		-HDWeapon.DROPTRANSLATION
		+HDWeapon.FITSINBACKPACK
		+HDWeapon.IGNORELOADOUTAMOUNT

		Weapon.SelectionOrder 1010;
		Inventory.Icon "DSDDA0";
		Inventory.PickupMessage "$PICKUP_DSD";
		Inventory.PickupSound "weapons/pocket";
		Tag "$TAG_DSD";
		HDWeapon.RefId HDLD_DSD;
		Scale 0.5;
		HDWeapon.loadoutcodes "
			\cucap - 0-???, Overrides the capacity of the Dimensional Storage Device.
			\cuNOTE: THIS IS CONSIDERED A CHEAT.
		";
		HDWeapon.wornlayer 0;

		HDStorageItem.minBulk 60;
		HDStorageItem.maxCapacity 500;
		HDStorageItem.maxBunch 200;
	}

	override double WeaponBulk() {
		return ContainerBulk(itemBulk);
	}

	override double ContainerBulk(double it) const {
		return minBulk;
	}

	override string,double GetPickupSprite(bool useSpare) {
		return "DSDD"..(weaponStatus[DSDPROP_BATTERY] < 1 ? "A" : "B").."0", 1.0;
	}

	override void Tick() {
		super.Tick();

		// Add capacity from FAK Upgrades
		if (weaponStatus[DSDPROP_EXTRAPOINTS] > 0) {
			maxCapacity += 500 * weaponStatus[DSDPROP_EXTRAPOINTS];
			weaponStatus[DSDPROP_EXTRAPOINTS] = 0;
		}

		// Sync Dynamic Light to operational status
		if (weaponStatus[DSDPROP_BATTERY] > 0) {
			if (!owner) A_AttachLight('DSDLight', DynamicLight.PointLight, 0x66CCFF, 16, 24, DynamicLight.LF_ATTENUATE);
			icon = TexMan.checkForTexture("DSDDB0");
		} else {
			A_RemoveLight('DSDLight');
			icon = TexMan.checkForTexture("DSDDA0");
		}
	}

	// check if an item can be added at all
	override bool CanFitInThisContainer(Class<Inventory> itemType) {
		let item = getDefaultByType(itemType);
		return weaponStatus[DSDPROP_BATTERY] > 0 && !HDCore.isChildClass(itemType, 'DSDInterface') && item && (HDPickup(item) || HDWeapon(item)) && !(item.bNOINTERACTION|item.bUNDROPPABLE|item.bUNTOSSABLE);
	}
	
	// sometimes particular instances of an item may vary
	override bool ThisCanFitInThisContainer(Inventory item) {
		return weaponStatus[DSDPROP_BATTERY] > 0 && !HDCore.isChildClass(item.getClass(), 'DSDInterface') && item && (HDPickup(item) || HDWeapon(item)) && !(item.bNOINTERACTION|item.bUNDROPPABLE|item.bUNTOSSABLE);
	}

	override void OnInsert(Inventory item) {
		if (!weaponStatus[DSDPROP_MERGING]) {
			weaponStatus[DSDPROP_BATTERY] -= 1;
	
			// owner.player.readyWeapon.A_SetTics(GetOperationSpeed(item, DSDACT_INSERT));
		}
	}

	override void OnExtract(Inventory item, Vector3 pos) {
		if (!weaponStatus[DSDPROP_MERGING]) {
			Spawn("DSDSpawnEffect", pos);
			weaponStatus[DSDPROP_BATTERY] -= 1;

			// owner.player.readyWeapon.A_SetTics(GetOperationSpeed(item, DSDACT_EXTRACT));
		}
	}

	// TODO: Re-Implement?
	override Vector3 ExtractPos() {
		if (owner) {
			for (int i = 64; i >= 0; i -= 8) {
				let pos = owner.vec3Angle(i - 8, owner.angle, owner.height / 2 + 6);
				if (Level.IsPointInLevel(pos)) return pos;
			}
		}

		return super.ExtractPos();
	}

	override string GetHelpText() {
		LocalizeHelp();
		return weaponStatus[DSDPROP_BATTERY] < 0
			? (
				LWPHELP_USE.."(hold) + "..LWPHELP_RELOAD..StringTable.Localize("$DSDWH_USERELOAD")
			)
			: (
				LWPHELP_FIRE.."/"..LWPHELP_ALTFIRE..StringTable.Localize("$BPWH_PNI")
				..LWPHELP_ZOOM.."+"..LWPHELP_UPDOWN..StringTable.Localize("$DSDWH_FMODPUD")
				..LWPHELP_RELOAD..StringTable.Localize("$BPWH_RELOAD")
				..LWPHELP_UNLOAD..StringTable.Localize("$BPWH_UNLOAD")
				// ..WEPHELP_BTCOL.."Enter"..WEPHELP_RGCOL..StringTable.Localize("$DSDWH_ENTER")
				// ..LWPHELP_USE.."(hold) + "..LWPHELP_ALTRELOAD..StringTable.Localize("$DSDWH_USEALTRELOAD")
				// ..LWPHELP_USE.."(hold) + "..LWPHELP_RELOAD..StringTable.Localize("$DSDWH_USERELOAD")
				..LWPHELP_USE.."(hold) + "..LWPHELP_UNLOAD..StringTable.Localize("$DSDWH_USEUNLOAD")
			);
	}

	override bool IsBeingWorn() { return false; }

	//configure from loadout
	override void LoadoutConfigure(string input){
		super.loadoutConfigure(input);

		let cap = GetLoadoutVar(input, "cap", 5);
		if (cap > 0) maxCapacity = cap;
	}

	override void DropOneAmmo(int amt) {
		let itemCnt = items.size();
		let itemBlk = itemBulk;

		super.DropOneAmmo(weaponStatus[SISTAT_SELINDEX]);

		if (itemCnt != items.size() || itemBlk != itemBulk) {
			Actor.Spawn("DSDSpawnEffect", ExtractPos());
		}
	}

	override bool AddSpareWeapon(actor newowner) { return false; }

	// override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect) {
	// 	return GetSpareWeaponRegular(newowner, reverse, doselect);
	// }

	// TODO: Localize
	override void ActualPickup(Actor other, bool silent) {
		A_RemoveLight('DSDLight');

		let dsd = DSDInterface(other.findInventory(getClass()));
		if (dsd && other.player && other.player.cmd.buttons&BT_ZOOM && other.player.cmd.buttons&BT_FIREMODE) {
			other.A_StartSound("weapons/pocket");
			other.A_Log("Your storage has expanded.", true);

			dsd.maxCapacity += 500;

			weaponStatus[DSDPROP_MERGING] = true;
			dsd.weaponStatus[DSDPROP_MERGING] = true;
			while (items.size()) {

				string itemCls, prefix;
				[itemCls, prefix] = itemClassAndPrefix(weaponStatus[SISTAT_SELINDEX]);

				let amt = count(itemCls);
				dsd.insert(extract(0, amt), amt);
			}

			if (weaponStatus[DSDPROP_BATTERY] >= 0) {
				HDMagAmmo.GiveMag(other, 'HDBattery', weaponStatus[DSDPROP_BATTERY]);
			}

			weaponStatus[DSDPROP_MERGING] = false;
			dsd.weaponStatus[DSDPROP_MERGING] = false;

			Destroy();
			return;
		}

		super.ActualPickup(other, silent);
	}

	// TODO: Re-implement HUD Logic
	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl) {
		super.DrawHUDStuff(sb, hdw, hpl);

		int bofs = -80;

		if (weaponStatus[DSDPROP_BATTERY] > -1)
		{
			sb.DrawImage(HDCore.GetBatteryIcon(weaponStatus[DSDPROP_BATTERY]), (0, bofs), sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER_BOTTOM, box: (-1, 20), scale: (2.0, 2.0));
		}

	// 	sb.DrawString(sb.pSmallFont, StringTable.Localize("$DSD_TOP"), (0, BaseOffset), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER);
	// 	sb.DrawString(sb.pSmallFont, Stringtable.Localize("$BACKPACK_TOTALBULK")..itemBulk.."/"..maxCapacity.."\c-", (0, BaseOffset + 10), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER);

		if (weaponStatus[DSDPROP_BATTERY] > 0) {
			sb.DrawString(sb.pSmallFont, ""..(weaponStatus[DSDPROP_BATTERY]), (10, bofs - 4), sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER, HDCore.GetBatteryFontColor(weaponStatus[DSDPROP_BATTERY]));
		} else if (Level.time % 50 < 25) {
			sb.DrawString(sb.pSmallFont, StringTable.Localize("$DSD_INOPERABLE"), (0, bofs + 20), sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER, Font.CR_RED);
		}

	// 	BaseOffset += 40;

	// 	int ItemCount = items.Size();

	// 	if(!ItemCount) {
	// 		sb.DrawString(sb.pSmallFont, Stringtable.Localize("$BACKPACK_NOITEMS"), (0, BaseOffset), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_DARKGRAY);
	// 		return;
	// 	}

	// 	StorageItem SelItem = Storage.GetSelectedItem();
	// 	if(!SelItem) return;

	// 	for (int i = 0; i < (ItemCount > 1 ? 5 : 1); ++i) {
	// 		int RealIndex = (Storage.SelItemIndex + (i - 2)) % ItemCount;

	// 		if (RealIndex < 0) RealIndex = ItemCount - abs(RealIndex); 

	// 		Vector2 Offset = ItemCount > 1 ? (-100, 8) : (0, 0);
	// 		switch (i)
	// 		{
	// 			case 1: Offset = (-50, 4);  break;
	// 			case 2: Offset = (0, 0); break;
	// 			case 3: Offset = (50, 4); break;
	// 			case 4: Offset = (100, 8); break;
	// 		}

	// 		StorageItem CurItem = Storage.Items[RealIndex];
	// 		bool CenterItem = Offset ~== (0, 0);
	// 		sb.DrawImage(CurItem.Icons[0], (Offset.x, BaseOffset + 10 + Offset.y), sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, CenterItem && !CurItem.HaveNone() ? 1.0 : 0.6, CenterItem ? (50, 30) : (30, 20), getdefaultbytype(CurItem.ItemClass).scale*(CenterItem?4.0:3.0));
	// 	}
		
	// 	sb.DrawString(sb.pSmallFont, SelItem.NiceName, (0, BaseOffset + 30), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_FIRE);

	// 	int AmountInBackpack = SelItem.ItemClass is 'HDMagAmmo' ? SelItem.Amounts.Size() : (SelItem.Amounts.Size() > 0 ? SelItem.Amounts[0] : 0);
	// 	sb.DrawString(sb.pSmallFont, StringTable.Localize("$DSD_INBAG")..sb.FormatNumber(AmountInBackpack, 1, 6), (0, BaseOffset + 40), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, AmountInBackpack > 0 ? Font.CR_BROWN : Font.CR_DARKBROWN);

	// 	int AmountOnPerson = GetAmountOnPerson(hpl.findInventory(SelItem.ItemClass));
	// 	sb.DrawString(sb.pSmallFont, StringTable.Localize("$BACKPACK_ONPERSON")..sb.FormatNumber(AmountOnPerson, 1, 6), (0, BaseOffset + 48), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, AmountOnPerson > 0 ?  Font.CR_WHITE : Font.CR_DARKGRAY);

	// 	if ((SelItem.ItemClass is 'HDPickup') && !(SelItem.ItemClass is 'HDArmour')) {
	// 		sb.DrawString(sb.pSmallFont, StringTable.Localize("$DSD_INSERTREMOVE")..sb.FormatNumber(OperationAmount, 1, 3), (0, BaseOffset + 56), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_SAPPHIRE);
	// 	}

	// 	if (DSDStorage(Storage).InSearchMode) {
	// 		sb.DrawString(sb.pSmallFont, StringTable.Localize("$DSD_SEARCHING")..DSDStorage(Storage).SearchString.."_", (-60, BaseOffset + 64), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_LEFT, Font.CR_WHITE);
	// 	}

	// 	if (SelItem.ItemClass is 'HDArmour') {
	// 		for (int i = 0; i < SelItem.Amounts.Size(); ++i)
	// 		{
	// 			Vector2 Off = (-126 + 35 * (i % 8), BaseOffset + 90 + 35 * (i / 8));
	// 			sb.DrawImage(SelItem.Icons[i], Off, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, 1.0, (30, 20), (4.0, 4.0));
	// 			sb.DrawString(sb.mAmountFont, sb.FormatNumber(SelItem.Amounts[i] > 1000 ? SelItem.Amounts[i] - 1000 : SelItem.Amounts[i], 1, 4), Off + (0, 12), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_YELLOW);
	// 		}
	// 	} else if (SelItem.ItemClass is 'HDMagAmmo' && GetDefaultByType((Class<HDMagAmmo>)(SelItem.ItemClass)).MaxPerUnit) {
	// 		for (int i = 0; i < SelItem.Amounts.Size(); ++i) {
	// 			Vector2 Off = (-160 + 42 * (i / 10) - 2 * i, BaseOffset + 90 + 12 * (i % 10));
	// 			sb.DrawImage(SelItem.Icons[i], Off, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, OperationAmount > i ? 1.0 : 0.5, (10, 20), (4.0, 4.0));
	// 			int magAmt = SelItem.Amounts[i];
	// 			if (magAmt == 51 && SelItem.ItemClass is 'HD4mMag') magAmt = 50;

	// 			// Account for Magazines that leverage the "recast" mechanic by only considering the "total rounds" portion of the magAmt.
	// 			name libMagName = 'HD7mMag';
	// 			Class<HDMagAmmo> libMag = (Class<HDMagAmmo>)(libMagName);
	// 			name cawsMagName = 'HD_CAWSMag';
	// 			Class<HDMagAmmo> cawsMag = (Class<HDMagAmmo>)(cawsMagName);
	// 			if (SelItem.ItemClass is libMag || SelItem.ItemClass is cawsMag) magAmt %= 100;

	// 			Off = (-160 + 42 * (i / 10) - 2 * i, BaseOffset + 90 + 12 * (i % 10));
	// 			sb.DrawString(sb.mAmountFont, sb.FormatNumber(magAmt, 1, 4), Off + (5, 3), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_LEFT, Font.CR_YELLOW, OperationAmount > i ? 1.0 : 0.5);
	// 		}
	// 	} else if (SelItem.ItemClass is 'HDWeapon' && SelItem.Amounts.Size() > 0 && SelItem.Amounts[0] > 1) {
	// 		// [Ace] Don't display the first weapon. It's already in the preview.
	// 		for (int i = 1; i < SelItem.Amounts[0]; ++i)
	// 		{
	// 			Vector2 Off = (-120 + 60 * ((i - 1) % 5), BaseOffset + 90 + 30 * ((i - 1) / 5));
	// 			sb.DrawImage(SelItem.Icons[i], Off, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, 1.0, (50, 20), (4.0, 4.0));
	// 		}
	// 	}
	}

	// protected int GetOperationSpeed(Inventory item, int operation) {
	// 	let wpn = HDWeapon(item);
	// 	let pkp = HDPickup(item);
	// 	bool multiPickup = pkp && pkp.bMULTIPICKUP;

	// 	switch (operation) {
	// 		case DSDACT_EXTRACT: return wpn ? 20 : multiPickup ? 6 : 6;
	// 		case DSDACT_INSERT:  return wpn ? 20 : multiPickup ? 6 : 6;
	// 		default:             return 20;
	// 	}
	// }

	override void InitializeWepStats(bool idfa) {
		weaponStatus[DSDPROP_BATTERY] = -1;
	}

	// private action void A_Sort(bool ascending) {
	// 	A_UpdateStorage();
	// 	StorageItem SelItem = invoker.Storage.GetSelectedItem();
	// 	int size = SelItem.Amounts.Size();
	// 	if (size > 1) // [Ace] It's a mag.
	// 	{
	// 		for (int i = 0; i < size - 1; ++i)
	// 		{
	// 			for (int j = i + 1; j < size; ++j)
	// 			{
	// 				if (!ascending && SelItem.Amounts[i] > SelItem.Amounts[j] || ascending && SelItem.Amounts[i] < SelItem.Amounts[j])
	// 				{
	// 					let swpAmt = SelItem.Amounts[i]; SelItem.Amounts[i] = SelItem.Amounts[j]; SelItem.Amounts[j] = swpAmt; 
	// 					let swpBulk = SelItem.Bulks[i]; SelItem.Bulks[i] = SelItem.Bulks[j]; SelItem.Bulks[j] = swpBulk; 
	// 					let swpIcon = SelItem.Icons[i]; SelItem.Icons[i] = SelItem.Icons[j]; SelItem.Icons[j] = swpIcon; 
	// 				}
	// 			}
	// 		}
	// 	}
	// }
	
	States {
		spawn:
			DSDD AB -1 NoDelay {
				if (invoker.weaponStatus[DSDPROP_BATTERY] > 0) {
					frame = 1;
				// } else if (target) {
				// 	translation = target.translation;
				}
			}
			stop;

		reload:
			TNT1 A 0 A_JumpIf(invoker.pressingUse(), "insertBattery");
			TNT1 A 0 A_JumpIf(invoker.weaponStatus[DSDPROP_BATTERY] < 1, "nope");
			goto super::reload;

		unload:
			TNT1 A 0 A_JumpIf(invoker.pressingUse(), "removeBattery");
			TNT1 A 0 A_JumpIf(invoker.weaponStatus[DSDPROP_BATTERY] < 1, "nope");
			goto super::unload;

		altreload:
			// TNT1 A 1 A_Sort(invoker.pressingUse());
			goto readyend;

		insertBattery:
			TNT1 A 0 A_JumpIf(invoker.weaponStatus[DSDPROP_BATTERY] >= 0, "nope");
			TNT1 A 14 A_StartSound("weapons/pocket", 9);
			TNT1 A 5 {
				let bat = HDBattery(findInventory('HDBattery'));
				if (!bat) return;

				invoker.weaponStatus[DSDPROP_BATTERY] = bat.TakeMag(true);
				A_StartSound("weapons/vulcopen1", 8, CHANF_OVERLAP);
			}
			TNT1 A 0 {
				invoker.A_SetHelpText();
				invoker.updateSelected();
				invoker.UpdateHudStuff();
			}
			goto ready;

		removeBattery:
			TNT1 A 0 A_JumpIf(invoker.weaponStatus[DSDPROP_BATTERY] < 0, "nope");
			TNT1 A 20;
			TNT1 A 5 {
				int charge = invoker.weaponStatus[DSDPROP_BATTERY];

				if (pressingUnload() || pressingReload()) {
					HDBattery.GiveMag(self, "HDBattery", charge);
					A_StartSound("weapons/pocket", 9);
					A_SetTics(20);
				} else {
					HDBattery.SpawnMag(self, "HDBattery", charge);
				}

				invoker.weaponStatus[DSDPROP_BATTERY] = -1;
			}
			TNT1 A 0 {
				invoker.A_SetHelpText();
				invoker.updateSelected();
				invoker.UpdateHudStuff();
			}
			goto ready;
	}
}

class DSDSpawnEffect : Actor
{
	Default {
		+NOINTERACTION
		Renderstyle "Add";
		Scale 0.5;
	}

	States {
		Spawn:
			DSDE A 0 NoDelay {
				A_StartSound("DSD/Unload", pitch: 0.7);

				for (int i = 0; i < 150; ++i) {
					A_SpawnParticle(0x88BBFF, SPF_RELATIVE | SPF_FULLBRIGHT, random(8, 12), frandom(2, 3), random(0, 359), 32, 0, 0, -2, 0, frandom(3.5, 4));
					A_SpawnParticle(0x88BBFF, SPF_RELATIVE | SPF_FULLBRIGHT, random(8, 12), frandom(2, 3), random(0, 359), 32, 0, 0, -2, 0, -frandom(3.5, 4));
				}
			}
			DSDE ABABCDEFGHIJ 3 Bright;
			Stop;
	}
}
