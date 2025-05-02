local QBCore = exports['qb-core']:GetCoreObject()

local spawnedPlantObjects = {}

local function OpenPlantStatusUI(plant)
    lib.registerContext({
        id = 'plant_status_context',
        title = plant.label or '🌿 Plant Status',
        options = {
            {
                title = 'Health',
                icon = 'heartbeat',
                description = tostring(plant.health or 0) .. '%'
            },
            {
                title = 'Food',
                icon = 'utensils',
                description = tostring(plant.food or 0) .. '%'
            },
            {
                title = 'Water',
                icon = 'tint',
                description = tostring(plant.water or 0) .. '%'
            },
            {
                title = 'Progress',
                icon = 'chart-line',
                description = tostring(plant.progress or 0) .. '%'
            },
            {
                title = 'Stage',
                icon = 'seedling',
                description = tostring(plant.stage or 'Unknown')
            }
        }
    })

    lib.showContext('plant_status_context')
end


local function CreateWeedPlant(plant)
    if not plant or not plant.coords or not plant.id then return nil end
    local coords = (type(plant.coords) == "string") and json.decode(plant.coords) or plant.coords
    local model = GetHashKey(plant.model)

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)

    exports.ox_target:addLocalEntity(obj, {
        {
            label = "Check Plant Status",
            icon = "fas fa-leaf",
            onSelect = function()
                TriggerServerEvent('weed:server:getPlantStatus', plant.id)
            end
        },
        {
            label = "Harvest Plant",
            icon = "fas fa-scissors",
            onSelect = function()
                TriggerServerEvent('weed:server:harvestPlant', plant.id)
            end
        },
        {
            label = "Feed Plant",
            icon = "fas fa-shield-alt",
            onSelect = function()
                TriggerServerEvent('weed:server:feedPlant', plant.id)
            end
        },
        {
            label = "Water Plant",
            icon = "fas fa-tint",
            onSelect = function()
                TriggerServerEvent('weed:server:waterPlant', plant.id)
            end
        }
    })

    return obj
end

local function spawnOutdoorPlants(plants)
    for _, obj in pairs(spawnedPlantObjects) do
        if DoesEntityExist(obj) then DeleteObject(obj) end
    end
    spawnedPlantObjects = {}

    for _, plant in pairs(plants) do
        local obj = CreateWeedPlant(plant)
        if obj then spawnedPlantObjects[plant.id] = obj end
    end
end

RegisterNetEvent('weed:client:syncPlants', function(plants)
    spawnOutdoorPlants(plants)
end)

RegisterNetEvent('weed:client:updatePlantStage', function(plant)
    local obj = spawnedPlantObjects[plant.id]
    if obj and DoesEntityExist(obj) then
        DeleteObject(obj)
        spawnedPlantObjects[plant.id] = nil
    end
    local newObj = CreateWeedPlant(plant)
    if newObj then spawnedPlantObjects[plant.id] = newObj end
end)

RegisterNetEvent('weed:client:updatePlantStatus', function(plant)
    OpenPlantStatusUI(plant)
end)

RegisterNetEvent('weed:client:useSeed', function(seedType)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return
    end
    TaskStartScenarioInPlace(ped, "world_human_gardener_plant", 0, true)
    local success = lib.progressBar({
        duration = 5000,
        label = 'Planting Seed...',
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        }
    })
    ClearPedTasksImmediately(ped)
    if success then
        TriggerServerEvent('weed:server:plantSeed', GetEntityCoords(ped), seedType)
    else
    end
end)

RegisterNetEvent('weed:client:addNewPlant', function(plant)
    if not plant or not plant.coords or not plant.id then return end
    local obj = CreateWeedPlant(plant)
    if obj then spawnedPlantObjects[plant.id] = obj end
end)

RegisterNetEvent('weed:client:removePlant', function(plantId)
    local obj = spawnedPlantObjects[plantId]
    if obj and DoesEntityExist(obj) then DeleteObject(obj) end
    spawnedPlantObjects[plantId] = nil
end)

CreateThread(function()
    TriggerServerEvent('weed:server:syncPlants')
end)
