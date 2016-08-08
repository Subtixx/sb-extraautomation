function init()
	script.setUpdateDelta(60)
end

function update(dt)
	local fuel = world.getObjectParameter( pane.containerEntityId() , "initialFuel", 0)
	local fuelMax = world.getObjectParameter( pane.containerEntityId() , "fuelMax", 0)

	widget.setText("lblDynFuel", string.format("%d/%d", math.floor(fuel),  math.floor(fuelMax)))

	local energyGen = world.getObjectParameter( pane.containerEntityId() , "energyGeneration", 0)
	widget.setText("lblDynPowerGen", string.format("%d F/t", energyGen))
end

function toggleGenerator()
  world.sendEntityMessage(pane.containerEntityId(), "toggleGenerator")
end