// const HDCONST_WCSPAWNPOOLEVENT = HDCONST_BPSPAWNPOOLEVENT + 1;

class WCSpawnPool : HDCoreEventHandler {

    Array<name> weaponWhiteList;
    Array<name> weaponBlackList;

    private Array<class <HDWeapon> > ValidWeapons;

    override void beforeProcessCommands() {
        weaponWhiteList.clear();
        weaponBlackList.clear();

        ValidWeapons.clear();
    }

    override void processCommand(HDCoreCommand cmd) {
        switch (cmd.command) {
            case 'addWeaponCrateFilter': {
                // FIXME: Find a better command/logic to handle existing CVARs

                let weapon = cmd.getNameParam("name");

                // If the filter entry is allowed, remove from blacklist,
                // Otherwise add to blacklist.
                let index = weaponBlackList.find(weapon);
                if (cmd.getBoolParam("allowed")) {
                    if (index < weaponBlackList.size()) weaponBlackList.delete(index);
                } else {
                    if (index >= weaponBlackList.size()) weaponBlackList.push(weapon);
                }

                break;
            }
            case 'addWeaponCrateWhitelist': {
                let weapon = cmd.getNameParam("name");

                if (weaponWhiteList.find(weapon) >= weaponWhiteList.size()) weaponWhiteList.push(weapon);

                break;
            }
            case 'removeWeaponCrateWhitelist': {
                let weapon = cmd.getNameParam("name");

                let index = weaponWhiteList.find(weapon);
                if (index < weaponWhiteList.size()) weaponWhiteList.delete(index);

                break;
            }
            case 'clearWeaponCrateWhitelist': {
                weaponWhiteList.clear();
                break;
            }
            case 'addWeaponCrateBlacklist': {
                let weapon = cmd.getNameParam("name");

                if (weaponBlackList.find(weapon) >= weaponBlackList.size()) weaponBlackList.push(weapon);

                break;
            }
            case 'removeWeaponCrateBlacklist': {
                let weapon = cmd.getNameParam("name");

                let index = weaponBlackList.find(weapon);
                if (index < weaponBlackList.size()) weaponBlackList.delete(index);

                break;
            }
            case 'clearWeaponCrateBlacklist': {
                weaponBlackList.clear();
                break;
            }
            default:
                break;
        }
    }

    override void afterProcessCommands() {
        if (HDCore.ShouldLog('AceCorpExtended', LOGGING_DEBUG)) {

            let msg = "Weapon Crate Spawn Pool Whitelist:\n";

            forEach(wl : weaponWhiteList) msg = msg.." * "..wl.."\n";

            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, msg);


            msg = "Weapon Crate Spawn Pool Blacklist:\n";

            forEach(bl : weaponBlackList) msg = msg.." * "..bl.."\n";

            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, msg);
        }
    }

    override void WorldLoaded(worldevent e) {
        super.WorldLoaded(e);

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
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_ERROR, "AddItem(): Weapon Crate spawn pool not found or initialized!");

            return false;
        }

        if (cls.isAbstract()) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." is abstract");

            return false;
        }

        if (CheckItem(cls) != -1) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." already in weapon crate spawn pool");

            return false;
        }

        forEach (bl : sp.weaponBlackList) if (cls is bl) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." blacklisted");

            return false;
        }

        let whitelisted = false;
        forEach (wl : sp.weaponWhiteList) if (cls is wl) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." whitelisted");

            whitelisted = true;
            break;
        }

        if (sp.weaponWhiteList.size() && !whitelisted) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." whitelist exists, not whitelisted");

            return false;
        }

        let CurrWeapon = HDWeapon(GetDefaultByType(cls));
        if (
            !sp.weaponWhiteList.size()
            && !(
                cls
                && !CurrWeapon.bWIMPY_WEAPON
                && !CurrWeapon.bCHEATNOTWEAPON
                && !CurrWeapon.bDONTNULL
                && CurrWeapon.WeaponBulk() > 0
                && !CurrWeapon.bINVBAR
                && CurrWeapon.Refid != ""
            )
        ) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "AddItem(): "..cls.GetClassName().." not a valid HDWeapon");

            return false;
        }

        // All checks passed
        sp.ValidWeapons.Push(cls);

        HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_INFO, "AddItem(): added "..cls.GetClassName().." to weapon crate spawn pool");

        return true;
    }

    // Removes an item class from the spawn pool if it exists.
    //   Returns TRUE if the item class was successfully removed.
    //   Returns FALSE if for some reason the removal failed.
    static bool RemoveItem(class<HDWeapon> cls) {
        WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
        if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_ERROR, "RemoveItem(): Weapon Crate spawn pool not found or initialized!");
            
            return false;
        }

        int index = CheckItem(cls);
        if (index != -1) {
            sp.ValidWeapons.Delete(index);
            
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_DEBUG, "RemoveItem(): removed "..cls.GetClassName().." from weapon crate spawn pool");

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
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_ERROR, "CheckItem(): Weapon Crate spawn pool not found or initialized!");
            
            return false;
        }

        for (int i=0; i<sp.ValidWeapons.Size(); i++) if (sp.ValidWeapons[i] is cls) return i;

        return -1;
    }

    // Returns a random valid item class from the weapon crate spawn pool.
    static class<HDWeapon> GetValidItem() {
        WCSpawnPool sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
        if (!(sp && sp.Initialized)) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_ERROR, "GetValidItem(): Weapon Crate spawn pool not found or initialized!");
            
            return null;
        }

        if (sp.ValidWeapons.Size() <= 0) {
            HDCore.Log('AceCorpExtended.WCSpawnPool', LOGGING_WARN, "GetValidItem(): Weapon Crate spawn pool empty!");
            
            return null;
        }

        return sp.ValidWeapons[random(0, sp.ValidWeapons.Size() - 1)];
    }
}