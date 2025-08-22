const HDCONST_WCSPAWNPOOLEVENT = HDCONST_BPSPAWNPOOLEVENT + 1;

class WCSpawnPool : EventHandler {
	private Array<class <HDWeapon> > ValidWeapons;
	private bool Initialized;

	override void OnRegister() {
		// Ideally this should have the event handler run BEFORE any others.
		// Modders: Any event handlers meant to run at world load should have
		//          an order number of HDCONST_WCSPAWNPOOLEVENT+1 or higher!
		//          (default is zero so this should almost never be a problem)
		SetOrder(HDCONST_WCSPAWNPOOLEVENT);
		Initialized = false;
	}

	override void WorldLoaded(worldevent e) {
		BuildValidItemList();
	}

	private void BuildValidItemList() {
		if (ValidWeapons.Size() > 0) { return; } // don't rebuild
		Initialized = true;
		for (int i = 0; i < AllActorClasses.Size(); ++i) {
			let invitem = (class<HDWeapon>)(AllActorClasses[i]);
			if (!invitem) { continue; }
			AddItem(invitem);
		}
	}

	// Runs all normal checks and adds the passed item class to the spawn pool.
	//   Returns TRUE if the item class was successfully added.
	//   Returns FALSE if the item class could not be added.
	static bool AddItem(class<HDWeapon> cls) {
		WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
		if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended', LOGGING_ERROR, "AddItem(): Weapon Crate spawn pool not found or initialized!");

			return false;
		 }

		if (CheckItem(cls) != -1) {
            HDCore.Log('AceCorpExtended', LOGGING_WARN, cls.GetClassName().." already in weapon crate spawn pool");

			return false;
		}

		let CurrWeapon = HDWeapon(GetDefaultByType(cls));
		if (!(cls
			&& !CurrWeapon.bWIMPY_WEAPON
			&& !CurrWeapon.bCHEATNOTWEAPON
			&& !CurrWeapon.bDONTNULL
			&& CurrWeapon.WeaponBulk() > 0
			&& !CurrWeapon.bINVBAR
			&& CurrWeapon.Refid != "")
		) {
            HDCore.Log('AceCorpExtended', LOGGING_WARN, cls.GetClassName().." not a valid HDWeapon");

			return false;
		}

		// All checks passed
		sp.ValidWeapons.Push(cls);

		HDCore.Log('AceCorpExtended', LOGGING_DEBUG, "added "..cls.GetClassName().." to weapon crate spawn pool");

		return true;
	}

	// Removes an item class from the spawn pool if it exists.
	//   Returns TRUE if the item class was successfully removed.
	//   Returns FALSE if for some reason the removal failed.
	static bool RemoveItem(class<HDWeapon> cls) {
		WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
		if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended', LOGGING_ERROR, "RemoveItem(): Weapon Crate spawn pool not found or initialized!");
			
			return false;
		}

		int index = CheckItem(cls);
		if (index != -1) {
			sp.ValidWeapons.Delete(index);
            
			HDCore.Log('AceCorpExtended', LOGGING_DEBUG, "removed "..cls.GetClassName().." from weapon crate spawn pool");

			return true;
		}

		return false;
	}

	// Checks if an item class already exists in the spawn pool
	//   Returns ARRAY INDEX if the item class is found in the spawn pool
	//   Returns -1 if the item class is not found in the spawn pool
	static int CheckItem(class<HDWeapon> cls) {
		WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
		if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended', LOGGING_ERROR, "CheckItem(): Weapon Crate spawn pool not found or initialized!");
			
			return false;
		}

		for (int i=0; i<sp.ValidWeapons.Size(); i++) if (sp.ValidWeapons[i] is cls) return i;

		return -1;
	}

	// Returns a random valid item class from the weapon crate spawn pool.
	static class<HDWeapon> GetValidItem() {
		WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
		if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended', LOGGING_ERROR, "GetValidItem(): Weapon Crate spawn pool not found or initialized!");
			
			return null;
		}

		if (sp.ValidWeapons.Size() <= 0) {
            HDCore.Log('AceCorpExtended', LOGGING_WARN, "GetValidItem(): Weapon Crate spawn pool empty!");
			
			return null;
		}

		return sp.ValidWeapons[random(0, sp.ValidWeapons.Size() - 1)];
	}
}

class HDWeaponCrate : HDUPK
{

	override void Tick()
	{
		UseTimer--;

		roll *= 0.6;

		Super.Tick();
	}

	override bool OnGrab(Actor other)
	{
		if (Distance3D(picktarget) <= 50) {
			if (UseTimer <= 0) {
				UseTimer = 10;
				vel.z = 2;
				A_SetRoll(frandompick(-5, 5), SPF_INTERPOLATE);
			} else {
				SetStateLabel("DropGoods");
			}
		}

		return false;
	}

	override void A_HDUPKGive() { }

	int UseTimer;

	Default
	{
		+ROLLSPRITE
		+ROLLCENTER
		+SHOOTABLE
		+NOBLOOD
		+NOPAIN
		Scale 0.375;
		Height 8;
		Radius 12;
		Health 100;
		Mass 120;
	}

	States
	{
		Spawn:
			WPCR T -1;
			Stop;
		DropGoods:
			TNT1 A 1
			{
				Class<HDWeapon> PickedWeapon = WCSpawnPool.GetValidItem();
				
	            HDCore.Log('AceCorpExtended', LOGGING_DEBUG, "Dropping "..(PickedWeapon ? PickedWeapon.getClassName().."" : "Nothing"));

				if (PickedWeapon) {
					A_SpawnItemEx(
						PickedWeapon,
						0, 0, 0,
						frandom(0.5, 1.0), 0, frandom(3.0, 6.0),
						random(0, 359),
						SXF_NOCHECKPOSITION
					);
				} else {
					SetStateLabel("Spawn");
					return;
				}
			}
			Stop;
		Death:
			TNT1 A 1
			{
				Spawn("HDExplosion", pos, ALLOW_REPLACE);
				A_Explode(64, 64);
			}
			Stop;
	}
}
