local config	= {
	Icon	= "rbxassetid://2524106687";
	
	Type	= "Gun";
	Size	= "Shotgun";
	
	SpreadPattern	= {
		-- inner 3
		{0, -0.4};
		{-0.35, 0.2};
		{0.35, 0.2};
		
		-- outer five
		{0, 1};
		{0.95, 0.31};
		{0.59, -0.81};
		{-0.59, -0.81};
		{-0.95, 0.31};
	};
	
	Magazine	= 5;
	FireRate	= 1.5;
	Recoil		= 40;
	Range		= 300;
	ShotSize	= 8;
	Spread		= 6;
	Damage		= 10;
	Zoom		= 10;
	ReloadTime	= 2;
	FireMode	= "Semi";
	Dropoff		= 3;
	Reticle		= "Shotgun";
}

return config