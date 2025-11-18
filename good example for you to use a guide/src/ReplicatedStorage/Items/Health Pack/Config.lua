local config = {
	Icon = "rbxassetid://2524237272";

	Type = "Booster";
	Boost = "Health";

	Slots = 1;
	Stack = 3;
	UseTime = 1.5; -- 1.5 seconds starting animation
	Potency = 5; -- Heals 5 HP per tick
	TickRate = 0.75; -- Heal every 0.75 seconds
	MaxHeal = 100; -- Maximum total healing

	-- Rotation in degrees (X = pitch, Y = yaw, Z = roll)
	BackRotation = {X = 45, Y = 90, Z = 0};
}

return config