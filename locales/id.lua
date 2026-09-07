-- ============================================================================
-- BUCU Multicharacter — Indonesian Localization (id)
-- ============================================================================

Locales = Locales or {}

Locales['id'] = {
    -- Header & Titles
    ['title_select_char'] = 'Pilih Karakter Warga',
    ['subtitle_select_char'] = 'Pilih profil karakter yang tersimpan atau daftarkan identitas baru',
    ['slot_empty'] = 'Slot Kosong',
    ['slot_create_new'] = '+ Buat Warga Baru',
    ['btn_play'] = 'Masuk Kota',
    ['btn_delete'] = 'Hapus',

    -- Character Card Details
    ['lbl_citizen_id'] = 'Nomor Warga',
    ['lbl_dob'] = 'Tgl Lahir',
    ['lbl_gender'] = 'Kelamin',
    ['lbl_job'] = 'Pekerjaan',
    ['lbl_bank'] = 'Saldo Bank',
    ['lbl_cash'] = 'Uang Tunai',

    -- Registration Modal
    ['modal_reg_title'] = 'Registrasi Kependudukan Sipil',
    ['modal_reg_subtitle'] = 'Isi data formulir identitas resmi Anda dengan benar dan teliti',
    ['field_firstname'] = 'Nama Depan',
    ['field_lastname'] = 'Nama Belakang',
    ['field_dob'] = 'Tanggal Lahir (YYYY-MM-DD)',
    ['field_gender'] = 'Jenis Kelamin',
    ['gender_male'] = 'Laki-Laki',
    ['gender_female'] = 'Perempuan',
    ['field_nationality'] = 'Kewarganegaraan',
    ['btn_submit_reg'] = 'Daftarkan Identitas & Masuk',
    ['btn_cancel'] = 'Batal',

    -- Spawn Selector Modal
    ['modal_spawn_title'] = 'Pilih Titik Kedatangan',
    ['modal_spawn_subtitle'] = 'Pilih lokasi awal karakter Anda terbangun di dalam kota',
    ['spawn_airport'] = 'Bandara Internasional Los Santos',
    ['spawn_airport_desc'] = 'Terminal kedatangan bagi warga baru atau pendatang dari luar kota.',
    ['spawn_harbor'] = 'Pelabuhan Laut Los Santos',
    ['spawn_harbor_desc'] = 'Kawasan dermaga kapal kargo dan logistik laut South Los Santos.',
    ['spawn_train'] = 'Stasiun Kereta Pusat Kota',
    ['spawn_train_desc'] = 'Pusat transit transportasi metro di jantung kota Los Santos.',
    ['spawn_hospital'] = 'Rumah Sakit Pillbox Hill',
    ['spawn_hospital_desc'] = 'Kawasan medis pusat darurat kota.',
    ['spawn_last'] = 'Lokasi Terakhir Tersimpan',
    ['spawn_last_desc'] = 'Terbangun persis di titik terakhir saat Anda logout sebelumnya.',
    ['btn_spawn_here'] = 'Pilih Titik Ini & Bangun',

    -- Notifications & Validation
    ['err_invalid_name'] = 'Nama depan dan belakang hanya boleh memuat huruf (2-25 karakter).',
    ['err_invalid_dob'] = 'Tanggal lahir tidak valid (Usia warga harus 18 hingga 90 tahun).',
    ['err_slot_occupied'] = 'Slot karakter ini sudah terisi.',
    ['err_max_slots'] = 'Jumlah batas maksimum slot karakter telah tercapai.',
    ['notif_char_created'] = 'Identitas karakter berhasil didaftarkan! Selamat datang di Los Santos.',
    ['notif_char_deleted'] = 'Profil karakter telah dihapus secara permanen.'
}
