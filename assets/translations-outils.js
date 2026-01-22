// ============ TRADUCTIONS OUTILS ============

const OUTILS_TRANSLATIONS = {
    fr: {
        sectionOutilsUrgence: "OUTILS D'URGENCE",
        outilMetronome: "MÉTRONOME RCP",
        outilMetronomeDesc: "110 BPM - Compressions cardiaques",
        outilFlash: "FLASH SOS",
        outilFlashDesc: "··· --- ··· Signal lumineux",
        outilSifflet: "SIFFLET URGENCE",
        outilSiffletDesc: "Son d'alerte - 2 secondes"
    },
    en: {
        sectionOutilsUrgence: "EMERGENCY TOOLS",
        outilMetronome: "CPR METRONOME",
        outilMetronomeDesc: "110 BPM - Chest compressions",
        outilFlash: "SOS FLASH",
        outilFlashDesc: "··· --- ··· Light signal",
        outilSifflet: "EMERGENCY WHISTLE",
        outilSiffletDesc: "Alert sound - 2 seconds"
    },
    de: {
        sectionOutilsUrgence: "NOTFALLWERKZEUGE",
        outilMetronome: "HLW-METRONOM",
        outilMetronomeDesc: "110 BPM - Herzdruckmassage",
        outilFlash: "SOS-BLITZ",
        outilFlashDesc: "··· --- ··· Lichtsignal",
        outilSifflet: "NOTFALLPFEIFE",
        outilSiffletDesc: "Alarmsignal - 2 Sekunden"
    },
    es: {
        sectionOutilsUrgence: "HERRAMIENTAS DE EMERGENCIA",
        outilMetronome: "METRÓNOMO RCP",
        outilMetronomeDesc: "110 BPM - Compresiones torácicas",
        outilFlash: "FLASH SOS",
        outilFlashDesc: "··· --- ··· Señal luminosa",
        outilSifflet: "SILBATO DE EMERGENCIA",
        outilSiffletDesc: "Sonido de alerta - 2 segundos"
    },
    it: {
        sectionOutilsUrgence: "STRUMENTI DI EMERGENZA",
        outilMetronome: "METRONOMO RCP",
        outilMetronomeDesc: "110 BPM - Compressioni toraciche",
        outilFlash: "FLASH SOS",
        outilFlashDesc: "··· --- ··· Segnale luminoso",
        outilSifflet: "FISCHIO EMERGENZA",
        outilSiffletDesc: "Suono allarme - 2 secondi"
    },
    pt: {
        sectionOutilsUrgence: "FERRAMENTAS DE EMERGÊNCIA",
        outilMetronome: "METRÔNOMO RCP",
        outilMetronomeDesc: "110 BPM - Compressões torácicas",
        outilFlash: "FLASH SOS",
        outilFlashDesc: "··· --- ··· Sinal luminoso",
        outilSifflet: "APITO DE EMERGÊNCIA",
        outilSiffletDesc: "Som de alerta - 2 segundos"
    },
    ar: {
        sectionOutilsUrgence: "أدوات الطوارئ",
        outilMetronome: "مترونوم الإنعاش",
        outilMetronomeDesc: "110 ضربة/دقيقة - ضغطات الصدر",
        outilFlash: "فلاش الاستغاثة",
        outilFlashDesc: "··· --- ··· إشارة ضوئية",
        outilSifflet: "صفارة طوارئ",
        outilSiffletDesc: "صوت إنذار - ثانيتين"
    },
    ru: {
        sectionOutilsUrgence: "ИНСТРУМЕНТЫ ЧС",
        outilMetronome: "МЕТРОНОМ СЛР",
        outilMetronomeDesc: "110 уд/мин - Компрессии",
        outilFlash: "SOS ВСПЫШКА",
        outilFlashDesc: "··· --- ··· Световой сигнал",
        outilSifflet: "СИГНАЛЬНЫЙ СВИСТОК",
        outilSiffletDesc: "Звук тревоги - 2 секунды"
    },
    tr: {
        sectionOutilsUrgence: "ACİL DURUM ARAÇLARI",
        outilMetronome: "CPR METRONOMU",
        outilMetronomeDesc: "110 BPM - Kalp masajı",
        outilFlash: "SOS FLAŞI",
        outilFlashDesc: "··· --- ··· Işık sinyali",
        outilSifflet: "ACİL DURUM DÜDÜĞÜ",
        outilSiffletDesc: "Alarm sesi - 2 saniye"
    },
    nl: {
        sectionOutilsUrgence: "NOODHULPMIDDELEN",
        outilMetronome: "CPR-METRONOOM",
        outilMetronomeDesc: "110 BPM - Borstcompressies",
        outilFlash: "SOS-FLITSER",
        outilFlashDesc: "··· --- ··· Lichtsignaal",
        outilSifflet: "NOODFLUITJE",
        outilSiffletDesc: "Alarmgeluid - 2 seconden"
    },
    sv: {
        sectionOutilsUrgence: "NOODVERKTYG",
        outilMetronome: "CPR-METRONOM",
        outilMetronomeDesc: "110 BPM - Bröstkompressioner",
        outilFlash: "SOS-BLINK",
        outilFlashDesc: "··· --- ··· Ljussignal",
        outilSifflet: "NÖDVISSLA",
        outilSiffletDesc: "Larmsignal - 2 sekunder"
    }
};

function updateOutilsLang(lang) {
    const t = OUTILS_TRANSLATIONS[lang] || OUTILS_TRANSLATIONS.fr;
    
    // Titre section
    const sectionTitle = document.getElementById('sectionOutilsUrgence');
    if (sectionTitle) sectionTitle.textContent = t.sectionOutilsUrgence;
    
    // Cartes
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (t[key]) el.textContent = t[key];
    });
}

// Détection automatique de la langue
document.addEventListener('DOMContentLoaded', () => {
    const lang = localStorage.getItem('sos_guide_language') || 'fr';
    setTimeout(() => updateOutilsLang(lang), 100);
    
    // Écouter les changements de langue
    const select = document.getElementById('languageSelect');
    if (select) {
        select.addEventListener('change', () => {
            setTimeout(() => updateOutilsLang(select.value), 100);
        });
    }
});
