/**
 * ============================================================================
 * BUCU Multicharacter — Modern Client NUI Application Controller
 * Manages live character selection, 3D ped synchronization & identity dossier
 * ============================================================================
 */

(function() {
    'use strict';

    const RESOURCE_NAME = 'bucu_multicharacter';

    // State
    let currentLocales = {};
    let characters = {};
    let maxSlots = 4;
    let spawnsList = [];
    let selectedSlot = 1;
    let selectedSpawnId = 'airport';
    let slotToDelete = null;

    // DOM Elements
    const appEl = document.getElementById('multichar-app');
    const slotsContainerEl = document.getElementById('slots-container');
    const slotsCountChipEl = document.getElementById('slots-count-chip');

    // Dossier Elements
    const dossierActiveEl = document.getElementById('dossier-active');
    const dossierEmptyEl = document.getElementById('dossier-empty');
    const dossierFullNameEl = document.getElementById('dossier-fullname');
    const dossierCitizenIdEl = document.getElementById('dossier-citizenid');
    const dossierCashEl = document.getElementById('dossier-cash');
    const dossierBankEl = document.getElementById('dossier-bank');
    const dossierDobEl = document.getElementById('dossier-dob');
    const dossierGenderEl = document.getElementById('dossier-gender');
    const dossierJobEl = document.getElementById('dossier-job');
    const dossierPhoneEl = document.getElementById('dossier-phone');

    // Main Actions
    const btnEnterCity = document.getElementById('btn-enter-city');
    const btnChooseSpawn = document.getElementById('btn-choose-spawn');
    const btnDeleteChar = document.getElementById('btn-delete-char');
    const btnCreateProfile = document.getElementById('btn-create-profile');

    // Rotation Dock
    const btnRotLeft = document.getElementById('btn-rot-left');
    const btnRotRight = document.getElementById('btn-rot-right');

    // Modals
    const modalSpawnEl = document.getElementById('modal-spawn');
    const spawnListContainerEl = document.getElementById('spawn-list-container');
    const btnCancelSpawn = document.getElementById('btn-cancel-spawn');
    const btnConfirmSpawn = document.getElementById('btn-confirm-spawn');

    const modalDeleteEl = document.getElementById('modal-delete');
    const deleteCharNameEl = document.getElementById('delete-char-name');
    const btnCancelDelete = document.getElementById('btn-cancel-delete');
    const btnConfirmDelete = document.getElementById('btn-confirm-delete');

    const modalRegEl = document.getElementById('modal-registration');
    const regFormEl = document.getElementById('registration-form');
    const regErrorEl = document.getElementById('reg-error-msg');
    const btnCancelReg = document.getElementById('btn-cancel-reg');

    // Helper: Post NUI
    function fetchPost(endpoint, data = {}) {
        return fetch(`https://${RESOURCE_NAME}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).then(res => res.json()).catch(() => ({}));
    }

    // Helper: Formatter
    function formatMoney(amount) {
        return (amount || 0).toLocaleString('en-US');
    }

    function getInitials(name) {
        if (!name) return '??';
        const parts = name.trim().split(' ');
        if (parts.length >= 2) {
            return (parts[0][0] + parts[1][0]).toUpperCase();
        }
        return name.slice(0, 2).toUpperCase();
    }

    function capitalize(str) {
        if (!str) return '';
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    // Helper: Normalize Characters (Handles both Lua Arrays and Object Dictionaries)
    function normalizeCharacters(rawChars) {
        const map = {};
        if (!rawChars) return map;

        if (Array.isArray(rawChars)) {
            rawChars.forEach((c, idx) => {
                if (c) {
                    const s = parseInt(c.slot, 10) || (idx + 1);
                    map[s] = c;
                }
            });
        } else if (typeof rawChars === 'object') {
            Object.keys(rawChars).forEach(k => {
                const c = rawChars[k];
                if (c) {
                    const s = parseInt(c.slot, 10) || parseInt(k, 10) || 1;
                    map[s] = c;
                }
            });
        }
        return map;
    }

    function updateEnterButtonText() {
        const playTextEl = document.getElementById('btn-play-text');
        if (!playTextEl) return;
        const labels = {
            airport: 'MASUK KOTA (BANDARA LSIA)',
            harbor: 'MASUK KOTA (PELABUHAN LAUT)',
            train: 'MASUK KOTA (STASIUN KERETA)'
        };
        playTextEl.textContent = labels[selectedSpawnId] || 'MASUK KOTA SEKARANG';
    }

    let quickSpawnsInitialized = false;
    function setupQuickSpawns() {
        if (quickSpawnsInitialized) return;
        quickSpawnsInitialized = true;

        document.querySelectorAll('.spawn-card-quick').forEach(card => {
            card.addEventListener('click', () => {
                document.querySelectorAll('.spawn-card-quick').forEach(c => c.classList.remove('active'));
                card.classList.add('active');
                selectedSpawnId = card.dataset.spawn || 'airport';
                updateEnterButtonText();
            });

            card.addEventListener('dblclick', () => {
                selectedSpawnId = card.dataset.spawn || 'airport';
                const char = characters[selectedSlot];
                if (char) {
                    fetchPost('selectCharacter', {
                        slot: selectedSlot,
                        citizenid: char.citizenid,
                        spawnId: selectedSpawnId,
                        character: char
                    });
                }
            });
        });
    }

    // ─── NUI Message Handler ─────────────────────────────────────────────────
    window.addEventListener('message', function(event) {
        const item = event.data;
        if (!item || !item.action) return;

        switch (item.action) {
            case 'open':
                currentLocales = item.locales || {};
                characters = normalizeCharacters(item.characters);
                if (Array.isArray(item.charactersList) && item.charactersList.length > 0) {
                    item.charactersList.forEach(c => {
                        if (c && c.slot) characters[parseInt(c.slot, 10)] = c;
                    });
                }
                maxSlots = item.maxSlots || 4;
                spawnsList = item.spawns || [];

                applyTranslations();
                renderSlotList();
                setupQuickSpawns();
                updateEnterButtonText();

                // Select first occupied slot, or Slot 1
                let initialSlot = 1;
                for (let i = 1; i <= maxSlots; i++) {
                    if (characters[i]) {
                        initialSlot = i;
                        break;
                    }
                }
                activateSlot(initialSlot);

                appEl.classList.remove('hidden');
                break;

            case 'close':
                appEl.classList.add('hidden');
                modalSpawnEl.classList.add('hidden');
                modalDeleteEl.classList.add('hidden');
                modalRegEl.classList.add('hidden');
                break;

            case 'showSpawnSelector':
                modalRegEl.classList.add('hidden');
                if (item.spawns) spawnsList = item.spawns;
                if (item.locales) currentLocales = item.locales;
                renderSpawnList();
                appEl.classList.remove('hidden');
                modalSpawnEl.classList.remove('hidden');
                break;
        }
    });

    // ─── Render Left Slots ───────────────────────────────────────────────────
    function renderSlotList() {
        slotsContainerEl.innerHTML = '';
        let filledCount = 0;

        for (let slot = 1; slot <= maxSlots; slot++) {
            const char = characters[slot];
            const card = document.createElement('div');
            card.dataset.slot = slot;

            if (char) {
                filledCount++;
                card.className = `slot-card ${slot === selectedSlot ? 'active' : ''}`;
                card.innerHTML = `
                    <div class="slot-card-inner">
                        <div class="slot-avatar-wrap">
                            <div class="slot-avatar">${getInitials(char.fullname || (char.firstname + ' ' + char.lastname))}</div>
                            <span class="slot-number-tag">0${slot}</span>
                        </div>
                        <div class="slot-info">
                            <div class="slot-name">${char.fullname || (char.firstname + ' ' + char.lastname)}</div>
                            <div class="slot-sub">
                                <span class="slot-citid">#${char.citizenid || 'BUCU-0000'}</span>
                                <span>•</span>
                                <span class="slot-job">${capitalize(char.job || 'Unemployed')}</span>
                            </div>
                        </div>
                    </div>
                `;
            } else {
                card.className = `slot-card empty-slot ${slot === selectedSlot ? 'active' : ''}`;
                card.innerHTML = `
                    <div class="empty-avatar">+</div>
                    <div class="empty-info">
                        <div class="empty-info-title">Slot 0${slot} Tersedia</div>
                        <div class="empty-info-sub">Klaim slot & buat warga baru</div>
                    </div>
                `;
            }

            card.addEventListener('click', () => {
                activateSlot(slot);
            });

            slotsContainerEl.appendChild(card);
        }

        slotsCountChipEl.textContent = `${filledCount} / ${maxSlots}`;
    }

    // ─── Activate Slot & Sync 3D Ped Preview ─────────────────────────────────
    function activateSlot(slot) {
        selectedSlot = slot;

        // Update card active classes
        document.querySelectorAll('.slot-card').forEach(card => {
            const s = parseInt(card.dataset.slot, 10);
            card.classList.toggle('active', s === slot);
        });

        const char = characters[slot];

        if (char) {
            // Show Active Dossier
            dossierFullNameEl.textContent = char.fullname || (char.firstname + ' ' + char.lastname);
            dossierCitizenIdEl.textContent = '#' + (char.citizenid || 'BUCU-0000');
            dossierCashEl.textContent = '$' + formatMoney(char.cash || 0);
            dossierBankEl.textContent = '$' + formatMoney(char.bank || 0);
            dossierDobEl.textContent = char.dob || '1990-01-01';
            dossierGenderEl.textContent = capitalize(char.gender || 'male');
            dossierJobEl.textContent = capitalize(char.job || 'Unemployed');
            dossierPhoneEl.textContent = char.phone || '555-0100';

            // Populate Dossier Avatar Photo
            const avatarImgEl = document.getElementById('dossier-avatar-img');
            const avatarFallbackEl = document.getElementById('dossier-avatar-fallback');
            const avatarSrc = char.avatar || (char.metadata && char.metadata.avatar) || 'images/default_avatar.png';

            if (avatarImgEl && avatarFallbackEl) {
                if (avatarSrc && avatarSrc !== '') {
                    avatarImgEl.src = avatarSrc;
                    avatarImgEl.style.display = 'block';
                    avatarFallbackEl.style.display = 'none';
                    avatarImgEl.onerror = () => {
                        avatarImgEl.style.display = 'none';
                        avatarFallbackEl.style.display = 'flex';
                        avatarFallbackEl.textContent = getInitials(char.fullname || (char.firstname + ' ' + char.lastname));
                    };
                } else {
                    avatarImgEl.style.display = 'none';
                    avatarFallbackEl.style.display = 'flex';
                    avatarFallbackEl.textContent = getInitials(char.fullname || (char.firstname + ' ' + char.lastname));
                }
            }

            dossierActiveEl.classList.remove('hidden');
            dossierEmptyEl.classList.add('hidden');

            updateEnterButtonText();

            // Send preview request to client Lua
            fetchPost('selectSlot', { slot: slot, character: char });
        } else {
            // Show Empty Dossier
            dossierActiveEl.classList.add('hidden');
            dossierEmptyEl.classList.remove('hidden');

            // Clear preview ped in client Lua
            fetchPost('selectSlot', { slot: slot, character: null });
        }
    }

    // ─── Action Handlers ─────────────────────────────────────────────────────

    // 1. Enter City / Play with Direct Spawn Location
    btnEnterCity.addEventListener('click', () => {
        const char = characters[selectedSlot];
        if (char) {
            fetchPost('selectCharacter', {
                slot: selectedSlot,
                citizenid: char.citizenid,
                spawnId: selectedSpawnId,
                character: char
            });
        }
    });

    // 2. Choose Spawn (if button exists)
    if (btnChooseSpawn) {
        btnChooseSpawn.addEventListener('click', () => {
            renderSpawnList();
            modalSpawnEl.classList.remove('hidden');
        });
    }

    // 3. Delete Character Confirmation
    btnDeleteChar.addEventListener('click', () => {
        const char = characters[selectedSlot];
        if (char) {
            slotToDelete = selectedSlot;
            deleteCharNameEl.textContent = char.fullname || (char.firstname + ' ' + char.lastname);
            modalDeleteEl.classList.remove('hidden');
        }
    });

    btnCancelDelete.addEventListener('click', () => {
        modalDeleteEl.classList.add('hidden');
        slotToDelete = null;
    });

    btnConfirmDelete.addEventListener('click', () => {
        if (slotToDelete) {
            fetchPost('deleteCharacter', { slot: slotToDelete });
            modalDeleteEl.classList.add('hidden');
            delete characters[slotToDelete];
            renderSlotList();
            activateSlot(slotToDelete);
            slotToDelete = null;
        }
    });

    // 4. Create New Character (Routes to bucu_identity)
    function triggerCreateProfile() {
        fetchPost('openIdentityCreator', { slot: selectedSlot }).then(res => {
            if (res && res.identityHandled) {
                // bucu_identity successfully launched
                appEl.classList.add('hidden');
            } else {
                // Fallback modal
                modalRegEl.classList.remove('hidden');
            }
        });
    }

    btnCreateProfile.addEventListener('click', triggerCreateProfile);

    // 5. Rotation Controls
    btnRotLeft.addEventListener('click', () => {
        fetchPost('rotatePed', { angle: 25.0 });
    });

    btnRotRight.addEventListener('click', () => {
        fetchPost('rotatePed', { angle: -25.0 });
    });

    // ─── Spawn Selection Modal ───────────────────────────────────────────────
    function renderSpawnList() {
        spawnListContainerEl.innerHTML = '';
        selectedSpawnId = (spawnsList[0] && spawnsList[0].id) || 'airport';

        spawnsList.forEach((sp, idx) => {
            const item = document.createElement('div');
            item.className = `spawn-item ${sp.id === selectedSpawnId ? 'selected' : ''}`;
            item.dataset.id = sp.id;
            item.innerHTML = `
                <div class="spawn-info">
                    <div class="spawn-name">${currentLocales[sp.label] || sp.label || sp.id}</div>
                    <div class="spawn-desc">${currentLocales[sp.description] || sp.description || ''}</div>
                </div>
                <span class="spawn-arrow">➔</span>
            `;

            item.addEventListener('click', () => {
                document.querySelectorAll('.spawn-item').forEach(i => i.classList.remove('selected'));
                item.classList.add('selected');
                selectedSpawnId = sp.id;
            });

            spawnListContainerEl.appendChild(item);
        });
    }

    btnCancelSpawn.addEventListener('click', () => {
        modalSpawnEl.classList.add('hidden');
    });

    btnConfirmSpawn.addEventListener('click', () => {
        fetchPost('selectSpawn', { spawnId: selectedSpawnId });
        modalSpawnEl.classList.add('hidden');
    });

    // ─── Fallback Registration Form ──────────────────────────────────────────
    btnCancelReg.addEventListener('click', () => {
        modalRegEl.classList.add('hidden');
    });

    regFormEl.addEventListener('submit', (e) => {
        e.preventDefault();
        regErrorEl.classList.add('hidden');

        const firstname = (document.getElementById('reg-firstname').value || '').trim();
        const lastname  = (document.getElementById('reg-lastname').value || '').trim();
        const dob       = document.getElementById('reg-dob').value;
        const gender    = document.getElementById('reg-gender').value;

        if (firstname.length < 2 || lastname.length < 2) {
            regErrorEl.textContent = 'First and Last name must be at least 2 characters.';
            regErrorEl.classList.remove('hidden');
            return;
        }

        fetchPost('createCharacter', {
            slot: selectedSlot,
            firstname: firstname,
            lastname: lastname,
            dob: dob,
            gender: gender
        });

        modalRegEl.classList.add('hidden');
    });

    // ─── Translations Helper ─────────────────────────────────────────────────
    function applyTranslations() {
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            if (currentLocales[key]) {
                el.textContent = currentLocales[key];
            }
        });
    }

    // ─── Standalone Browser Preview Mode ──────────────────────────────────────
    if (!window.invokeNative) {
        setTimeout(() => {
            window.postMessage({
                action: 'open',
                language: 'id',
                locales: {
                    title_select_char: 'PROFIL WARGA KOTA',
                    subtitle_select_char: 'Pilih Profil Warga Kota atau Buat Baru',
                    lbl_cash: 'UANG TUNAI',
                    lbl_bank: 'TABUNGAN BANK',
                    lbl_dob: 'TANGGAL LAHIR',
                    lbl_gender: 'JENIS KELAMIN',
                    lbl_job: 'PEKERJAAN',
                    btn_create_char: 'BUAT KARAKTER BARU'
                },
                characters: {
                    "1": {
                        id: 4,
                        slot: 1,
                        citizenid: 'BUCU-121436',
                        firstname: 'Bucu',
                        lastname: 'Banget',
                        fullname: 'Bucu Banget',
                        dob: '1990-01-01',
                        gender: 'male',
                        phone: '555-0104',
                        job: 'unemployed',
                        jobGrade: 0,
                        cash: 1000,
                        bank: 5000
                    }
                },
                charactersList: [
                    {
                        id: 4,
                        slot: 1,
                        citizenid: 'BUCU-121436',
                        firstname: 'Bucu',
                        lastname: 'Banget',
                        fullname: 'Bucu Banget',
                        dob: '1990-01-01',
                        gender: 'male',
                        phone: '555-0104',
                        job: 'unemployed',
                        jobGrade: 0,
                        cash: 1000,
                        bank: 5000
                    }
                ],
                maxSlots: 4,
                spawns: [
                    { id: 'airport', name: 'Bandara Internasional (LSIA)' },
                    { id: 'harbor', name: 'Pelabuhan Los Santos (Docks)' },
                    { id: 'train', name: 'Stasiun Kereta Api (Central)' }
                ]
            }, '*');
        }, 120);
    }

})();
