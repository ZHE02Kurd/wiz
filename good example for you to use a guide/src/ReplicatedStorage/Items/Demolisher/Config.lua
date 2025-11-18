local config	= {
	Icon	= "rbxassetid://2097714792";
	Type	= "Gun";
	Size	= "Shotgun";
	
	SpreadPattern	= {
		{0.5, 0.5};
		{-0.5, 0.5};
		{0.5, -0.5};
		{-0.5, -0.5};
		{-1, 0};
		{0, 0};
		{1, 0};
	};
	
	Magazine	= 8;
	FireRate	= 2;
	Recoil		= 80;
	Range		= 300;
	ShotSize	= 7;
	Spread		= 10;
	Damage		= 9;
	Zoom		= 10;
	ReloadTime	= 2;
	FireMode	= "Auto";
	Dropoff		= 3;
	Reticle		= "Shotgun";
}

return config