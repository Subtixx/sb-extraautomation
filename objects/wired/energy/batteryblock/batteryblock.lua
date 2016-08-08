function init(virtual)
   if virtual then return end
   energy.init()

   self.particleCooldown = 0.2
   self.particleTimer = 0

   self.acceptCharge = config.getParameter("acceptCharge") or true

   animator.setParticleEmitterActive("charging", false)

   --animator.translateTransformationGroup("chargebar", {0.125, 0.375})

   updateAnimationState()
end

function die()
   local position = entity.position()
   --[[if energy.getEnergy() == 0 then
      world.spawnItem("batteryblock", {position[1] + 0.5, position[2] + 1}, 1)
   elseif energy.getUnusedCapacity() == 0 then
      world.spawnItem("fullbattery", {position[1] + 0.5, position[2] + 1}, 1, {savedEnergy=energy.getEnergy()})
   else
      world.spawnItem("batteryblock", {position[1] + 0.5, position[2] + 1}, 1, {savedEnergy=energy.getEnergy()})
   end]]
   world.spawnItem("batteryblock", {position[1] + 0.5, position[2] + 1}, 1, {
      savedEnergy=energy.getEnergy(),
      description=string.format(config.getParameter("energyDescription"), math.floor(energy.getEnergy())),
      inventoryIcon="fullbatteryicon.png" -- TODO: Figure out how to override "largeImage"
   })

   energy.die()
end

function isBattery()
   return true
end

function getBatteryStatus()
   return {
      id=entity.id(),
      capacity=energy.getCapacity(),
      energy=energy.getEnergy(),
      unusedCapacity=energy.getUnusedCapacity(),
      position=entity.position(),
      acceptCharge=self.acceptCharge
   }
end

function onEnergyChange(newAmount)
   updateAnimationState()
end

function showChargeEffect()
   animator.setParticleEmitterActive("charging", true)
   self.particleTimer = self.particleCooldown
end

function updateAnimationState()
   local chargeAmt = energy.getEnergy() / energy.getCapacity()
   --entity.scaleGroup("chargebar", {1, chargeAmt})
   animator.resetTransformationGroup("chargebar")
   animator.scaleTransformationGroup("chargebar", {1, chargeAmt})
   animator.translateTransformationGroup("chargebar", {0.125, 0.375})
end

function update(dt)
   if self.particleTimer > 0 then
      self.particleTimer = self.particleTimer - dt
      if self.particleTimer <= 0 then
         animator.setParticleEmitterActive("charging", false)
      end
   end

   energy.update(dt)
end