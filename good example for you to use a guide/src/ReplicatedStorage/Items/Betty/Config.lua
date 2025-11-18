local config	= {
	Icon	= "rbxassetid://2593956238";
	
	Type	= "Gun";
	Size	= "Shotgun";
	
	SpreadPattern	= {
		{1, 0};
		{-1, 0};
		{0, 0.8};
		{0, -0.8};
		{0.3, 0.3};
		{-0.3, 0.3};
		{0.3, -0.3};
		{-0.3, -0.3};
	};
	
	Magazine	= 2;
	FireRate	= 2;
	Recoil		= 50;
	Range		= 150;
	ShotSize	= 8;
	Spread		= 8;
	Damage		= 14;
	Zoom		= 10;
	ReloadTime	= 1.3;
	FireMode	= "Semi";
	Dropoff		= 3;
	Reticle		= "Shotgun";
}

return config