-- ============================================================================
-- BUCU Multicharacter — English Localization (en)
-- ============================================================================

Locales = Locales or {}

Locales['en'] = {
    -- Header & Titles
    ['title_select_char'] = 'Select Your Character',
    ['subtitle_select_char'] = 'Choose an active citizen profile or register a new identity',
    ['slot_empty'] = 'Empty Slot',
    ['slot_create_new'] = '+ Register New Citizen',
    ['btn_play'] = 'Enter City',
    ['btn_delete'] = 'Delete',

    -- Character Card Details
    ['lbl_citizen_id'] = 'Citizen ID',
    ['lbl_dob'] = 'DOB',
    ['lbl_gender'] = 'Gender',
    ['lbl_job'] = 'Occupation',
    ['lbl_bank'] = 'Bank Balance',
    ['lbl_cash'] = 'Cash',

    -- Registration Modal
    ['modal_reg_title'] = 'State Identity Registration',
    ['modal_reg_subtitle'] = 'Please fill out your official civil registry documents accurately',
    ['field_firstname'] = 'First Name',
    ['field_lastname'] = 'Last Name',
    ['field_dob'] = 'Date of Birth (YYYY-MM-DD)',
    ['field_gender'] = 'Gender',
    ['gender_male'] = 'Male',
    ['gender_female'] = 'Female',
    ['field_nationality'] = 'Nationality',
    ['btn_submit_reg'] = 'Create Identity & Enter',
    ['btn_cancel'] = 'Cancel',

    -- Spawn Selector Modal
    ['modal_spawn_title'] = 'Select Arrival Location',
    ['modal_spawn_subtitle'] = 'Choose where you want to wake up in the state',
    ['spawn_airport'] = 'Los Santos International Airport',
    ['spawn_airport_desc'] = 'Terminal arrival for new arrivals and traveling citizens.',
    ['spawn_harbor'] = 'Port of Los Santos Docks',
    ['spawn_harbor_desc'] = 'Ocean terminal and maritime freight harbor district.',
    ['spawn_train'] = 'Central Train Station',
    ['spawn_train_desc'] = 'Downtown Los Santos metro transport hub.',
    ['spawn_hospital'] = 'Pillbox Hill Medical Center',
    ['spawn_hospital_desc'] = 'Central emergency hospital district.',
    ['spawn_last'] = 'Last Saved Location',
    ['spawn_last_desc'] = 'Wake up exactly where you logged out.',
    ['btn_spawn_here'] = 'Confirm Spawn Point',

    -- Notifications & Validation
    ['err_invalid_name'] = 'First and last names must only contain letters (2-25 characters).',
    ['err_invalid_dob'] = 'Date of birth must be valid (Citizen age must be 18 to 90 years old).',
    ['err_slot_occupied'] = 'This character slot is already occupied.',
    ['err_max_slots'] = 'Maximum number of character slots reached.',
    ['notif_char_created'] = 'Character successfully registered! Welcome to Los Santos.',
    ['notif_char_deleted'] = 'Character profile has been permanently deleted.'
}
