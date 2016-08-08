function init()
	script.setUpdateDelta(60)
end

function update(dt)
	local fuel = world.getObjectParameter( pane.containerEntityId() , "initialFuel", 0)
	local fuelMax = world.getObjectParameter( pane.containerEntityId() , "fuelMax", 0)

	widget.setText("lblDynFuel", string.format("%d/%d U", math.floor(fuel),  math.floor(fuelMax)))

	local energy = world.getObjectParameter( pane.containerEntityId() , "energy", 0)
	local energyMax = world.getObjectParameter( pane.containerEntityId() , "energyMax", 0)

	widget.setText("lblDynEnergy", string.format("%d/%d F", math.floor(energy), math.floor(energyMax)))

	widget.setProgress("pbDynFuel", math.min(1, fuel / fuelMax))
	widget.setProgress("pbDynEnergy", math.min(1, energy / energyMax))
end

function toggleGenerator()
  world.sendEntityMessage(pane.containerEntityId(), "toggleGenerator")
end