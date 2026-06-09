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
		if (Distance3DSquared(picktarget) <= 50 ** 2) {
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
