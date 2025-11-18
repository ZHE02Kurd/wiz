local module	= {}

function module.Create(self, item)
	local itemModule	= {
		Item		= item;
		Equipped	= false;
		Connections	= {};
	}
	
	function itemModule.Connect(self)
		-- called when the item is first initialized on the client
	end
	
	function itemModule.Disconnect(self)
		-- called when the item leaves the client's control
		for _, connection in pairs(self.Connections) do
			connection:Disconnect()
		end
		self.Connections	= {}
	end
	
	function itemModule.Equip(self)
		-- called when the item is equipped
		self.Equipped	= true
	end
	
	function itemModule.Unequip(self)
		-- called when the item is unequipped
		self.Equipped	= false
	end
	
	function itemModule.Activate(self)
		-- called when the item is activated
	end
	
	function itemModule.Deactivate(self)
		-- called when then item is deactivated
	end
	
	return itemModule
end

return module