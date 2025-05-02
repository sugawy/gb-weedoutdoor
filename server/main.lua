local QBCore = exports['qb-core']:GetCoreObject()

local seedTypes = {
    "ogkush",
    "amnesia",
    "ak47",
    "purplehaze",
    "skunk",
    "whitewidow"
}

for _, seed in ipairs(seedTypes) do
    exports.qbx_core:CreateUseableItem("weed_" .. seed .. "_seed", function(source, item)
        TriggerClientEvent('weed:client:useSeed', source, seed)
    end)
end

local function getPlantById(plantId)
    local result = MySQL.query.await('SELECT * FROM weed_plants WHERE id = ?', { plantId })
    return result and result[1] or nil
end

RegisterNetEvent('weed:server:plantSeed', function(coords, weedType)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)

    if not QBWeed.Plants[weedType] then
        lib.notify(src, { description = 'Invalid seed type: ' .. tostring(weedType), type = 'error' })
        return
    end

    if Player.Functions.RemoveItem('weed_' .. weedType .. '_seed', 1) then
        local plantCfg = QBWeed.Plants[weedType]
        local newPlant = {
            coords = coords,
            model = plantCfg.stages[1],
            label = plantCfg.label,
            stage = 1,
            health = 100,
            food = 100,
            water = 100,
            progress = 0,
            sort = weedType,
        }

        MySQL.insert('INSERT INTO weed_plants (coords, model, label, stage, health, food, water, progress, sort) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            json.encode(newPlant.coords),
            newPlant.model,
            newPlant.label,
            newPlant.stage,
            newPlant.health,
            newPlant.food,
            newPlant.water,
            newPlant.progress,
            newPlant.sort
        }, function(insertId)
            TriggerClientEvent('weed:client:addNewPlant', -1, {
                id = insertId,
                coords = newPlant.coords,
                model = newPlant.model,
                label = newPlant.label,
                stage = newPlant.stage,
                health = newPlant.health,
                food = newPlant.food,
                water = newPlant.water,
                progress = newPlant.progress,
                sort = newPlant.sort
            })
            lib.notify(src, { description = 'Seed planted successfully!', type = 'success' })
        end)
    else
        lib.notify(src, { description = 'You do not have the required seeds.', type = 'error' })
    end
end)

local function updatePlantResource(src, plantId, resource, requiredItem, amount, verb)
    local Player = exports.qbx_core:GetPlayer(src)
    local plant = getPlantById(plantId)
    if not plant then
        lib.notify(src, { description = 'This plant no longer exists.', type = 'error' })
        return
    end

    if plant[resource] >= 100 then
        lib.notify(src, { description = 'The plant does not need ' .. verb .. '.', type = 'error' })
        return
    end

    if Player.Functions.GetItemByName(requiredItem) then
        if Player.Functions.RemoveItem(requiredItem, 1) then
            local newValue = math.min(100, plant[resource] + amount)
            MySQL.update('UPDATE weed_plants SET ' .. resource .. ' = ? WHERE id = ?', { newValue, plantId })
            lib.notify(src, { description = ('You %s the plant. %s: %d%%'):format(verb, resource:sub(1,1):upper() .. resource:sub(2), newValue), type = 'success' })
        else
            lib.notify(src, { description = 'Failed to remove item.', type = 'error' })
        end
    else
        lib.notify(src, { description = 'You need ' .. requiredItem:gsub("_", " ") .. '!', type = 'error' })
    end
end

RegisterNetEvent('weed:server:feedPlant', function(plantId)
    updatePlantResource(source, plantId, "food", "weed_nutrition", 20, "fed")
end)

RegisterNetEvent('weed:server:waterPlant', function(plantId)
    updatePlantResource(source, plantId, "water", "water", 20, "watered")
end)

RegisterNetEvent('weed:server:harvestPlant', function(plantId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    local plant = getPlantById(plantId)
    if not plant then
        lib.notify(src, { description = 'This plant no longer exists.', type = 'error' })
        return
    end

    local plantCfg = QBWeed.Plants[plant.sort]
    if not plantCfg then
        lib.notify(src, { description = 'Invalid plant data.', type = 'error' })
        return
    end

    if plant.stage < plantCfg.highestStage then
        lib.notify(src, { description = 'This plant is not ready for harvest yet.', type = 'error' })
        return
    end

    local leafMap = {
        ogkush = 'weed_ogkush_leaf',
        amnesia = 'weed_amnesia_leaf',
        ak47 = 'weed_ak47_leaf',
        purplehaze = 'weed_purple_haze_leaf',
        skunk = 'weed_skunk_leaf',
        whitewidow = 'weed_white_widow_leaf'
    }

    local leafItem = leafMap[plant.sort] or 'weed_leaf'
    local amount = math.random(2, 5)
    Player.Functions.AddItem(leafItem, amount)

    MySQL.execute('DELETE FROM weed_plants WHERE id = ?', { plantId })
    local allPlants = MySQL.query.await('SELECT * FROM weed_plants')
    TriggerClientEvent('weed:client:syncPlants', -1, allPlants)

    lib.notify(src, { description = ('You harvested the plant and received %dx %s!'):format(amount, leafItem), type = 'success' })
end)

RegisterNetEvent('weed:server:getPlantStatus', function(plantId)
    local src = source
    local plant = getPlantById(plantId)
    TriggerClientEvent('weed:client:updatePlantStatus', src, plant or nil)
end)

CreateThread(function()
    while true do
        local plants = MySQL.query.await('SELECT * FROM weed_plants')
        for _, plant in pairs(plants) do
            local cfg = QBWeed.Plants[plant.sort]
            if cfg then
                local health = plant.health or 0
                if health > 50 then
                    local progressGain = math.random(QBWeed.Progress.min, QBWeed.Progress.max)
                    plant.progress = plant.progress + progressGain

                    if plant.progress >= 100 and plant.stage < cfg.highestStage then
                        plant.stage = plant.stage + 1
                        plant.progress = 0
                        plant.model = cfg.stages[plant.stage]
                    end
                end

                local newFood = math.max(0, plant.food - QBWeed.FoodUsage)
                local newWater = math.max(0, plant.water - QBWeed.WaterUsage)

                if newFood <= 0 and newWater <= 0 then
                    health = math.max(0, health - math.random(5, 10))
                elseif newFood > 0 and newWater > 0 and health < 100 then
                    health = math.min(100, health + math.random(3, 7))
                end

                if health <= 0 then
                    MySQL.execute('DELETE FROM weed_plants WHERE id = ?', { plant.id })
                    TriggerClientEvent('weed:client:removePlant', -1, plant.id)
                else
                    MySQL.update('UPDATE weed_plants SET stage=?, progress=?, model=?, food=?, water=?, health=? WHERE id=?', {
                        plant.stage, plant.progress, plant.model, newFood, newWater, health, plant.id
                    })
                end
            end
        end

        local updatedPlants = MySQL.query.await('SELECT * FROM weed_plants')
        TriggerClientEvent('weed:client:syncPlants', -1, updatedPlants)
        Wait(QBWeed.GrowthTick * 60000)
    end
end)

function FormatItemName(item)
    return item:gsub("weed_", ""):gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

lib.callback.register('weedprocessing:server:checkLeaf', function(source, leaf)
    local Player = exports.qbx_core:GetPlayer(source)
    local hasLeaf = Player.Functions.GetItemByName(leaf) ~= nil
    if not hasLeaf then
        lib.notify(source, { description = "You are missing " .. FormatItemName(leaf):gsub(" Leaf", "") .. " Leaf!", type = "error" })
    end
    return hasLeaf
end)

RegisterNetEvent("weedprocessing:server:processLeaf", function(data)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if Player.Functions.RemoveItem(data.leaf, 1) then
        Player.Functions.AddItem(data.bud, 1)
        lib.notify(src, { description = "Processed 1x " .. FormatItemName(data.leaf):gsub(" Leaf", "") .. " Leaf into 1x " .. FormatItemName(data.bud) .. " Bud!", type = "success" })
    else
        lib.notify(src, { description = "You are missing " .. FormatItemName(data.leaf) .. " Leaf!", type = "error" })
    end
end)

lib.callback.register('weedprocessing:server:checkPack', function(source, bud)
    local Player = exports.qbx_core:GetPlayer(source)
    local hasBud = Player.Functions.GetItemByName(bud) ~= nil
    local hasBag = Player.Functions.GetItemByName("empty_weed_bag") ~= nil

    if not hasBud and not hasBag then
        lib.notify(source, { description = "You are missing " .. FormatItemName(bud):gsub(" Bud", "") .. " Bud & an Empty Bag!", type = "error" })
    elseif not hasBud then
        lib.notify(source, { description = "You are missing " .. FormatItemName(bud):gsub(" Bud", "") .. " Bud!", type = "error" })
    elseif not hasBag then
        lib.notify(source, { description = "You are missing Empty Bags!", type = "error" })
    end

    return hasBud and hasBag
end)

local BudToWeed = {
    ["weed_ak47_bud"] = "weed_ak47",
    ["weed_amnesia_bud"] = "weed_amnesia",
    ["weed_purple_haze_bud"] = "weed_purplehaze",
    ["weed_og_kush_bud"] = "weed_ogkush",
    ["weed_skunk_bud"] = "weed_skunk",
    ["weed_white_widow_bud"] = "weed_whitewidow"
}

RegisterNetEvent("weedprocessing:server:packWeed", function(data)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    local packedWeed = BudToWeed[data.bud]
    if not packedWeed then
        lib.notify(src, { description = "Invalid weed strain!", type = "error" })
        return
    end
    if Player.Functions.GetItemByName(data.bud) and Player.Functions.GetItemByName("empty_weed_bag") then
        Player.Functions.RemoveItem(data.bud, 1)
        Player.Functions.RemoveItem("empty_weed_bag", 1)
        Player.Functions.AddItem(packedWeed, 1)
        lib.notify(src, { description = "Packed 1x " .. FormatItemName(data.bud):gsub(" Bud", "") .. " Bud into 1x " .. FormatItemName(packedWeed) .. "!", type = "success" })
    else
        lib.notify(src, { description = "You don't have the required items!", type = "error" })
    end
end)
