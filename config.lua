-- ============================================================================
-- BUCU Multicharacter — Specific Configuration
-- ============================================================================

MulticharConfig = MulticharConfig or {}

MulticharConfig.Language = (Config and Config.Language) or 'en'
MulticharConfig.MaxSlots = 4

-- Starter Pack untuk Karakter Baru
MulticharConfig.StarterPack = {
    Cash = 1000,
    Bank = 5000,
    Items = {
        { name = 'id_card', count = 1 },
        { name = 'phone', count = 1 },
        { name = 'bread', count = 2 },
        { name = 'water_bottle', count = 2 }
    }
}

-- Titik Spawn Awal yang Tersedia (Bandara, Pelabuhan & Stasiun Kereta)
MulticharConfig.Spawns = {
    {
        id = 'airport',
        icon = '🛫',
        tag = 'UDARA',
        name = 'Bandara Internasional (LSIA)',
        label = 'spawn_airport',
        description = 'spawn_airport_desc',
        coords = { x = -1037.6, y = -2737.8, z = 20.1, h = 330.0 }
    },
    {
        id = 'harbor',
        icon = '⚓',
        tag = 'LAUT',
        name = 'Pelabuhan Los Santos (Docks)',
        label = 'spawn_harbor',
        description = 'spawn_harbor_desc',
        coords = { x = -140.0, y = -2365.0, z = 6.0, h = 180.0 }
    },
    {
        id = 'train',
        icon = '🚆',
        tag = 'DARAT',
        name = 'Stasiun Kereta Api (Central)',
        label = 'spawn_train',
        description = 'spawn_train_desc',
        coords = { x = -210.0, y = -1015.0, z = 30.1, h = 250.0 }
    },
    {
        id = 'hospital',
        icon = '🏥',
        tag = 'MEDIS',
        name = 'Rumah Sakit Pillbox Hill',
        label = 'spawn_hospital',
        description = 'spawn_hospital_desc',
        coords = { x = 298.6, y = -584.5, z = 43.2, h = 70.0 }
    }
}

-- ----------------------------------------------------------------------------
-- Preset Lokasi Sinematik Pemilihan Karakter
-- Ubah ActiveLocation ke pilihan yang Anda inginkan:
-- 'airport_tarmac'   = Bandara LSIA Private Jet (Nuansa Kedatangan Warga Baru ke Bucu City) [RECOMMENDED]
-- 'del_perro_coast'  = Dermaga Pantai Del Perro (Nuansa Pesisir Laut & Sunset Los Santos)
-- 'casino_terrace'   = Rooftop Penthouse Diamond Casino (Nuansa Kemewahan Modern)
-- 'penthouse_skyline'= Penthouse Eclipse Towers (Gedung Tinggi Menghadap Kota)
-- 'classic_office'   = Kantor Klasik Meja Kayu (Legacy NoPixel style)
-- ----------------------------------------------------------------------------
MulticharConfig.ActiveLocation = 'airport_tarmac'

MulticharConfig.Locations = {
    ['airport_tarmac'] = {
        label     = 'LSIA Private Jet Tarmac (Kedatangan Bucu City)',
        isIndoor  = false,
        interior  = nil,
        pedCoords = vector4(-1037.71, -2737.77, 20.17, 330.0),
        camCoords = vector4(-1035.80, -2734.50, 20.35, 150.0),
        hiddenCoords = vector4(-1037.71, -2737.77, -50.0, 330.0),
        fov       = 48.0
    },
    ['del_perro_coast'] = {
        label     = 'Del Perro Coastal Pier (Pesisir Pantai)',
        isIndoor  = false,
        interior  = nil,
        pedCoords = vector4(-1686.0, -1072.0, 13.0, 50.0),
        camCoords = vector4(-1683.5, -1069.0, 13.3, 230.0),
        hiddenCoords = vector4(-1686.0, -1072.0, -50.0, 50.0),
        fov       = 46.0
    },
    ['casino_terrace'] = {
        label     = 'Diamond Casino Skyline Rooftop Terrace',
        isIndoor  = false,
        interior  = nil,
        pedCoords = vector4(964.5, 58.2, 112.5, 328.0),
        camCoords = vector4(967.0, 60.5, 112.7, 148.0),
        hiddenCoords = vector4(964.5, 58.2, 50.0, 328.0),
        fov       = 46.0
    },
    ['penthouse_skyline'] = {
        label     = 'Eclipse Towers Modern Skyline Penthouse',
        isIndoor  = true,
        interior  = vector3(-774.0, 342.0, 196.0),
        pedCoords = vector4(-774.2, 342.5, 196.68, 180.0),
        camCoords = vector4(-774.2, 339.8, 196.85, 0.0),
        hiddenCoords = vector4(-774.2, 342.5, 150.0, 180.0),
        fov       = 48.0
    },
    ['classic_office'] = {
        label     = 'Classic Executive Office (Meja Kayu)',
        isIndoor  = true,
        interior  = vector3(-1004.36, -477.9, 51.63),
        pedCoords = vector4(-1006.98, -477.98, 50.03, 208.42),
        camCoords = vector4(-1005.53, -480.38, 50.03, 29.11),
        hiddenCoords = vector4(-1006.98, -477.98, -100.0, 208.42),
        fov       = 46.0
    }
}

-- Backward compatibility helpers
local activeLoc = MulticharConfig.Locations[MulticharConfig.ActiveLocation] or MulticharConfig.Locations['airport_tarmac']
MulticharConfig.Interior     = activeLoc.interior
MulticharConfig.PedCoords    = activeLoc.pedCoords
MulticharConfig.CamCoords    = activeLoc.camCoords
MulticharConfig.HiddenCoords = activeLoc.hiddenCoords


function _U(key, ...)
    local lang = MulticharConfig.Language or 'en'
    local dict = (Locales and Locales[lang]) or (Locales and Locales['en']) or {}
    local str = dict[key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
