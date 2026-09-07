-- ============================================================================
-- BUCU Multicharacter — Server Management Engine
-- Handles character queries, registration, starter packs, and session loading
-- ============================================================================

-- Helper: Extract all potential license & player identifier patterns for this client
local function GetPlayerAllIdentifierPatterns(source)
    local patterns = {}
    local seen = {}

    local function addPattern(pat)
        if pat and pat ~= '' and not seen[pat] then
            seen[pat] = true
            table.insert(patterns, pat)
        end
    end

    local numIdentifiers = GetNumPlayerIdentifiers(source)
    for i = 0, numIdentifiers - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            addPattern(id .. ':%')
            -- Check for raw hex hash (e.g. if id is license:abcdef..., add %:abcdef...:%)
            local raw = string.gsub(id, '^%a+%d*:', '')
            if raw and raw ~= '' and raw ~= id then
                addPattern('%:' .. raw .. ':%')
                addPattern('license:' .. raw .. ':%')
                addPattern('license2:' .. raw .. ':%')
            end
        end
    end

    if GetPlayerIdentifierByType then
        local lic = GetPlayerIdentifierByType(source, 'license')
        if lic and lic ~= '' then
            local full = (string.sub(lic, 1, 8) == 'license:') and lic or ('license:' .. lic)
            addPattern(full .. ':%')
            local raw = string.gsub(lic, '^license:', '')
            addPattern('%:' .. raw .. ':%')
        end
        local lic2 = GetPlayerIdentifierByType(source, 'license2')
        if lic2 and lic2 ~= '' then
            local full = (string.sub(lic2, 1, 9) == 'license2:') and lic2 or ('license2:' .. lic2)
            addPattern(full .. ':%')
            local raw = string.gsub(lic2, '^license2:', '')
            addPattern('%:' .. raw .. ':%')
        end
    end

    -- Standalone / dev fallback
    addPattern('license:' .. tostring(source) .. ':%')

    return patterns
end

local function GetPlayerIdentifierKey(source)
    if GetPlayerIdentifierByType then
        local lic = GetPlayerIdentifierByType(source, 'license')
        if lic and lic ~= '' then
            return (string.sub(lic, 1, 8) == 'license:') and lic or ('license:' .. lic)
        end
        local lic2 = GetPlayerIdentifierByType(source, 'license2')
        if lic2 and lic2 ~= '' then
            return (string.sub(lic2, 1, 9) == 'license2:') and lic2 or ('license2:' .. lic2)
        end
    end

    local numIdentifiers = GetNumPlayerIdentifiers(source)
    for i = 0, numIdentifiers - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and string.sub(id, 1, 8) == 'license:' then
            return id
        end
    end
    for i = 0, numIdentifiers - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and string.sub(id, 1, 9) == 'license2:' then
            return id
        end
    end
    for i = 0, numIdentifiers - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and string.sub(id, 1, 6) == 'steam:' then
            return id
        end
    end
    -- Fallback jika license tidak ditemukan
    return 'license:' .. tostring(source)
end

-- Validasi Nama (Hanya huruf alfabet, panjang 2-25)
local function IsValidName(name)
    if not name or type(name) ~= 'string' then return false end
    local clean = string.gsub(name, '^%s*(.-)%s*$', '%1')
    if string.len(clean) < 2 or string.len(clean) > 25 then return false end
    return string.match(clean, '^[%a%s]+$') ~= nil
end

-- Validasi Tanggal Lahir (Format YYYY-MM-DD, usia 18 s/d 90 tahun)
local function IsValidDOB(dob)
    if not dob or type(dob) ~= 'string' then return false end
    local y, m, d = string.match(dob, '^(%d%d%d%d)-(%d%d)-(%d%d)$')
    if not y or not m or not d then return false end
    local year = tonumber(y)
    local month = tonumber(m)
    local day = tonumber(d)
    if month < 1 or month > 12 or day < 1 or day > 31 then return false end

    local currentYear = 2026
    local age = currentYear - year
    return age >= 18 and age <= 90
end

-- ----------------------------------------------------------------------------
-- Ambil Semua Karakter Pemain (Slots 1 - 4)
-- ----------------------------------------------------------------------------
RegisterNetEvent('bucu:multicharacter:server:getCharacters', function()
    local src = source
    local patterns = GetPlayerAllIdentifierPatterns(src)
    local maxSlots = MulticharConfig.MaxSlots or 4

    if not MySQL or not MySQL.query then
        -- Standalone Memory / Mock Fallback (oxmysql tidak tersedia)
        TriggerClientEvent('bucu:multicharacter:client:setupUI', src, {
            characters = {},
            charactersList = {},
            maxSlots = maxSlots
        })
        return
    end

    local conds = {}
    for _ in ipairs(patterns) do
        table.insert(conds, "c.identifier LIKE ?")
    end
    local whereSql = table.concat(conds, " OR ")

    local query = string.format([[
        SELECT c.id, c.identifier, c.firstname, c.lastname, c.date_of_birth, c.gender, c.phone_number, c.metadata,
               j.job_name, j.job_grade,
               acc_cash.balance AS cash, acc_bank.balance AS bank
        FROM bucu_characters c
        LEFT JOIN bucu_jobs j ON j.character_id = c.id
        LEFT JOIN bucu_accounts acc_cash ON (acc_cash.character_id = c.id AND acc_cash.account_type = 'cash')
        LEFT JOIN bucu_accounts acc_bank ON (acc_bank.character_id = c.id AND acc_bank.account_type = 'bank')
        WHERE %s
        ORDER BY c.id ASC
    ]], whereSql)

    MySQL.query(query, patterns, function(rows)
        local characters = {}
        local citizenIds = {}

        if rows and #rows > 0 then
            for _, row in ipairs(rows) do
                local slotStr = string.match(row.identifier, ':(%d+)$')
                local slot = tonumber(slotStr) or 1
                local meta = {}
                if row.metadata and type(row.metadata) == 'string' and row.metadata ~= '' then
                    pcall(function() meta = json.decode(row.metadata) end)
                end

                local citId = (meta and meta.citizenid) or ('BUCU-' .. tostring(row.id))
                table.insert(citizenIds, citId)

                characters[slot] = {
                    id = row.id,
                    slot = slot,
                    identifier = row.identifier,
                    citizenid = citId,
                    firstname = row.firstname,
                    lastname = row.lastname,
                    fullname = row.firstname .. ' ' .. row.lastname,
                    dob = row.date_of_birth,
                    gender = row.gender,
                    phone = row.phone_number or (meta and meta.phone) or '555-' .. string.format('%04d', row.id),
                    job = row.job_name or 'unemployed',
                    jobGrade = row.job_grade or 0,
                    cash = row.cash or 1000,
                    bank = row.bank or 5000,
                    lastCoords = meta and meta.lastCoords,
                    avatar = (meta and meta.avatar) or 'images/default_avatar.png',
                    nationality = (meta and meta.nationality) or 'San Andreas',
                    skin_model = nil,
                    skin_data = nil
                }
            end
        end

        local function sendCharactersToClient()
            local charMap = {}
            local charList = {}
            for slot, char in pairs(characters) do
                charMap[slot] = char
                charMap[tostring(slot)] = char
                table.insert(charList, char)
            end

            -- Sort list by slot ascending
            table.sort(charList, function(a, b) return (a.slot or 0) < (b.slot or 0) end)

            TriggerClientEvent('bucu:multicharacter:client:setupUI', src, {
                characters = charMap,
                charactersList = charList,
                maxSlots = maxSlots
            })
        end

        -- Query skin data if any characters found
        if #citizenIds > 0 then
            MySQL.query('SELECT citizenid, model, skin_data FROM bucu_player_skins WHERE citizenid IN (?)', { citizenIds }, function(skinRows)
                if skinRows then
                    local skinMap = {}
                    for _, sk in ipairs(skinRows) do
                        skinMap[sk.citizenid] = sk
                    end

                    for slot, char in pairs(characters) do
                        local s = skinMap[char.citizenid]
                        if s then
                            char.skin_model = s.model
                            char.skin_data  = s.skin_data
                        end
                    end
                end

                sendCharactersToClient()
            end)
        else
            sendCharactersToClient()
        end
    end)
end)

-- ----------------------------------------------------------------------------
-- Registrasi Karakter Baru
-- ----------------------------------------------------------------------------
RegisterNetEvent('bucu:multicharacter:server:createCharacter', function(data)
    local src = source
    if not data or not data.slot then return end

    local slot = tonumber(data.slot)
    if not slot or slot < 1 or slot > (MulticharConfig.MaxSlots or 4) then
        TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = _U('err_max_slots') })
        return
    end

    if not IsValidName(data.firstname) or not IsValidName(data.lastname) then
        TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = _U('err_invalid_name') })
        return
    end

    if not IsValidDOB(data.dob) then
        TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = _U('err_invalid_dob') })
        return
    end

    local gender = (data.gender == 'female') and 'female' or 'male'
    local license = GetPlayerIdentifierKey(src)
    local charIdentifier = string.format('%s:%d', license, slot)
    local citizenId = BucuSharedHelpers.GenerateCitizenNumber()

    local initialMeta = {
        citizenid = citizenId,
        nationality = data.nationality or 'San Andreas',
        created_at = os.date('!%Y-%m-%d %H:%M:%SZ')
    }
    local metaStr = json and json.encode and json.encode(initialMeta) or '{}'

    if not MySQL or not MySQL.insert then
        -- Mock Callback
        TriggerClientEvent('bucu:multicharacter:client:charCreated', src, {
            slot = slot,
            citizenid = citizenId,
            firstname = data.firstname,
            lastname = data.lastname
        })
        return
    end

    -- 1. Insert ke bucu_characters
    local insertCharQuery = [[
        INSERT INTO bucu_characters (identifier, firstname, lastname, date_of_birth, gender, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
    ]]

    MySQL.insert(insertCharQuery, {
        charIdentifier,
        data.firstname,
        data.lastname,
        data.dob,
        gender,
        metaStr
    }, function(charId)
        if not charId or charId <= 0 then
            TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = _U('err_slot_occupied') })
            return
        end

        -- 2. Buat Rekening Awal ($1.000 Cash & $5.000 Bank)
        local initialCash = MulticharConfig.StarterPack.Cash or 1000
        local initialBank = MulticharConfig.StarterPack.Bank or 5000
        MySQL.execute("INSERT INTO bucu_accounts (character_id, account_type, balance) VALUES (?, 'cash', ?)", { charId, initialCash })
        MySQL.execute("INSERT INTO bucu_accounts (character_id, account_type, balance) VALUES (?, 'bank', ?)", { charId, initialBank })

        -- 3. Setel Pekerjaan Awal (unemployed)
        MySQL.execute("INSERT INTO bucu_jobs (character_id, job_name, job_grade, on_duty) VALUES (?, 'unemployed', 0, 1)", { charId })

        -- 4. Berikan Starter Pack Item ke bucu_inventory
        local idCardMeta = {
            name = data.firstname .. ' ' .. data.lastname,
            citizenid = citizenId,
            date_of_birth = data.dob,
            gender = gender,
            issued_date = os.date('!%Y-%m-%d')
        }

        if exports and exports['bucu_inventory'] then
            exports['bucu_inventory']:AddItem(citizenId, 'id_card', 1, 1, idCardMeta, 'pocket')
            exports['bucu_inventory']:AddItem(citizenId, 'phone', 1, 2, nil, 'pocket')
            exports['bucu_inventory']:AddItem(citizenId, 'bread', 2, 3, nil, 'pocket')
            exports['bucu_inventory']:AddItem(citizenId, 'water_bottle', 2, 4, nil, 'pocket')
        end

        TriggerClientEvent('bucu:notify:show', src, { type = 'success', text = _U('notif_char_created') })
        TriggerClientEvent('bucu:multicharacter:client:charCreated', src, {
            slot = slot,
            citizenid = citizenId,
            firstname = data.firstname,
            lastname = data.lastname
        })
    end)
end)

-- ----------------------------------------------------------------------------
-- Memilih Karakter yang Tersimpan
-- ----------------------------------------------------------------------------
RegisterNetEvent('bucu:multicharacter:server:selectCharacter', function(slot, citizenId, spawnId)
    local src = source
    local slotNum = tonumber(slot) or 1
    local license = GetPlayerIdentifierKey(src)
    local fallbackIdentifier = string.format('%s:%d', license, slotNum)

    local function finalizeSelection(charIdentifier, actualCitId, model, skinData)
        -- Inisialisasi Session di BUCU Core
        if BucuPlayerStorage and BucuPlayerStorage.LoadPlayer then
            BucuPlayerStorage.LoadPlayer(src, charIdentifier)
        end

        -- Set player state bags
        Player(src).state:set('citizenid', actualCitId, true)
        Player(src).state:set('charIdentifier', charIdentifier, true)

        -- Trigger event publik agar skrip lain tahu karakter sudah aktif
        TriggerEvent('bucu:player:loaded', src, {
            identifier = charIdentifier,
            citizenid = actualCitId,
            slot = slotNum
        })

        TriggerClientEvent('bucu:multicharacter:client:spawnSelectorReady', src, {
            slot = slotNum,
            citizenid = actualCitId,
            model = model or 'mp_m_freemode_01',
            skin = skinData,
            spawnId = spawnId or 'airport'
        })
    end

    if MySQL and MySQL.query then
        -- Lookup exact character record to get canonical identifier and metadata
        local lookupQuery = "SELECT id, identifier, metadata FROM bucu_characters WHERE identifier LIKE ? OR metadata LIKE ? LIMIT 1"
        local citPattern = '%"citizenid":"' .. tostring(citizenId or '') .. '"%'
        local slotPattern = '%:' .. tostring(slotNum)

        MySQL.query(lookupQuery, { slotPattern, citPattern }, function(charRows)
            local charIdentifier = fallbackIdentifier
            local realCitId = citizenId

            if charRows and charRows[1] then
                charIdentifier = charRows[1].identifier or fallbackIdentifier
                if (not realCitId or realCitId == '') and charRows[1].metadata then
                    pcall(function()
                        local m = json.decode(charRows[1].metadata)
                        if m and m.citizenid then realCitId = m.citizenid end
                    end)
                end
            end

            realCitId = realCitId or ('BUCU-' .. tostring(slotNum))

            MySQL.query('SELECT model, skin_data FROM bucu_player_skins WHERE citizenid = ?', { realCitId }, function(skinRows)
                local skinData = nil
                local model = nil
                if skinRows and skinRows[1] then
                    model = skinRows[1].model
                    if skinRows[1].skin_data and skinRows[1].skin_data ~= '' then
                        pcall(function() skinData = json.decode(skinRows[1].skin_data) end)
                    end
                end

                finalizeSelection(charIdentifier, realCitId, model, skinData)
            end)
        end)
    else
        finalizeSelection(fallbackIdentifier, citizenId or ('BUCU-' .. tostring(slotNum)), nil, nil)
    end
end)

-- ----------------------------------------------------------------------------
-- Hapus Karakter (Delete Profile)
-- ----------------------------------------------------------------------------
RegisterNetEvent('bucu:multicharacter:server:deleteCharacter', function(slot)
    local src = source
    local license = GetPlayerIdentifierKey(src)
    local charIdentifier = string.format('%s:%d', license, slot)

    if not MySQL or not MySQL.execute then return end

    local query = 'DELETE FROM bucu_characters WHERE identifier = ?'
    MySQL.execute(query, { charIdentifier }, function(rowsChanged)
        if rowsChanged and rowsChanged > 0 then
            TriggerClientEvent('bucu:notify:show', src, { type = 'info', text = _U('notif_char_deleted') })
            TriggerEvent('bucu:multicharacter:server:getCharacters')
        end
    end)
end)
