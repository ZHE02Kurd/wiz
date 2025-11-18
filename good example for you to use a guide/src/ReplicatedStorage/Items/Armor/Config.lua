local config = {
	Icon = "rbxassetid://2524237272"; -- Add an icon ID here

	Type = "Booster";
	Boost = "Armor";

	Slots = 1;
	Stack = 3;
	UseTime = 5; -- 5 second use animation
	Potency = 100; -- Instantly restores 100 armor

	-- Rotation in degrees (X = pitch, Y = yaw, Z = roll)
	BackRotation = {X = 45, Y = 90, Z = 0};
}

return config