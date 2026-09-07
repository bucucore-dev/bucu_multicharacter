-- ============================================================================
-- BUCU Multicharacter — Client Camera & 3D Ped Preview Controller
-- Manages interior loading, cinematic ped preview, skin applying & spawn
-- ============================================================================

local currentCam   = nil
local previewPed   = nil
local hasStarted   = false

-- ─── Helper: Request & Load Model ───────────────────────────────────────────

local function RequestAndLoadModel(hash)
    if not IsModelValid(hash) then return false end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 5000 do
        Wait(50); t = t + 50
    end
    return HasModelLoaded(hash)
end

-- ─── Helper: Apply Skin Data to Ped ─────────────────────────────────────────

local function ApplySkinToPed(ped, skin)
    if not ped or not DoesEntityExist(ped) or not skin then return end

    if exports['bucu_identity'] and exports['bucu_identity'].ApplySkinData then
        pcall(function() exports['bucu_identity']:ApplySkinData(ped, skin) end)
        return
    end

    -- Standalone fallback
    if skin.headBlend then
        local hb = skin.headBlend
        SetPedHeadBlendData(
            ped,
            tonumber(hb.shapeFirst or 0),
            tonumber(hb.shapeSecond or 21),
            0,
            tonumber(hb.skinFirst or hb.shapeFirst or 0),
            tonumber(hb.skinSecond or hb.shapeSecond or 21),
            0,
            (tonumber(hb.shapeMix or 0.5) + 0.0),
            (tonumber(hb.skinMix or 0.5) + 0.0),
            0.0,
            false
        )
    end
    if skin.faceFeatures then
        for i, v in pairs(skin.faceFeatures) do SetPedFaceFeature(ped, tonumber(i), tonumber(v) + 0.0) end
    end
    if skin.hair then
        SetPedComponentVariation(ped, 2, skin.hair.style or 0, 0, 2)
        SetPedHairColor(ped, skin.hair.color or 0, skin.hair.highlight or 0)
    end
    if skin.overlays then
        for i, ov in pairs(skin.overlays) do
            local idx = tonumber(i)
            SetPedHeadOverlay(ped, idx, ov.index or 255, (ov.opacity or 0) + 0.0)
            if ov.color1 then SetPedHeadOverlayColor(ped, idx, 1, ov.color1, ov.color2 or ov.color1) end
        end
    end
    if skin.components then
        for i, comp in pairs(skin.components) do
            SetPedComponentVariation(ped, tonumber(i), comp.drawable or 0, comp.texture or 0, 2)
        end
    end
    if skin.props then
        for i, prop in pairs(skin.props) do
            local propId = tonumber(i)
            if prop.drawable == nil or prop.drawable == -1 then
                ClearPedProp(ped, propId)
            else
                SetPedPropIndex(ped, propId, prop.drawable, prop.texture or 0, true)
            end
        end
    end
    if skin.eyeColor ~= nil then
        SetPedEyeColor(ped, tonumber(skin.eyeColor))
    end
end

local function GetActiveLocation()
    return (MulticharConfig.Locations and MulticharConfig.Locations[MulticharConfig.ActiveLocation]) or {
        pedCoords    = MulticharConfig.PedCoords,
        camCoords    = MulticharConfig.CamCoords,
        hiddenCoords = MulticharConfig.HiddenCoords,
        interior     = MulticharConfig.Interior,
        isIndoor     = MulticharConfig.Interior ~= nil,
        fov          = 48.0
    }
end

-- ─── Memulai Kamera Sinematik & Setup Interior ──────────────────────────────

local function StartCinematicCam()
    if hasStarted then return end
    hasStarted = true

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    DoScreenFadeOut(0)

    local activeLoc = GetActiveLocation()

    -- Sembunyikan player ped asli di bawah lantai
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, false, 0)
    FreezeEntityPosition(playerPed, true)
    SetEntityCoords(playerPed, activeLoc.hiddenCoords.x, activeLoc.hiddenCoords.y, activeLoc.hiddenCoords.z, false, false, false, true)

    -- Muat Interior hanya jika lokasi indoor
    if activeLoc.isIndoor and activeLoc.interior then
        local interior = GetInteriorAtCoords(
            activeLoc.interior.x,
            activeLoc.interior.y,
            activeLoc.interior.z - 18.9
        )
        LoadInterior(interior)
        local t = 0
        while not IsInteriorReady(interior) and t < 5000 do
            Wait(100); t = t + 100
        end
    end

    -- Buat Kamera Menghadap Ped Coords
    local pedPos = activeLoc.pedCoords
    local camPos = activeLoc.camCoords

    currentCam = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        camPos.x, camPos.y, camPos.z,
        0.0, 0.0, camPos.w,
        activeLoc.fov or 48.0,
        false, 2
    )

    SetCamActive(currentCam, true)
    RenderScriptCams(true, false, 1, true, true)
    PointCamAtCoord(currentCam, pedPos.x, pedPos.y, pedPos.z + 0.15)
    SetTimecycleModifier('default')

    -- Ensure bright daytime lighting
    NetworkOverrideClockTime(13, 0, 0)
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')

    -- Studio illumination loop for multicharacter preview
    CreateThread(function()
        while hasStarted do
            Wait(0)
            if previewPed and DoesEntityExist(previewPed) then
                local pCoords = GetEntityCoords(previewPed)
                local rad = math.rad(pedPos.w or 330.0)
                local forward = vector3(-math.sin(rad), math.cos(rad), 0.0)
                -- Key light
                local kPos = pCoords + (forward * 1.8) + vector3(0.0, 0.0, 0.7)
                DrawLightWithRange(kPos.x, kPos.y, kPos.z, 255, 245, 235, 4.0, 2.8)
                -- Fill light
                local fPos = pCoords + vector3(0.0, 0.0, 2.2)
                DrawLightWithRange(fPos.x, fPos.y, fPos.z, 210, 225, 255, 3.5, 1.2)
            end
        end
    end)

    Wait(300)
    DoScreenFadeIn(800)

    -- Minta data karakter dari server
    TriggerServerEvent('bucu:multicharacter:server:getCharacters')
end

-- ─── Spawn Preview Ped untuk Slot Terpilih ───────────────────────────────────

function SpawnPreviewPed(charData)
    -- Hapus preview ped sebelumnya
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end

    if not charData then return end

    local modelName = charData.skin_model
    if not modelName or modelName == '' then
        modelName = (charData.gender == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    end

    local hash = GetHashKey(modelName)
    if not RequestAndLoadModel(hash) then
        print('^1[bucu_multicharacter]^7 Failed to load model: ' .. tostring(modelName))
        return
    end

    local activeLoc = GetActiveLocation()
    local pCoords = activeLoc.pedCoords
    previewPed = CreatePed(2, hash, pCoords.x, pCoords.y, pCoords.z - 0.98, pCoords.w, false, true)

    if not previewPed or previewPed == 0 then return end

    SetEntityHeading(previewPed, pCoords.w)
    FreezeEntityPosition(previewPed, false)
    SetEntityInvincible(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    PlaceObjectOnGroundProperly(previewPed)

    -- Putar animasi idle santai
    local animDict = 'amb@world_human_stand_impatient@male@no_sign@idle_a'
    local animName = 'idle_a'
    RequestAnimDict(animDict)
    local t = 0
    while not HasAnimDictLoaded(animDict) and t < 2000 do
        Wait(50); t = t + 50
    end
    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(previewPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    -- Terapkan skin jika ada data skin
    local skinRaw = charData.skin_data or charData.skin
    if skinRaw then
        local skinObj = skinRaw
        if type(skinObj) == 'string' then
            pcall(function() skinObj = json.decode(skinObj) end)
        end
        if type(skinObj) == 'table' then
            ApplySkinToPed(previewPed, skinObj)
        end
    end

    SetModelAsNoLongerNeeded(hash)
end

function RotatePreviewPed(angle)
    if previewPed and DoesEntityExist(previewPed) then
        local currentHeading = GetEntityHeading(previewPed)
        SetEntityHeading(previewPed, currentHeading + (tonumber(angle) or 0))
    end
end

-- ─── Hook Lifecycle ──────────────────────────────────────────────────────────

AddEventHandler('playerActivated', function()
    CreateThread(function()
        Wait(500)
        StartCinematicCam()
    end)
end)

AddEventHandler('onClientGameTypeStart', function()
    CreateThread(function()
        Wait(1000)
        StartCinematicCam()
    end)
end)

-- ─── Event Spawn Pemain ke Titik Terpilih ────────────────────────────────────

RegisterNetEvent('bucu:multicharacter:client:spawnPlayer', function(spawnId, charData)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end

    -- Hapus preview ped
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end

    -- Cari koordinat spawn yang dipilih
    local targetCoords = nil
    for _, sp in ipairs(MulticharConfig.Spawns) do
        if sp.id == spawnId then
            targetCoords = sp.coords
            break
        end
    end

    if not targetCoords then
        targetCoords = MulticharConfig.Spawns[1].coords
    end

    -- 1. Transform PlayerPedId() from default Michael into the saved character model & skin
    if charData then
        local model = charData.model or charData.skin_model or (charData.gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01')
        local hash  = type(model) == 'number' and model or GetHashKey(model)
        if RequestAndLoadModel(hash) then
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
        end

        local ped = PlayerPedId()
        SetPedDefaultComponentVariation(ped)

        local skinData = charData.skin or charData.skin_data
        if type(skinData) == 'string' then
            pcall(function() skinData = json.decode(skinData) end)
        end
        if skinData and type(skinData) == 'table' then
            ApplySkinToPed(ped, skinData)
        end

        if charData.citizenid then
            LocalPlayer.state:set('citizenid', charData.citizenid, true)
        end
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    RequestCollisionAtCoord(targetCoords.x, targetCoords.y, targetCoords.z)
    SetEntityCoordsNoOffset(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)
    SetEntityHeading(ped, targetCoords.h or 0.0)

    local colTimeout = 0
    while not HasCollisionLoadedAroundEntity(ped) and colTimeout < 2000 do
        Wait(50)
        colTimeout = colTimeout + 50
    end

    PlaceObjectOnGroundProperly(ped)
    SetEntityVisible(ped, true, 0)
    FreezeEntityPosition(ped, false)

    -- Hancurkan kamera sinematik
    if currentCam and DoesCamExist(currentCam) then
        DestroyCam(currentCam, false)
        RenderScriptCams(false, false, 0, true, true)
        currentCam = nil
    end

    ClearTimecycleModifier()

    Wait(500)
    DoScreenFadeIn(1000)

    TriggerEvent('bucu:client:onPlayerSpawned', targetCoords)
    if charData then
        TriggerEvent('bucu:player:clientLoaded', charData)
    end
end)

-- Bersihkan ped saat resource dihentikan
AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end
    if currentCam and DoesCamExist(currentCam) then
        DestroyCam(currentCam, false)
        RenderScriptCams(false, false, 0, true, true)
    end
end)
