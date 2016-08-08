function init(virtual)
   if not virtual then
      energy.init()
      datawire.init()
      pipes.init({itemPipe})

      if storage.ore == nil then storage.ore = {} end
      if storage.state == nil then storage.state = true end

      self.conversions = config.getParameter("smeltRecipes")

      self.smeltRate = config.getParameter("smeltRate")
      self.smeltTimer = 0

      object.setInteractive(not object.isInputNodeConnected(0))
   end
end

function die()
   energy.die()
   ejectOre() --Temporary
end

function onNodeConnectionChange()
   checkNodes()
   datawire.onNodeConnectionChange()
end

function onInputNodeChange(args)
   checkNodes()
end

function checkNodes()
   local isWired = object.isInputNodeConnected(0)
   if isWired then
      storage.state = object.getInputNodeLevel(0)
   end
   object.setInteractive(not isWired)
end

function containerCallback()
   if not isItemNodeConnected(1) and not isItemNodeConnected(2) then
      local contents = world.containerItems(entity.id())
      local item = contents[1]
      if(item) then
         local oreConversion = self.conversions[item.name]
         if(oreConversion == nil) then -- reject item.
            world.containerConsume(entity.id(), item)

            local position = entity.position()
            world.spawnItem(item.name, {position[1] + 1.5, position[2] + 1}, item.count)
         end
      end
   end
   --[[if not isItemNodeConnected(1) then
      local contents = world.containerItems(entity.id())
      local item = contents[1]
      if item and contents[2] == nil then
         if(beforeItemPut(item, 1)) then
            local used = onItemPut(item, 1)
            if(used ~= false and used ~= true) then
               item.count = used
            elseif(used == false) then
               item.count = 0
            end
            world.containerConsume(entity.id(), item)
         end
      end
   end]]
end

--[[function onInteraction(args)
if object.isInputNodeConnected(0) == false then
storage.state = not storage.state
end
end]]

function update(dt)
   energy.update(dt)
   datawire.update(dt)
   pipes.update(dt)

   if(not isItemNodeConnected(1) and not isItemNodeConnected(2)) then -- No itemPipe connected to output
      if(storage.ore.name == nil) then -- no ores in buffer
         local contents = world.containerItems(entity.id())
         local item = contents[1]
         -- we have a conversion for this item
         -- we don't have an item in output slot, or the output matches this results item.
         if(item) then
            if(self.conversions[item.name] ~= nil and (contents[2] == nil or self.conversions[item.name][3] == contents[2].name)) then
               local used = onItemPut(item, 1)
               if(used ~= false and used ~= true) then
                  item.count = used
               elseif(used == false) then
                  item.count = 0
                  animator.setAnimationState("smelting", "error")
               end
               world.containerConsume(entity.id(), item) -- consume
            else
               animator.setAnimationState("smelting", "error")
            end
         else
            animator.setAnimationState("smelting", "idle")
         end
      elseif storage.ore.name and storage.state and energy.consumeEnergy(dt) then
         local oreConversion = self.conversions[storage.ore.name]
         local bar = {name = oreConversion[3], count = oreConversion[2], data = {}}

         if self.smeltTimer > self.smeltRate then
            local out = world.containerPutItemsAt(entity.id(), bar, 1)
            if oreConversion and out == 0 or out == nil then
               storage.ore = {}
               animator.setAnimationState("smelting", "smelt")
            else
               if storage.ore ~= nil and storage.ore.name ~= nil then
                  sb.logInfo(string.format("Ores: %s (%dx) - %s", storage.ore.name, storage.ore.count, sb.print(out)))
                  sb.logInfo(string.format("oreConversion[1]: %d, storage.ore.count: %d", sb.print(oreConversion[1]), sb.print(storage.ore.count)))
               end
            end
            self.smeltTimer = 0
         end
         self.smeltTimer = self.smeltTimer + dt
      else
         animator.setAnimationState("smelting", "error")
      end
   end
end

function pullOre()
   storage.ore = {}
   local pullFilter = {}
   for matitem,conversion in pairs(self.conversions) do
      pullFilter[matitem] = {conversion[1], conversion[1]}
   end
   local pulledItem = pullItem(1, pullFilter)
   if pulledItem then
      storage.ore = pulledItem
   end
end

function onItemPut(item, nodeId)
   if item and nodeId == 1 and storage.ore.name == nil then
      if self.conversions[item.name] then
         local conversion = self.conversions[item.name]
         if item.count < conversion[1] then
            return false
         elseif item.count == conversion[1] then
            storage.ore = item
            return true --used whole stack
         else
            item.count = conversion[1]
            storage.ore = item
            return conversion[1] --return amount used
         end
      end
   end
   return false
end

function beforeItemPut(item, nodeId)
   if item and nodeId == 1 and storage.ore.name == nil then
      local pullFilter = {}
      for ore,_ in pairs(self.conversions) do
         if ore == item.name then return true end
      end
   end
   return false
end

--Temporary function until itempipes api is changed to allow amount filters and returns
function ejectOre()
   local position = entity.position()
   if storage.ore.name and (storage.ore.data == nil or next(storage.ore.data) == nil) then
      world.spawnItem(storage.ore.name, {position[1] + 1.5, position[2] + 1}, storage.ore.count)
   elseif storage.ore.name then
      world.spawnItem(storage.ore.name, {position[1] + 1.5, position[2] + 1}, storage.ore.count, storage.ore.data)
   end
   storage.ore = {}
end
