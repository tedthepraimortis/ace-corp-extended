class HDBlackhawkBoltIncendiary : HDBlackhawkBolt
{
	Default
	{
		Tag "$TAG_BLACKHAWKBOLT_I";
		Inventory.Icon "BHBIB0";
		HDPickup.Bulk 5.0;
		HDPickup.RefId HDLD_BLACKHAWKBOLT_I;
	}

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_BLACKHAWKBOLT_I_PREFIX")..Stringtable.localize("$TAG_BLACKHAWKBOLT_I")..Stringtable.localize("$PICKUP_BLACKHAWKBOLT_I_SUFFIX");
	}

	States
	{
		Spawn:
			BHBL B 0;
			Goto Super::Spawn;
	}
}

// [Ace] This also acts as an incendiary bolt. It's less kinetic and more chemical.
class HDBlackhawkProjectileIncendiary : HDBlackhawkProjectile
{
	override void OnBoltHit(Line hitLine, Actor hitActor)
	{
		A_SprayDecal("BoltScorchRegular", 16);

		if (hitLine)
		{
			Actor.Spawn("BulletPuffSmall", pos);
		}

		if (hitActor)
		{
			int dmg = random(50, 100);
			double ang = AbsAngle(angle, AngleTo(hitActor));
			if (ang < 20)
			{
				dmg += random(40, 60);
			}
			else if (ang < 40)
			{
				dmg += random(20, 30);
			}
			hitActor.DamageMobj(self, target, dmg, 'Piercing');
		}
		else
		{
			DoorDestroyer.DestroyDoor(self, maxdepth: 4);
		}
	}

	Default
	{
		Mass 100;
		Speed HDCONST_MPSTODUPT * 150;
		Obituary "$OB_BLACKHAWKBOLT_I";
		+BRIGHT
	}

	States
	{
		Spawn:
			BHBP B 0 A_GiveInventory('Heat', random(150, 400), AAPTR_TRACER);
			Goto Super::Spawn;
	}
}