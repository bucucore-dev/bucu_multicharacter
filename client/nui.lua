-- ============================================================================
-- BUCU Multicharacter — Client NUI Bridge
-- Handles NUI callbacks and triggers server actions & ped previews
-- ============================================================================

local isUIOpen = false

RegisterNetEvent('bucu:multicharacter:client:setupUI', function(data)
    isUIOpen = true
    SetNuiFocus(true, true)

    -- Ambil karakter pertama untuk auto-preview jika ada
    local firstChar = nil
    if data.charactersList and #data.charactersList > 0 then
        firstChar = data.charactersList[1]
    elseif data.characters then
        for i = 1, (data.maxSlots or 4) do
            local c = data.characters[i] or data.characters[tostring(i)]
            if c then
                firstChar = c
                break
            end
        end
    end

    if firstChar then
        SpawnPreviewPed(firstChar)
    end

    SendNUIMessage({
        action = 'open',
        language = MulticharConfig.Language or 'en',
        locales = Locales[MulticharConfig.Language or 'en'] or Locales['en'],
        characters = data.characters,
        charactersList = data.charactersList,
        maxSlots = data.maxSlots or 4,
        spawns = MulticharConfig.Spawns
    })
end)

local activeCharData = nil

RegisterNetEvent('bucu:multicharacter:client:charCreated', function(newCharData)
    activeCharData = newCharData
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action    = 'showSpawnSelector',
        character = newCharData,
        spawns    = MulticharConfig.Spawns,
        locales   = Locales and (Locales[MulticharConfig.Language or 'en'] or Locales['en']) or {}
    })
end)

RegisterNetEvent('bucu:multicharacter:client:spawnSelectorReady', function(data)
    activeCharData = data
    if data and data.spawnId then
        -- Direct spawn at selected location
        TriggerEvent('bucu:multicharacter:client:spawnPlayer', data.spawnId, activeCharData)
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        isUIOpen = false
        return
    end

    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action    = 'showSpawnSelector',
        character = data,
        spawns    = MulticharConfig.Spawns,
        locales   = Locales and (Locales[MulticharConfig.Language or 'en'] or Locales['en']) or {}
    })
end)

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────

-- Dipanggil saat pemain mengklik slot karakter di antarmuka (untuk live 3D preview)
RegisterNUICallback('selectSlot', function(data, cb)
    if data and data.character then
        SpawnPreviewPed(data.character)
    else
        -- Jika slot kosong, hapus ped preview
        SpawnPreviewPed(nil)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('rotatePed', function(data, cb)
    RotatePreviewPed(data and data.angle or 0)
    if cb then cb('ok') end
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    if data and data.slot then
        activeCharData = data.character or { slot = data.slot, citizenid = data.citizenid }
        local spawnId = data.spawnId or 'airport'
        TriggerServerEvent('bucu:multicharacter:server:selectCharacter', data.slot, data.citizenid, spawnId)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('createCharacter', function(data, cb)
    TriggerServerEvent('bucu:multicharacter:server:createCharacter', data)
    if cb then cb('ok') end
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    if data and data.slot then
        TriggerServerEvent('bucu:multicharacter:server:deleteCharacter', data.slot)
        SpawnPreviewPed(nil)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('selectSpawn', function(data, cb)
    if data and data.spawnId then
        TriggerEvent('bucu:multicharacter:client:spawnPlayer', data.spawnId, activeCharData)
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        isUIOpen = false
    end
    if cb then cb('ok') end
end)

-- ─── Route to bucu_identity if installed ─────────────────────────────────────
RegisterNUICallback('openIdentityCreator', function(data, cb)
    local slot = (data and data.slot) or 1

    -- Hapus preview ped sebelum masuk ke creator
    SpawnPreviewPed(nil)

    -- Check if bucu_identity resource is started
    if GetResourceState('bucu_identity') == 'started' then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        isUIOpen = false

        -- Buka identity creator via export
        exports['bucu_identity']:OpenCreator(slot)

        if cb then cb({ identityHandled = true }) end
    else
        if cb then cb({ identityHandled = false }) end
    end
end)
