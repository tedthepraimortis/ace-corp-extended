class AceCorpsWeaponCrateHandler : HDCoreEventHandler {

    // List of Inventory Classes to add to Weapon Crate Spawns
    Array< Class<HDWeapon> > weaponCrateWhitelist;

    // List of Inventory Classes to remove from Weapon Crate Spawns
    Array< Class<HDWeapon> > weaponCrateBlacklist;

    private WCSpawnPool sp;

    override void beforeProcessCommands() {
        weaponCrateWhitelist.clear();
        weaponCrateBlacklist.clear();
        
        // If the Weapon Crate Spawn Pool hasn't been cached, attempt to get it.
		if (!sp) sp = WCSpawnPool(EventHandler.Find("WCSpawnPool"));
    }

    override void processCommand(HDCoreCommand cmd) {
        switch (cmd.command) {
            case 'addWeaponCrateFilter': {
                // FIXME: Find a better command/logic to handle existing CVARs

                let weapon = cmd.getNameParam("name");
                Class<HDWeapon> wpnCls = weapon;

                if (!wpnCls) break;

                // If the filter entry is allowed, remove from blacklist,
                // Otherwise add to blacklist.
                let index = weaponCrateBlacklist.find(wpnCls);
                if (cmd.getBoolParam("allowed")) {
                    if (index < weaponCrateBlacklist.size()) weaponCrateBlacklist.delete(index);
                } else {
                    if (index >= weaponCrateBlacklist.size()) weaponCrateBlacklist.push(wpnCls);
                }

                break;
            }
            case 'addWeaponCrateWhitelist': {
                let weapon = cmd.getNameParam("name");
                Class<HDWeapon> wpnCls = weapon;

                if (!wpnCls) break;

                if (weaponCrateWhitelist.find(wpnCls) >= weaponCrateWhitelist.size()) weaponCrateWhitelist.push(wpnCls);

                break;
            }
            case 'removeWeaponCrateWhitelist': {
                let weapon = cmd.getNameParam("name");
                Class<HDWeapon> wpnCls = weapon;

                if (!wpnCls) break;

                let index = weaponCrateWhitelist.find(wpnCls);
                if (index < weaponCrateWhitelist.size()) weaponCrateWhitelist.delete(index);

                break;
            }
            case 'clearWeaponCrateWhitelist': {
                weaponCrateWhitelist.clear();
                break;
            }
            case 'addWeaponCrateBlacklist': {
                let weapon = cmd.getNameParam("name");
                Class<HDWeapon> wpnCls = weapon;

                if (!wpnCls) break;

                if (weaponCrateBlacklist.find(wpnCls) >= weaponCrateBlacklist.size()) weaponCrateBlacklist.push(wpnCls);

                break;
            }
            case 'removeWeaponCrateBlacklist': {
                let weapon = cmd.getNameParam("name");
                Class<HDWeapon> wpnCls = weapon;

                if (!wpnCls) break;

                let index = weaponCrateBlacklist.find(wpnCls);
                if (index < weaponCrateBlacklist.size()) weaponCrateBlacklist.delete(index);

                break;
            }
            case 'clearWeaponCrateBlacklist': {
                weaponCrateBlacklist.clear();
                break;
            }
            default:
                break;
        }
    }

    override void afterProcessCommands() {
        if (HDCore.ShouldLog('AceCorpExtended', LOGGING_DEBUG)) {

            let msg = "Weapon Crate Spawn Pool Whitelist:\n";

            forEach(wl : weaponCrateWhitelist) msg = msg.." * "..wl.getClassName().."\n";

            HDCore.Log('AceCorpExtended', LOGGING_DEBUG, msg);


            msg = "Weapon Crate Spawn Pool Blacklist:\n";

            forEach(bl : weaponCrateBlacklist) msg = msg.." * "..bl.getClassName().."\n";

            HDCore.Log('AceCorpExtended', LOGGING_DEBUG, msg);
        }
    }

    override void worldLoaded(WorldEvent e) {

        super.worldLoaded(e);

        // If the Weapon Crate Whitelist and Blacklist are both empty, quit.
        if (!weaponCrateWhitelist.size() && !weaponCrateBlacklist.size()) return;

        handleWeaponCrateLootTable();
    }

    private void handleWeaponCrateLootTable() {

        // If we don't have the Weapon Crate Spawn Pool, quit.
        if (!sp) return;

        // If the spawn pool hasn't been initialized yet, do so.
        // if (!sp.initialized) sp.BuildValidItemList();

        // Add all "whitelisted" entries
        foreach (wl : weaponCrateWhitelist) {
            HDCore.Log('AceCorpExtended', LOGGING_DEBUG, "Adding "..wl.getClassName().." to Weapon Crate Spawn Pool");

            WCSpawnPool.AddItem(wl);
        }

        // Remove all "blacklisted" entries
        foreach (bl : weaponCrateBlacklist) {
            HDCore.Log('AceCorpExtended', LOGGING_DEBUG, "Removing "..bl.getClassName().." from Weapon Crate Spawn Pool");

            WCSpawnPool.removeItem(bl);
        }
    }
}
