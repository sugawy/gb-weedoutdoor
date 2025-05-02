local QBCore = exports['qb-core']:GetCoreObject()

local tableCoords = vector3(-36.9, -2689.80, 6.0)
local propHash = `bkr_prop_weed_table_01a`
local spawnedTable, attachedProp, handProp = nil, nil, nil

function RemoveAttachedProp()
    if attachedProp and DoesEntityExist(attachedProp) then DeleteObject(attachedProp) end
    attachedProp = nil
end

function AttachPropToHand(propModel)
    local ped = PlayerPedId()
    local prop = CreateObject(GetHashKey(propModel), 0, 0, 0, true, true, true)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005), 0.12, 0.02, -0.02, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    handProp = prop
end

function RemoveHandProp()
    if handProp and DoesEntityExist(handProp) then DeleteObject(handProp) end
    handProp = nil
end

function SpawnWeedTable()
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do Wait(100) end

    if DoesEntityExist(spawnedTable) then DeleteEntity(spawnedTable) end

    spawnedTable = CreateObject(propHash, tableCoords.x, tableCoords.y, tableCoords.z - 1.0, true, false, false)
    FreezeEntityPosition(spawnedTable, true)
    SetEntityInvincible(spawnedTable, true)

    exports.ox_target:addLocalEntity(spawnedTable, {
        {
            label = "Process Weed Leafs",
            icon = "fas fa-cannabis",
            onSelect = function() OpenProcessingMenu() end
        },
        {
            label = "Pack Weed",
            icon = "fas fa-box",
            onSelect = function() OpenPackingMenu() end
        }
    })
end

CreateThread(function()
    Wait(500)
    SpawnWeedTable()
end)

function StartProcessing(time, label, animation, onComplete, propModel)
    local ped = PlayerPedId()
    if propModel then
        AttachPropToHand(propModel)
    end
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, animation, 0, true)
    local success = lib.progressBar({
        duration = time,
        label = label,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        }
    })
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    RemoveHandProp()
    if success then
        if onComplete then
            onComplete()
        end
    else
        lib.notify({ description = "Cancelled", type = "error" })
    end
end


lib.registerContext({
    id = 'weed_processing_menu',
    title = 'Process Weed Leafs',
    options = {
        {
            title = 'Process AK47',
            description = '1 AK47 Leaf → 1 AK47 Bud',
            icon = 'seedling',
            event = 'weedprocessing:processLeaf',
            args = { leaf = 'weed_ak47_leaf', bud = 'weed_ak47_bud' }
        },
        {
            title = 'Process AMNESIA',
            description = '1 Amnesia Leaf → 1 Amnesia Bud',
            icon = 'seedling',
            event = 'weedprocessing:processLeaf',
            args = { leaf = 'weed_amnesia_leaf', bud = 'weed_amnesia_bud' }
        },
        {
            title = 'Process PURPLE HAZE',
            description = '1 Purple Haze Leaf → 1 Purple Haze Bud',
            icon = 'seedling',
            event = 'weedprocessing:processLeaf',
            args = { leaf = 'weed_purple_haze_leaf', bud = 'weed_purple_haze_bud' }
        },
        {
            title = 'Process OG KUSH',
            description = '1 OG Kush Leaf → 1 OG Kush Bud',
            icon = 'seedling',
            event = 'weedprocessing:processLeaf',
            args = { leaf = 'weed_og_kush_leaf', bud = 'weed_og_kush_bud' }
        },
        {
            title = 'Process SKUNK',
            description = '1 Skunk Leaf → 1 Skunk Bud',
            icon = 'seedling',
            event = 'weedprocessing:processLeaf',
            args = { leaf = 'weed_skunk_leaf', bud = 'weed_skunk_bud' }
        },
        {
            title = 'Process WHITE WIDOW',
            description = '1 White Widow Leaf → 1 White Widow Bud',
            icon = 'seedling',
            event = 'weedprocessing:processLeaf',
            args = { leaf = 'weed_white_widow_leaf', bud = 'weed_white_widow_bud' }
        }
    }
})

function OpenProcessingMenu()
    lib.showContext('weed_processing_menu')
end



lib.registerContext({
    id = 'weed_packing_menu',
    title = 'Pack Weed',
    options = {
        {
            title = 'Pack AK47',
            description = '1 AK47 Bud + 1 Empty Bag',
            icon = 'box',
            event = 'weedprocessing:packWeed',
            args = { bud = 'weed_ak47_bud', packed = 'weed_ak47' }
        },
        {
            title = 'Pack AMNESIA',
            description = '1 Amnesia Bud + 1 Empty Bag',
            icon = 'box',
            event = 'weedprocessing:packWeed',
            args = { bud = 'weed_amnesia_bud', packed = 'weed_amnesia' }
        },
        {
            title = 'Pack PURPLE HAZE',
            description = '1 Purple Haze Bud + 1 Empty Bag',
            icon = 'box',
            event = 'weedprocessing:packWeed',
            args = { bud = 'weed_purple_haze_bud', packed = 'weed_purplehaze' }
        },
        {
            title = 'Pack OG KUSH',
            description = '1 OG Kush Bud + 1 Empty Bag',
            icon = 'box',
            event = 'weedprocessing:packWeed',
            args = { bud = 'weed_og_kush_bud', packed = 'weed_ogkush' }
        },
        {
            title = 'Pack SKUNK',
            description = '1 Skunk Bud + 1 Empty Bag',
            icon = 'box',
            event = 'weedprocessing:packWeed',
            args = { bud = 'weed_skunk_bud', packed = 'weed_skunk' }
        },
        {
            title = 'Pack WHITE WIDOW',
            description = '1 White Widow Bud + 1 Empty Bag',
            icon = 'box',
            event = 'weedprocessing:packWeed',
            args = { bud = 'weed_white_widow_bud', packed = 'weed_whitewidow' }
        }
    }
})

function OpenPackingMenu()
    lib.showContext('weed_packing_menu')
end



RegisterNetEvent("weedprocessing:processLeaf", function(data)
    lib.callback('weedprocessing:server:checkLeaf', false, function(hasItem)
        if hasItem then
            StartProcessing(12000, "Processing Weed...", "PROP_HUMAN_PARKING_METER", function()
                TriggerServerEvent("weedprocessing:server:processLeaf", data)
            end, "bkr_prop_weed_bud_01a")
        end
    end, data.leaf)
end)

RegisterNetEvent("weedprocessing:packWeed", function(data)
    lib.callback('weedprocessing:server:checkPack', false, function(hasItems)
        if hasItems then
            StartProcessing(8000, "Packing Weed...", "PROP_HUMAN_PARKING_METER", function()
                TriggerServerEvent("weedprocessing:server:packWeed", data)
            end, "sf_prop_sf_bag_weed_01b")
        end
    end, data.bud)
end)