local config	= {
	Icon	= "rbxassetid://2524106687";
	
	Type	= "Gun";
	Size	= "Shotgun";
	
	SpreadPattern	= {
		{-0.5, 0.5};
		{0.5, 0.5};
		{-0.5, -0.5};
		{0.5, -0.5};
		{-1, 0};
		{1, 0};
		{0, -1};
		{0, 1};
		{0, 0};
	};
	
	Magazine	= 6;
	FireRate	= 1.8;
	Recoil		= 50;
	Range		= 300;
	ShotSize	= 9;
	Spread		= 5;
	Damage		= 7;
	Zoom		= 10;
	ReloadTime	= 1.8;
	FireMode	= "Semi";
	Dropoff		= 3;
	Reticle		= "Shotgun";
}

return config