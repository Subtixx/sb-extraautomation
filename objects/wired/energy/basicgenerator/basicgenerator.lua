function init(virtual)
   if virtual then return end
   energy.init()

   -- Set self values
   self.fuelValues = config.getParameter("fuelValues") or {}
   self.fuelMax = config.getParameter("fuelMax") or 50
   storage.fuel = config.getParameter("initialFuel") or 0
   self.fuelUseRate = config.getParameter("fuelUseRate") or 0.2
   self.fuelBarOffset = config.getParameter("fuelBarOffset") or {-1.625, 0.375}

   -- Set config parameters (for UI)
   object.setConfigParameter("fuelMax", self.fuelMax)
   object.setConfigParameter("energyMax", energy.capacity)

   object.setInteractive(not object.isInputNodeConnected(0))

   --animator.translateTransformationGroup("fuelbar", self.fuelBarOffset)

   -- profilerApi.init()

   -- Communication with the UI
   message.setHandler("toggleGenerator", toggleGenerator)

   updateAnimationState()
end

function toggleGenerator()
   if not object.isInputNodeConnected(0) then
      storage.state = not storage.state
      updateAnimationState()
   end
end

function containerCallback()
   -- don't consume when item is placed.
   --consumeFuel()
end

function consumeFuel()
   if(storage.fuel >= self.fuelMax) then return end

   local item = world.containerItems(entity.id())[1]

   if item then
      if self.fuelValues[item.name] and storage.fuel + self.fuelValues[item.name] <= self.fuelMax then
         local itemCount = item.count
         item.count = 1

         while itemCount > 0 and storage.fuel + self.fuelValues[item.name] <= self.fuelMax do
            if(world.containerConsume(entity.id(), item)) then
               storage.fuel = storage.fuel + self.fuelValues[item.name]
               itemCount = itemCount - 1
            end
         end
      end
   end
   object.setConfigParameter("initialFuel", storage.fuel)
   updateAnimationState()
end

function die()
   local position = object.position()
   world.spawnItem("basicgenerator", {position[1] + 2, position[2] + 1}, 1, {
      initialFuel=storage.fuel,
      description=string.format(config.getParameter("fuelDescription"), math.floor(storage.fuel))
   })

   energy.die()
end

function onNodeConnectionChange(args)
   checkNodes()
end

function onInputNodeChange(args)
   checkNodes()
end

--[[function onInteraction(args)
  -- if world.entityHandItem(args.sourceId, "primary") == "profilertool" then
  --   profilerApi.logData()
  --   return
  -- end
  if not object.isInputNodeConnected(0) then
    if storage.state then
      storage.state = false
    else
      storage.state = true
    end

    updateAnimationState()
  end
end]]

function updateAnimationState()
   if storage.state and storage.fuel > 0 then
      animator.setAnimationState("generatorState", "on")
   elseif storage.state then
      animator.setAnimationState("generatorState", "error")
   else
      animator.setAnimationState("generatorState", "off")
   end

   animator.resetTransformationGroup("fuelbar")
   animator.scaleTransformationGroup("fuelbar", {math.min(1, storage.fuel / self.fuelMax), 1})
   animator.translateTransformationGroup("fuelbar", {-1.625, 0.375}) --self.fuelBarOffset) -- translate it to offset, otherwise bar moves on it's own
end

function checkNodes()
   local isWired = object.isInputNodeConnected(0)
   if isWired then
      storage.state = object.getInputNodeLevel(0)
      updateAnimationState()
   end
   object.setInteractive(not isWired)
end

--never accept energy from elsewhere
function onEnergyNeedsCheck(energyNeeds)
   energyNeeds[tostring(entity.id())] = 0
   return energyNeeds
end

--only send energy while generating (even if it's in the pool... could try revamping this later)
function onEnergySendCheck()
   if storage.state then
      return energy.getEnergy()
   else
      return 0
   end
end

function generateEnergy(dt)
   local tickFuel = self.fuelUseRate * dt
   if storage.fuel >= tickFuel then
      storage.fuel = storage.fuel - tickFuel
      energy.addEnergy(tickFuel * energy.fuelEnergyConversion)
      return true
   elseif storage.fuel > 0 then
      energy.addEnergy(storage.fuel * energy.fuelEnergyConversion)
      storage.fuel = 0
      return true
   else
      storage.state = false
      return false
   end
end 

function update(dt)
   if storage.state then
      consumeFuel()
      generateEnergy(dt)
      updateAnimationState()

      object.setConfigParameter("energy", energy.getEnergy())
   else
      object.setConfigParameter("energy", 0)
   end

   energy.update(dt)
end