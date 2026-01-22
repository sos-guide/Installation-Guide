// ============ CONFIGURATION ============
        const CONFIG = {
            defaultLanguage: 'fr',
            supportedLanguages: ['fr', 'en', 'de', 'es', 'it', 'pt', 'ar', 'ru', 'tr', 'nl', 'sv'],
            dataFiles: {
                faq: 'faq.json',
                droits: 'droits.json',
                documents: 'documents.json'
            }
        };

        // ============ ÉTAT GLOBAL ============
        let appState = {
            darkMode: false,
            currentLanguage: CONFIG.defaultLanguage,
            pwaInstalled: false,
            deferredPrompt: null,
            drawerOpen: false,
            welcomeClosed: false,
            loadedData: {
                faq: null,
                droits: null,
                documents: null
            }
        };

        // ============ TRADUCTIONS D'INTERFACE ============
        const TRANSLATIONS = {
            fr: {
                appTitle: "SOS-GUIDE",
                offlineBadge: "HORS-LIGNE",
                sectionDroits: "DROITS ET DEVOIRS",
                sectionDocuments: "DÉCLARATIONS & CONSTITUTIONS",
                sectionSanteMentale: "SANTÉ MENTALE",
                loading: "Chargement...",
                darkModeOn: "Mode sombre activé",
                darkModeOff: "Mode clair activé",
                darkMode: "MODE SOMBRE",
                lightMode: "MODE CLAIR",
                welcomeTitle: "Hey, Bienvenue !",
                welcomeText: "Accédez instantanément aux informations essentielles avec SOS-GUIDE. Une application de survie 100% hors-ligne, toujours dans votre poche.",
                welcomeTip: "Ne cédez pas à la panique.",
                welcomeButton: "⭐ Installer l'application",
                skipUrgence: "📖 ACCÉDER AU GUIDE COMPLET",
                guideLoaded: "Guide de survie chargé - 100% hors-ligne",
                offlineMode: "Mode hors-ligne - 100% autonome",
                installCancelled: "Installation annulée",
                installLater: "Vous pourrez installer l'application plus tard",
                installSuccess: "Application installée avec succès !",
                drawerSanteMentale: "SANTÉ MENTALE",
                mentalHealthWarning: "⚠️ Ces conseils ne remplacent pas un professionnel",
                emergencyPsych: "URGENCE PSYCHIATRIQUE : 3114",
                emergencyScreenTitle: "🚨 URGENCE IMMÉDIATE",
                emergencyNumbers: {
                    15: "SAMU MÉDICAL",
                    17: "POLICE SÉCURITÉ",
                    18: "POMPIERS INCENDIE",
                    112: "URGENCE EUROPÉEN"
                },
                drawerMenu: "MENU",
                drawerSections: "📚 SECTIONS",
                drawerTools: "⚙️ OUTILS",
                drawerInstallApp: "INSTALLER L'APP",
                drawerEmergencyScreen: "ÉCRAN D'URGENCE",
                drawerVersion: "SOS-GUIDE v1.0",
                drawerStatus: "● HORS-LIGNE"
            },
            en: {
                appTitle: "SOS-GUIDE",
                offlineBadge: "OFFLINE",
                sectionDroits: "RIGHTS & DUTIES",
                sectionDocuments: "DECLARATIONS & CONSTITUTIONS",
                sectionSanteMentale: "MENTAL HEALTH",
                loading: "Loading...",
                darkModeOn: "Dark mode activated",
                darkModeOff: "Light mode activated",
                darkMode: "DARK MODE",
                lightMode: "LIGHT MODE",
                welcomeTitle: "Hey, Welcome!",
                welcomeText: "Instantly access essential information with SOS-GUIDE. A 100% offline survival app, always in your pocket.",
                welcomeTip: "Don't give in to panic.",
                welcomeButton: "⭐ Install the app",
                skipUrgence: "📖 ACCESS FULL GUIDE",
                guideLoaded: "Survival guide loaded - 100% offline",
                offlineMode: "Offline mode - 100% autonomous",
                installCancelled: "Installation cancelled",
                installLater: "You can install the app later",
                installSuccess: "App installed successfully!",
                sectionSanteMentale: "MENTAL HEALTH & PSYCHOLOGICAL FIRST AID",
                drawerSanteMentale: "MENTAL HEALTH",
                mentalHealthWarning: "⚠️ This advice does not replace a professional",
                emergencyPsych: "PSYCHIATRIC EMERGENCY: 3114",
                emergencyScreenTitle: "🚨 IMMEDIATE EMERGENCY",
                emergencyNumbers: {
                    15: "MEDICAL EMERGENCY",
                    17: "POLICE",
                    18: "FIRE DEPARTMENT",
                    112: "EUROPEAN EMERGENCY"
                },
                drawerMenu: "MENU",
                drawerSections: "📚 SECTIONS",
                drawerTools: "⚙️ TOOLS",
                drawerInstallApp: "INSTALL APP",
                drawerEmergencyScreen: "EMERGENCY SCREEN",
                drawerVersion: "SOS-GUIDE v1.0",
                drawerStatus: "● OFFLINE"
            },
            de: {
                appTitle: "SOS-GUIDE",
                offlineBadge: "OFFLINE",
                sectionDroits: "RECHTE & PFLICHTEN",
                sectionDocuments: "ERKLÄRUNGEN & VERFASSUNGEN",
                sectionSanteMentale: "PSYCHISCHE GESUNDHEIT",
                loading: "Laden...",
                darkModeOn: "Dunkelmodus aktiviert",
                darkModeOff: "Hellmodus activé",
                darkMode: "DUNKELMODUS",
                lightMode: "HELLMODUS",
                welcomeTitle: "Hallo, Willkommen!",
                welcomeText: "Greifen Sie sofort auf wichtige Informationen mit SOS-GUIDE zu. Eine 100% offline Überlebens-App, immer in Ihrer Tasche.",
                welcomeTip: "Geben Sie nicht der Panik nach.",
                welcomeButton: "⭐ App installieren",
                skipUrgence: "📖 VOLLSTÄNDIGE ANLEITUNG",
                guideLoaded: "Überlebenshandbuch geladen - 100% offline",
                offlineMode: "Offline-Modus - 100% autonom",
                installCancelled: "Installation abgebrochen",
                installLater: "Sie können die App später installieren",
                installSuccess: "App erfolgreich installiert!",
                drawerSanteMentale: "PSYCHISCHE GESUNDHEIT",
                emergencyScreenTitle: "🚨 SOFORTIGER NOTFALL",
                emergencyNumbers: {
                    15: "MEDIZINISCHER NOTDIENST",
                    17: "POLIZEI",
                    18: "FEUERWEHR",
                    112: "EUROPÄISCHER NOTRUF"
                },
                drawerMenu: "MENÜ",
                drawerSections: "📚 BEREICHE",
                drawerTools: "⚙️ WERKZEUGE",
                drawerInstallApp: "APP INSTALLIEREN",
                drawerEmergencyScreen: "NOTFALL-BILDSCHIRM",
                drawerVersion: "SOS-GUIDE v1.0",
                drawerStatus: "● OFFLINE"
            },
            es: {
                appTitle: "SOS-GUÍA",
                offlineBadge: "SIN CONEXIÓN",
                sectionDroits: "DERECHOS Y DEBERES",
                sectionDocuments: "DECLARACIONES & CONSTITUCIONES",
                sectionSanteMentale: "SALUD MENTAL",
                loading: "Cargando...",
                darkModeOn: "Modo oscuro activado",
                darkModeOff: "Modo claro activado",
                darkMode: "MODO OSCURO",
                lightMode: "MODO CLARO",
                welcomeTitle: "¡Hola, Bienvenido!",
                welcomeText: "Accede al instante a información esencial con SOS-GUIDE. Una aplicación de supervivencia 100% sin conexión, siempre en tu bolsillo.",
                welcomeTip: "No cedas al pánico.",
                welcomeButton: "⭐ Instalar la aplicación",
                skipUrgence: "📖 ACCEDER A LA GUÍA COMPLETA",
                guideLoaded: "Guía de supervivencia cargada - 100% sin conexión",
                offlineMode: "Modo sin conexión - 100% autónomo",
                installCancelled: "Instalación cancelada",
                installLater: "Puede instalar la aplicación más tarde",
                installSuccess: "¡Aplicación instalada con éxito!",
                drawerSanteMentale: "SALUD MENTAL",
                emergencyScreenTitle: "🚨 EMERGENCIA INMEDIATA",
                emergencyNumbers: {
                    15: "EMERGENCIA MÉDICA",
                    17: "POLICÍA",
                    18: "BOMBEROS",
                    112: "EMERGENCIA EUROPEA"
                },
                drawerMenu: "MENÚ",
                drawerSections: "📚 SECCIONES",
                drawerTools: "⚙️ HERRAMIENTAS",
                drawerInstallApp: "INSTALAR APP",
                drawerEmergencyScreen: "PANTALLA DE EMERGENCIA",
                drawerVersion: "SOS-GUÍA v1.0",
                drawerStatus: "● SIN CONEXIÓN"
            },
            it: {
                appTitle: "SOS-GUIDA",
                offlineBadge: "SENZA CONNESSIONE",
                sectionDroits: "DIRITTI E DOVERI",
                sectionDocuments: "DICHIARAZIONI & COSTITUZIONI",
                sectionSanteMentale: "SALUTE MENTALE",
                loading: "Caricamento...",
                darkModeOn: "Modalità scura attivata",
                darkModeOff: "Modalità chiara attivata",
                darkMode: "MODALITÀ SCURA",
                lightMode: "MODALITÀ CHIARA",
                welcomeTitle: "Ciao, Benvenuto!",
                welcomeText: "Accedi all'istante alle informazioni essenziali con SOS-GUIDE. Un'app di sopravvivenza 100% offline, sempre nella tua tasca.",
                welcomeTip: "Non cedete al panico.",
                welcomeButton: "⭐ Installa l'app",
                skipUrgence: "📖 ACCEDI ALLA GUIDA COMPLETA",
                guideLoaded: "Guida di sopravvivenza caricata - 100% offline",
                offlineMode: "Modalità offline - 100% autonoma",
                installCancelled: "Installazione annullata",
                installLater: "Puoi installare l'applicazione più tardi",
                installSuccess: "Applicazione installata con successo!",
                drawerSanteMentale: "SALUTE MENTALE",
                emergencyScreenTitle: "🚨 EMERGENZA IMMEDIATA",
                emergencyNumbers: {
                    15: "EMERGENZA MEDICA",
                    17: "POLIZIA",
                    18: "VIGILI DEL FUOCO",
                    112: "EMERGENZA EUROPEA"
                },
                drawerMenu: "MENU",
                drawerSections: "📚 SEZIONI",
                drawerTools: "⚙️ STRUMENTI",
                drawerInstallApp: "INSTALLA APP",
                drawerEmergencyScreen: "SCHERMO EMERGENZA",
                drawerVersion: "SOS-GUIDA v1.0",
                drawerStatus: "● SENZA CONNESSIONE"
            },
            pt: {
                appTitle: "SOS-GUIA",
                offlineBadge: "SEM CONEXÃO",
                sectionDroits: "DIREITOS E DEVERES",
                sectionDocuments: "DECLARAÇÕES & CONSTITUIÇÕES",
                sectionSanteMentale: "SAÚDE MENTAL",
                loading: "Carregando...",
                darkModeOn: "Modo escuro ativado",
                darkModeOff: "Modo claro ativado",
                darkMode: "MODO ESCURO",
                lightMode: "MODO CLARO",
                welcomeTitle: "Olá, Bem-vindo!",
                welcomeText: "Aceda instantaneamente a informações essenciais com o SOS-GUIDE. Um aplicativo de sobrevivência 100% offline, sempre no seu bolso.",
                welcomeTip: "Não ceda ao pânico.",
                welcomeButton: "⭐ Instalar a aplicação",
                skipUrgence: "📖 ACEDER AO GUIA COMPLETO",
                guideLoaded: "Guia de sobrevivência carregado - 100% offline",
                offlineMode: "Modo offline - 100% autónomo",
                installCancelled: "Instalação cancelada",
                installLater: "Pode instalar a aplicação mais tarde",
                installSuccess: "Aplicação instalada com sucesso!",
                drawerSanteMentale: "SAÚDE MENTAL",
                emergencyScreenTitle: "🚨 EMERGÊNCIA IMEDIATA",
                emergencyNumbers: {
                    15: "EMERGÊNCIA MÉDICA",
                    17: "POLÍCIA",
                    18: "BOMBEIROS",
                    112: "EMERGÊNCIA EUROPEIA"
                },
                drawerMenu: "MENU",
                drawerSections: "📚 SEÇÕES",
                drawerTools: "⚙️ FERRAMENTAS",
                drawerInstallApp: "INSTALAR APP",
                drawerEmergencyScreen: "ECRÃ DE EMERGÊNCIA",
                drawerVersion: "SOS-GUIA v1.0",
                drawerStatus: "● SEM CONEXÃO"
            },
            ru: {
		appTitle: "SOS-ГИД",
		offlineBadge: "ОФФЛАЙН",
		sectionDroits: "ПРАВА И ОБЯЗАННОСТИ",
		sectionDocuments: "ДЕКЛАРАЦИИ И КОНСТИТУЦИИ",
		sectionSanteMentale: "ПСИХИЧЕСКОЕ ЗДОРОВЬЕ",
		loading: "Загрузка...",
		darkModeOn: "Тёмный режим активирован",
		darkModeOff: "Светлый режим активирован",
		darkMode: "ТЁМНЫЙ РЕЖИМ",
		lightMode: "СВЕТЛЫЙ РЕЖИМ",
		welcomeTitle: "Привет, Добро пожаловать!",
		welcomeText: "Мграненный доступ к важной информации с SOS-GUIDE. Приложение для выживания на 100% офлайн, всегда под рукой.",
		welcomeTip: "Не поддавайтесь панике.",
		welcomeButton: "⭐ Установить приложение",
		skipUrgence: "📖 ДОСТУП К ПОЛНОМУ РУКОВОДСТВУ",
		guideLoaded: "Руководство по выживанию загружено - 100% офлайн",
		offlineMode: "Офлайн режим - 100% автономно",
		installCancelled: "Установка отменена",
		installLater: "Вы можете установить приложение позже",
		installSuccess: "Приложение успешно установлено!",
		drawerSanteMentale: "ПСИХИЧЕСКОЕ ЗДОРОВЬЕ",
		mentalHealthWarning: "⚠️ Эти советы не заменяют профессиональную помощь",
		emergencyPsych: "ПСИХИАТРИЧЕСКАЯ СЛУЖБА: 3114",
		emergencyScreenTitle: "🚨 НЕМЕДЛЕННАЯ ЧРЕЗВЫЧАЙНАЯ СИТУАЦИЯ",
		emergencyNumbers: {
		    15: "СКОРАЯ МЕДИЦИНСКАЯ",
		    17: "ПОЛИЦИЯ",
		    18: "ПОЖАРНАЯ СЛУЖБА",
		    112: "ЕВРОПЕЙСКАЯ СЛУЖБА"
		},
		drawerMenu: "МЕНЮ",
		drawerSections: "📚 РАЗДЕЛЫ",
		drawerTools: "⚙️ ИНСТРУМЕНТЫ",
		drawerInstallApp: "УСТАНОВИТЬ ПРИЛОЖЕНИЕ",
		drawerEmergencyScreen: "ЭКРАН ЧРЕЗВЫЧАЙНОЙ СИТУАЦИИ",
		drawerVersion: "SOS-GUIDE v1.0",
		drawerStatus: "● ОФФЛАЙН"
	    },
            tr: {
    		appTitle: "SOS REHBER",
	        offlineBadge: "ÇEVRİMDIŞI",
	        sectionDroits: "HAK VE GÖREVLER",
	        sectionDocuments: "BEYANNAMELER VE ANAYASALAR",
	        sectionSanteMentale: "RUH SAĞLIĞI",
	        loading: "Yükleniyor...",
	        darkModeOn: "Koyu mod etkin",
	        darkModeOff: "Açık mod etkin",
	        darkMode: "KOYU MOD",
	        lightMode: "AÇIK MOD",
	        welcomeTitle: "Merhaba, Hoş Geldiniz!",
	        welcomeText: "SOS-GUIDE ile temel bilgilere anında erişin. %100 çevrimdışı bir hayatta kalma uygulaması, her zaman cebinizde.",
	        welcomeTip: "Panik yapmayın.",
	        welcomeButton: "⭐ Uygulamayı Yükle",
	        skipUrgence: "📖 TAM REHBER'E ERİŞ",
	        guideLoaded: "Hayatta kalma rehberi yüklendi - %100 çevrimdışı",
	        offlineMode: "Çevrimdışı mod - %100 bağımsız",
	        installCancelled: "Yükleme iptal edildi",
	        installLater: "Uygulamayı daha sonra yükleyebilirsiniz",
	        installSuccess: "Uygulama başarıyla yüklendi!",
	        drawerSanteMentale: "RUH SAĞLIĞI",
	        mentalHealthWarning: "⚠️ Bu tavsiyeler bir profesyonelin yerini tutmaz",
	        emergencyPsych: "PSİKİYATRİK ACİL: 3114",
	        emergencyScreenTitle: "🚨 ACİL DURUM",
	        emergencyNumbers: {
		    15: "ACİL TIP",
		    17: "POLİS",
		    18: "İTFAİYE",
		    112: "AVRUPA ACİL"
	        },
	        drawerMenu: "MENÜ",
	        drawerSections: "📚 BÖLÜMLER",
	        drawerTools: "⚙️ ARAÇLAR",
	        drawerInstallApp: "UYGULAMAYI YÜKLE",
	        drawerEmergencyScreen: "ACİL DURUM EKRANI",
	        drawerVersion: "SOS REHBER v1.0",
	        drawerStatus: "● ÇEVRİMDIŞI"
	    },
            nl: {
	        appTitle: "SOS-GIDS",
	        offlineBadge: "OFFLINE",
	        sectionDroits: "RECHTEN EN PLICHTEN",
	        sectionDocuments: "VERKLARINGEN & GRONDWETTEN",
	        sectionSanteMentale: "MENTALE GEZONDHEID",
	        loading: "Laden...",
	        darkModeOn: "Donkere modus geactiveerd",
	        darkModeOff: "Lichte modus geactiveerd",
	        darkMode: "DONKERE MODUS",
	        lightMode: "LICHTE MODUS",
	        welcomeTitle: "Hallo, Welkom!",
	        welcomeText: "Krijg direct toegang tot essentiële informatie met SOS-GUIDE. Een 100% offline overlevingsapp, altijd in uw zak.",
	        welcomeTip: "Geef niet toe aan paniek.",
	        welcomeButton: "⭐ App installeren",
	        skipUrgence: "📖 TOEGANG TOT VOLLEDIGE GIDS",
	        guideLoaded: "Overlevingsgids geladen - 100% offline",
	        offlineMode: "Offline modus - 100% autonoom",
	        installCancelled: "Installatie geannuleerd",
	        installLater: "Je kunt de app later installeren",
	        installSuccess: "App succesvol geïnstalleerd!",
	        drawerSanteMentale: "MENTALE GEZONDHEID",
	        mentalHealthWarning: "⚠️ Dit advies vervangt geen professional",
	        emergencyPsych: "PSYCHIATRISCHE SPOED: 3114",
	        emergencyScreenTitle: "🚨 DIRECTE NOODSITUATIE",
	        emergencyNumbers: {
		    15: "MEDISCHE SPOED",
		    17: "POLITIE",
		    18: "BRANDWEER",
		    112: "EUROPESE NOODNUMMER"
	        },
	        drawerMenu: "MENU",
	        drawerSections: "📚 SECTIES",
	        drawerTools: "⚙️ HULPMIDDELEN",
	        drawerInstallApp: "APP INSTALLEREN",
	        drawerEmergencyScreen: "NOODSCHEM",
	        drawerVersion: "SOS-GIDS v1.0",
	        drawerStatus: "● OFFLINE"
	    },
            sv: {
	        appTitle: "SOS-GUIDE",
	        offlineBadge: "OFFLINE",
	        sectionDroits: "RÄTTIGHETER & SKYLDIGHETER",
	        sectionDocuments: "DEKLARATIONER & GRUNDLAGAR",
	        sectionSanteMentale: "PSYKISK HÄLSA",
	        loading: "Laddar...",
	        darkModeOn: "Mörkt läge aktiverat",
	        darkModeOff: "Ljust läge aktiverat",
	        darkMode: "MÖRKT LÄGE",
	        lightMode: "LJUST LÄGE",
	        welcomeTitle: "Hej, Välkommen!",
	        welcomeText: "Få omedelbar tillgång till viktig information med SOS-GUIDE. En 100% offline överlevnadsapp, alltid i din ficka.",
	        welcomeTip: "Ge inte efter för panik.",
	        welcomeButton: "⭐ Installera appen",
	        skipUrgence: "📖 TILLGÅ TILL HELA GUIDEN",
	        guideLoaded: "Överlevnadsguide laddad - 100% offline",
	        offlineMode: "Offlineläge - 100% autonomt",
	        installCancelled: "Installation avbruten",
	        installLater: "Du kan installera appen senare",
	        installSuccess: "Appen har installerats!",
	        drawerSanteMentale: "PSYKISK HÄLSA",
	        mentalHealthWarning: "⚠️ Detta råd ersätter inte en professionell",
	        emergencyPsych: "PSYKIATRISKT AKUT: 3114",
	        emergencyScreenTitle: "🚨 OMEDELBAR NÖDSITUATION",
	        emergencyNumbers: {
		    15: "MEDICINSK AKUT",
		    17: "POLIS",
		    18: "BRANDKÅR",
		    112: "EUROPÉISKT NÖDNUMER"
	        },
	        drawerMenu: "MENY",
	        drawerSections: "📚 AVSNITT",
	        drawerTools: "⚙️ VERKTYG",
	        drawerInstallApp: "INSTALLERA APP",
	        drawerEmergencyScreen: "NÖDSCREEN",
	        drawerVersion: "SOS-GUIDE v1.0",
	        drawerStatus: "● OFFLINE"
	    },
            ar: {
                appTitle: "دليل الإنقاذ",
                offlineBadge: "بدون اتصال",
                sectionDroits: "حقوق وواجبات",
                sectionDocuments: "إعلانات ودساتير",
                sectionSanteMentale: "الصحة النفسية",
                loading: "جار التحميل...",
                darkModeOn: "الوضع الداكن مفعل",
                darkModeOff: "الوضع الفاتح مفعل",
                darkMode: "الوضع الداكن",
                lightMode: "الوضع الفاتح",
                welcomeTitle: "مرحباً بك!",
                welcomeText: "الوصول الفوري إلى المعلومات الأساسية مع SOS-GUIDE. تطبيق بقاء يعمل دون اتصال بالإنترنت 100٪، دائمًا في جيبك.",
                welcomeTip: "احتفظ بهدوئك ",
                welcomeButton: "⭐ تثبيت التطبيق",
                skipUrgence: "📖 الوصول إلى الدليل الكامل",
                guideLoaded: "تم تحميل دليل البقاء - 100% دون اتصال",
                offlineMode: "وضع عدم الاتصال - 100% مستقل",
                installCancelled: "تم إلغاء التثبيت",
                installLater: "يمكنك تثبيت التطبيق لاحقاً",
                installSuccess: "تم تثبيت التطبيق بنجاح!",
                drawerSanteMentale: "الصحة النفسية",
                emergencyScreenTitle: "🚨 طوارئ فورية",
                emergencyNumbers: {
                    15: "طوارئ طبية",
                    17: "شرطة",
                    18: "إطفاء",
                    112: "طوارئ أوروبية"
                },
                drawerMenu: "القائمة",
                drawerSections: "📚 الأقسام",
                drawerTools: "⚙️ الأدوات",
                drawerInstallApp: "تثبيت التطبيق",
                drawerEmergencyScreen: "شاشة الطوارئ",
                drawerVersion: "دليل الإنقاذ v1.0",
                drawerStatus: "● بدون اتصال"
            }
        };
        
        // ============ INITIALISATION ============
        document.addEventListener('DOMContentLoaded', function() {
            // VÉRIFIER SI LES CGU ONT ÉTÉ ACCEPTÉES
            const accepted = document.cookie.includes('sos_accepted=1');
            if (!accepted && !window.location.pathname.includes('cgu.html')) {
                window.location.href = '/cgu.html';
                return;
            }
            
            // Masquer le loader après 800ms
            setTimeout(() => {
                const loader = document.getElementById('loader');
                if (loader) loader.style.display = 'none';
            }, 800);

            // Initialiser la langue
            initLanguage();
            
            // Initialiser le thème
            initTheme();
            
            // Initialiser PWA
            initPWA();
            
            // Initialiser les événements
            initEvents();
            if ('serviceWorker' in navigator) {
	        navigator.serviceWorker.register('./service-worker.js')
		    .then(reg => console.log('Service Worker enregistré', reg))
		    .catch(err => console.log('Erreur SW:', err));
	    }
            
            // Initialiser les modales
            initModals();
            
            // Initialiser le drawer
            initDrawer();
            
            // Initialiser la carte de bienvenue
            initWelcomeCard();
            
            console.log('SOS-GUIDE initialisé - 100% hors-ligne');
        });

        // ============ CARTE DE BIENVENUE ============
        function initWelcomeCard() {
            const welcomeClose = document.getElementById('welcomeClose');
            const welcomeCard = document.getElementById('welcomeCard');
            
            // Vérifier si l'utilisateur a déjà fermé la carte
            const welcomeClosed = localStorage.getItem('sos_welcome_closed') === 'true';
            
            if (welcomeClose && welcomeCard) {
                welcomeClose.addEventListener('click', function() {
                    welcomeCard.style.display = 'none';
                    localStorage.setItem('sos_welcome_closed', 'true');
                    appState.welcomeClosed = true;
                });
                
                // Masquer la carte si déjà fermée
                if (welcomeClosed) {
                    welcomeCard.style.display = 'none';
                    appState.welcomeClosed = true;
                }
            }
        }

        // ============ GESTION DU DRAWER ============
        function initDrawer() {
            const navHamburger = document.getElementById('navHamburger');
            const drawerClose = document.getElementById('drawerClose');
            const drawerOverlay = document.getElementById('drawerOverlay');
            const drawerItems = document.querySelectorAll('.drawer-item[data-section]');
            
            // Ouvrir le drawer
            if (navHamburger) {
                navHamburger.addEventListener('click', openDrawer);
            }
            
            // Fermer le drawer
            if (drawerClose) {
                drawerClose.addEventListener('click', closeDrawer);
            }
            
            // Fermer avec l'overlay
            if (drawerOverlay) {
                drawerOverlay.addEventListener('click', closeDrawer);
            }
            
            // Navigation par section
            if (drawerItems.length > 0) {
                drawerItems.forEach(item => {
                    item.addEventListener('click', function(e) {
                        e.preventDefault();
                        const sectionId = this.getAttribute('data-section');
                        navigateToSection(sectionId);
                        closeDrawer();
                    });
                });
            }
            
            // Outils du drawer
            const drawerThemeToggle = document.getElementById('drawerThemeToggle');
            const drawerInstall = document.getElementById('drawerInstall');
            const drawerEmergency = document.getElementById('drawerEmergency');
            
            if (drawerThemeToggle) {
                drawerThemeToggle.addEventListener('click', function() {
                    toggleTheme();
                    closeDrawer();
                });
            }
            
            if (drawerInstall) {
                drawerInstall.addEventListener('click', function() {
                    handleInstallClick();
                    closeDrawer();
                });
            }
            
            if (drawerEmergency) {
                drawerEmergency.addEventListener('click', function() {
                    showEmergencyScreen();
                    closeDrawer();
                });
            }
            
            // Fermer avec la touche Échap
            document.addEventListener('keydown', function(e) {
                if (e.key === 'Escape' && appState.drawerOpen) {
                    closeDrawer();
                }
            });
            
            // Mettre à jour les traductions du drawer
            updateDrawerTranslations();
        }

        function openDrawer() {
            const drawer = document.getElementById('navDrawer');
            const overlay = document.getElementById('drawerOverlay');
            
            if (drawer && overlay) {
                drawer.classList.add('open');
                overlay.style.display = 'block';
                setTimeout(() => {
                    overlay.style.opacity = '1';
                }, 10);
                appState.drawerOpen = true;
            }
        }

        function closeDrawer() {
            const drawer = document.getElementById('navDrawer');
            const overlay = document.getElementById('drawerOverlay');
            
            if (drawer && overlay) {
                drawer.classList.remove('open');
                overlay.style.opacity = '0';
                setTimeout(() => {
                    overlay.style.display = 'none';
                }, 300);
                appState.drawerOpen = false;
            }
        }

        function navigateToSection(sectionId) {
            const sectionMap = {
                'santeMentale': 'santeMentaleSection',
                'droits': 'droitsSection',
                'documents': 'documentsSection'
            };
            
            const targetId = sectionMap[sectionId];
            if (targetId) {
                const element = document.getElementById(targetId);
                if (element) {
                    // Fermer toutes les modales ouvertes
                    closeTempModal();
                    closeDocumentModal();
                    
                    // Faire défiler jusqu'à la section
                    element.scrollIntoView({ 
                        behavior: 'smooth',
                        block: 'start'
                    });
                    
                    // Ajouter un effet visuel temporaire
                    const originalColor = element.style.backgroundColor;
                    element.style.backgroundColor = 'var(--red-emergency)';
                    element.style.transition = 'background-color 0.5s';
                    setTimeout(() => {
                        element.style.backgroundColor = originalColor;
                    }, 1000);
                    
                    showNotification(`Section: ${TRANSLATIONS[appState.currentLanguage][`section${sectionId.charAt(0).toUpperCase() + sectionId.slice(1)}`]}`);
                }
            }
        }

        function updateDrawerTranslations() {
            const lang = appState.currentLanguage;
            const t = TRANSLATIONS[lang] || TRANSLATIONS.fr;
            
            // Mettre à jour les textes du drawer
            
            const drawerSanteMentale = document.getElementById('drawerSanteMentale');
            const drawerDroits = document.getElementById('drawerDroits');
            const drawerDocuments = document.getElementById('drawerDocuments');
            const drawerThemeText = document.getElementById('drawerThemeText');
            const drawerStatus = document.getElementById('drawerStatus');
            const drawerSectionsTitle = document.getElementById('drawerSectionsTitle');
            const drawerToolsTitle = document.getElementById('drawerToolsTitle');
            const drawerTitle = document.querySelector('.drawer-title');
            
            if (drawerDroits) drawerDroits.textContent = t.sectionDroits;
            if (drawerDocuments) drawerDocuments.textContent = t.sectionDocuments;
            if (drawerSanteMentale) drawerSanteMentale.textContent = t.drawerSanteMentale;
            
            // Mettre à jour le texte du thème
            if (drawerThemeText) {
                drawerThemeText.textContent = appState.darkMode ? t.lightMode : t.darkMode;
            }
            
            // Mettre à jour le statut
            if (drawerStatus) drawerStatus.textContent = t.drawerStatus;
            
            // Mettre à jour les titres des sections
            if (drawerSectionsTitle) drawerSectionsTitle.textContent = t.drawerSections;
            if (drawerToolsTitle) drawerToolsTitle.textContent = t.drawerTools;
            if (drawerTitle) drawerTitle.textContent = t.drawerMenu;
        }

        function showEmergencyScreen() {
            const urgenceScreen = document.getElementById('urgenceScreen');
            const mainApp = document.getElementById('mainApp');
            
            if (urgenceScreen && mainApp) {
                urgenceScreen.style.display = 'flex';
                mainApp.style.display = 'none';
            }
        }

        // ============ GESTION DE LA LANGUE ============
        function initLanguage() {
            const languageSelect = document.getElementById('languageSelect');
            if (!languageSelect) return;
            
            // Charger la langue sauvegardée ou utiliser la langue par défaut
            const savedLanguage = localStorage.getItem('sos_guide_language');
            if (savedLanguage && CONFIG.supportedLanguages.includes(savedLanguage)) {
                appState.currentLanguage = savedLanguage;
                languageSelect.value = savedLanguage;
            } else {
                // Détecter la langue du navigateur
                const browserLang = navigator.language.split('-')[0];
                if (CONFIG.supportedLanguages.includes(browserLang)) {
                    appState.currentLanguage = browserLang;
                    languageSelect.value = browserLang;
                }
            }
            
            // Événement de changement de langue
            languageSelect.addEventListener('change', function() {
                const newLang = this.value;
                if (CONFIG.supportedLanguages.includes(newLang)) {
                    changeLanguage(newLang);
                }
            });
            
            // Charger les données dans la langue courante
            loadAllData();
        }

        function changeLanguage(newLang) {
            appState.currentLanguage = newLang;
            localStorage.setItem('sos_guide_language', newLang);
            
            // Mettre à jour l'interface
            updateInterfaceLanguage();
            
            // Mettre à jour le drawer
            updateDrawerTranslations();
            
            // Recharger les données
            loadAllData();
            
            showNotification(`Langue changée: ${getLanguageName(newLang)}`);
        }

        function updateInterfaceLanguage() {
            const lang = appState.currentLanguage;
            const t = TRANSLATIONS[lang] || TRANSLATIONS.fr;
            
            // Mettre à jour les titres
            const headerTitle = document.querySelector('.header-title span:nth-child(2)');
            const headerBadge = document.querySelector('.header-badge');
            const skipUrgenceBtn = document.getElementById('skipUrgence');
            
            if (headerTitle) headerTitle.textContent = t.appTitle;
            if (headerBadge) headerBadge.textContent = t.offlineBadge;
            if (skipUrgenceBtn) skipUrgenceBtn.textContent = t.skipUrgence;
            
            // Mettre à jour les sections
            const sectionIds = ['Urgence', 'Secours', 'Survie', 'Sante', 'Droits', 'Documents'];
            sectionIds.forEach(id => {
                const element = document.getElementById(`section${id}`);
                if (element) element.textContent = t[`section${id}`];
            });
            
            // Mettre à jour l'écran d'urgence
            const urgenceTitle = document.querySelector('.urgence-title');
            if (urgenceTitle) urgenceTitle.textContent = t.emergencyScreenTitle;
            
            // Mettre à jour les labels d'urgence
            const emergencyElements = {
                '.urgence-btn.samu .urgence-label': t.emergencyNumbers[15],
                '.urgence-btn.police .urgence-label': t.emergencyNumbers[17],
                '.urgence-btn.pompiers .urgence-label': t.emergencyNumbers[18],
                '.urgence-btn.europe .urgence-label': t.emergencyNumbers[112]
            };
            
            Object.entries(emergencyElements).forEach(([selector, text]) => {
                const element = document.querySelector(selector);
                if (element) element.textContent = text;
            });
            
            // Mettre à jour la carte de bienvenue
            const welcomeTitle = document.getElementById('welcomeTitle');
            const welcomeText = document.getElementById('welcomeText');
            const welcomeButton = document.getElementById('installButton');
            const welcomeTip = document.getElementById('welcomeTip');
            
            if (welcomeTitle) welcomeTitle.textContent = t.welcomeTitle;
            if (welcomeText) welcomeText.textContent = t.welcomeText;
            if (welcomeButton) welcomeButton.innerHTML = `<span>${t.welcomeButton}</span>`;
            if (welcomeTip) welcomeTip.textContent = t.welcomeTip;
        }

        function getLanguageName(code) {
            const names = {
                fr: 'Français',
                en: 'English',
                de: 'Deutsch',
                es: 'Español',
                it: 'Italiano',
                pt: 'Português',
                ar: 'العربية',
                ru: 'Русский',
                tr: 'Türkçe',
                nl: 'Nederlands',
                sv: 'Svenska'
            };
            return names[code] || code;
        }

        // ============ CHARGEMENT DES DONNÉES ============
        async function loadAllData() {
	    const lang = appState.currentLanguage;
	    
	    try {
		// Charger seulement les deux fichiers existants
		const [faqData, droitsData, documentsData] = await Promise.all([
		    loadJSON(`/data/${lang}/${CONFIG.dataFiles.faq}`),
		    loadJSON(`/data/${lang}/${CONFIG.dataFiles.droits}`),
		    loadJSON(`/data/${lang}/${CONFIG.dataFiles.documents}`)
		]);
		
		// Stocker les données
		appState.loadedData.faq = faqData;
		appState.loadedData.droits = droitsData;
		appState.loadedData.documents = documentsData;
		
		// Mettre à jour l'interface
		populateFaq();
		populateDroitsDevoirs();
		populateDocuments();
		
		console.log(`Données chargées pour la langue: ${lang}`);
		
	    } catch (error) {
		console.error('Erreur de chargement des données:', error);
		
		// Fallback vers le français si échec
		if (lang !== 'fr') {
		    showNotification(`Langue ${lang} non disponible, retour au français`);
		    changeLanguage('fr');
		} else {
		    // Fallback vers les données intégrées
		    useFallbackData();
		}
	    }
	}

        async function loadJSON(url) {
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return await response.json();
        }

        function useFallbackData() {
            appState.loadedData.droits = [
                {
                    id: 'droit1',
                    title: 'DROIT À LA SÉCURITÉ',
                    content: 'Toute personne a droit à la vie, à la liberté et à la sûreté de sa personne. En situation d\'urgence...',
                    tag: 'DROIT'
                }
            ];
            
            appState.loadedData.documents = [
                {
                    id: 'ddhc',
                    title: 'DÉCLARATION DES DROITS DE L\'HOMME ET DU CITOYEN',
                    date: '26 août 1789',
                    content: '**Articles essentiels en situation d\'urgence:**\n\n**Article 1:** Les hommes naissent et demeurent libres et égaux en droits.'
                }
            ];
            
            populateDroitsDevoirs();
            populateDocuments();
            
            showNotification('Données de secours chargées');
        }

        // ============ FONCTIONS D'AFFICHAGE ============
        function populateSection(containerId, items) {
            const container = document.getElementById(containerId);
            if (!container) return;
            
            // Vider le conteneur complètement
            container.innerHTML = '';
            
            // Si pas d'items, afficher un message
            if (!items || items.length === 0) {
                container.innerHTML = `
                    <div class="survival-card" style="text-align: center; padding: 40px 20px; grid-column: 1 / -1;">
                        <div class="card-icon">📋</div>
                        <div class="card-title">Contenu en préparation</div>
                        <div class="card-content">Cette section sera bientôt disponible dans cette langue.</div>
                    </div>
                `;
                return;
            }
            
            // Créer toutes les cartes
            items.forEach(item => {
                const card = document.createElement('div');
                card.className = 'survival-card animate-fadeIn';
                card.id = item.id;
                
                // CRÉER LA STRUCTURE COMPLÈTE AVEC BADGE
                card.innerHTML = `
                    <div class="card-icon">${item.icon}</div>
                    <div class="card-title">${item.title}</div>
                `;
                
                // Ajouter l'event listener
                card.addEventListener('click', () => openSurvivalModal(item));
                
                container.appendChild(card);
            });
        }

        function populateDroitsDevoirs() {
            const container = document.getElementById('droitsContainer');
            if (!container) return;
            
            container.innerHTML = '';
            
            const items = appState.loadedData.droits || [];
            
            if (items.length === 0) {
                container.innerHTML = `
                    <div class="document-card animate-fadeIn" style="text-align: center; padding: 40px 20px;">
                        <div class="document-title">Contenu en cours de traduction</div>
                        <div class="document-content">Cette section sera bientôt disponible dans cette langue.</div>
                    </div>
                `;
                return;
            }
            
            items.forEach(doc => {
                const card = document.createElement('div');
                card.className = 'document-card animate-fadeIn';
                card.innerHTML = `
                    <div class="document-title">${doc.title}</div>
                    <div class="card-tag">${doc.tag}</div>
                    <div class="document-content">${doc.content}</div>
                `;
                container.appendChild(card);
            });
        }
        

        function populateDocuments() {
            const container = document.getElementById('constitutionsContainer');
            if (!container) return;
            
            container.innerHTML = '';
            
            const items = appState.loadedData.documents || [];
            
            if (items.length === 0) {
                container.innerHTML = `
                    <div class="document-card animate-fadeIn" style="text-align: center; padding: 40px 20px;">
                        <div class="document-title">Contenu en cours de traduction</div>
                        <div class="document-content">Cette section sera bientôt disponible dans cette langue.</div>
                    </div>
                `;
                return;
            }
            
            items.forEach(doc => {
                const card = document.createElement('div');
                card.className = 'document-card animate-fadeIn';
                
                // Créer un aperçu court (premier paragraphe seulement)
                const preview = doc.content.split('\n\n')[0] || doc.content.substring(0, 150);
                
                card.innerHTML = `
                    <div class="document-title">${doc.title}</div>
                    <div class="document-date">📅 ${doc.date}</div>
                    <div class="document-preview">${preview.substring(0, 200)}...</div>
                    <div class="document-more" onclick="openDocumentModal('${doc.id}')">
                        📖 Lire le document complet
                    </div>
                `;
                container.appendChild(card);
            });
        }
        
        function populateFaq() {
	    const container = document.getElementById('faqContainer');
	    if (!container) return;
	    
	    container.innerHTML = '';
	    
	    const items = appState.loadedData.faq || [];
	    
	    if (items.length === 0) {
		container.innerHTML = `
		    <div class="document-card animate-fadeIn" style="text-align: center; padding: 40px 20px;">
		        <div class="document-title">Section en préparation</div>
		        <div class="document-content">Les conseils de santé mentale seront bientôt disponibles.</div>
		    </div>
		`;
		return;
	    }
	    
	    // Créer les cartes FAQ
	    items.forEach(item => {
		const card = document.createElement('div');
		card.className = 'faq-card animate-fadeIn';
		
		card.innerHTML = `
		    <div class="faq-question">
		        ${item.question}
		        <span class="faq-indicator">▼</span>
		    </div>
		    <div class="faq-answer">${item.answer.replace(/\n/g, '<br>')}</div>
		`;
		
		// Toggle pour ouvrir/fermer la réponse
		card.addEventListener('click', function() {
		    this.classList.toggle('active');
		    
		    // Fermer les autres FAQ si celle-ci s'ouvre
		    if (this.classList.contains('active')) {
			document.querySelectorAll('.faq-card.active').forEach(otherCard => {
			    if (otherCard !== this) {
				otherCard.classList.remove('active');
			    }
			});
		    }
		});
		
		container.appendChild(card);
	    });
	}

        // ============ GESTION DES MODALES ============
        function initModals() {
            // Modal pour les cartes de survie
            const tempModalClose = document.getElementById('tempModalClose');
            if (tempModalClose) {
                tempModalClose.addEventListener('click', closeTempModal);
            }
            
            // Modal pour les documents
            const modalClose = document.getElementById('modalClose');
            if (modalClose) {
                modalClose.addEventListener('click', closeDocumentModal);
            }
            
            // Fermer les modales avec la touche Échap
            document.addEventListener('keydown', function(e) {
                if (e.key === 'Escape') {
                    closeTempModal();
                    closeDocumentModal();
                    closeDrawer();
                }
            });
            
            // Fermer les modales en cliquant à l'extérieur
            document.addEventListener('click', function(e) {
                const tempModal = document.getElementById('tempModal');
                const documentModal = document.getElementById('documentModal');
                
                if (tempModal && tempModal.style.display === 'block' && 
                    e.target === tempModal) {
                    closeTempModal();
                }
                
                if (documentModal && documentModal.style.display === 'flex' && 
                    e.target === documentModal) {
                    closeDocumentModal();
                }
            });
        }

        function openSurvivalModal(item) {
            // Fermer d'abord toute autre modal ouverte
            closeTempModal();
            closeDocumentModal();
            closeDrawer();
            
            const tempModal = document.getElementById('tempModal');
            const tempModalIcon = document.getElementById('tempModalIcon');
            const tempModalTitle = document.getElementById('tempModalTitle');
            const tempModalContent = document.getElementById('tempModalContent');
            
            if (tempModal && tempModalIcon && tempModalTitle && tempModalContent) {
                tempModalIcon.textContent = item.icon;
                tempModalTitle.textContent = item.title;
                
                // Formater le contenu
                const formattedContent = item.content
                    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                    .replace(/\n/g, '<br>');
                
                tempModalContent.innerHTML = formattedContent;
                tempModal.style.display = 'block';
            }
        }

        function openDocumentModal(documentId) {
            // Fermer d'abord toute autre modal ouverte
            closeTempModal();
            closeDocumentModal();
            closeDrawer();
            
            const items = appState.loadedData.documents || [];
            const doc = items.find(d => d.id === documentId);
            if (!doc) return;
            
            const modal = document.getElementById('documentModal');
            const modalDocTitle = document.getElementById('modalDocTitle');
            const modalDocDate = document.getElementById('modalDocDate');
            const modalDocContent = document.getElementById('modalDocContent');
            
            if (modal && modalDocTitle && modalDocDate && modalDocContent) {
                modalDocTitle.textContent = doc.title;
                modalDocDate.textContent = `📅 ${doc.date}`;
                
                // Formater le contenu
                const formattedContent = doc.content
                    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                    .replace(/\n/g, '<br>');
                
                modalDocContent.innerHTML = formattedContent;
                modal.style.display = 'flex';
            }
        }

        function closeTempModal() {
            const tempModal = document.getElementById('tempModal');
            if (tempModal) {
                tempModal.style.display = 'none';
            }
        }

        function closeDocumentModal() {
            const documentModal = document.getElementById('documentModal');
            if (documentModal) {
                documentModal.style.display = 'none';
            }
        }

        // ============ GESTION DU THÈME ============
        function initTheme() {
            const themeToggle = document.getElementById('themeToggle');
            const savedTheme = localStorage.getItem('sos_guide_theme');
            
            if (savedTheme === 'dark') {
                enableDarkMode();
            } else {
                enableLightMode();
            }
            
            if (themeToggle) {
                themeToggle.addEventListener('click', toggleTheme);
            }
        }

        function toggleTheme() {
            if (appState.darkMode) {
                enableLightMode();
            } else {
                enableDarkMode();
            }
        }

        function enableDarkMode() {
            document.body.classList.add('dark-mode');
            const themeToggle = document.getElementById('themeToggle');
            const drawerThemeText = document.getElementById('drawerThemeText');
            if (themeToggle) {
                themeToggle.textContent = '☀️';
            }
            if (drawerThemeText) {
                drawerThemeText.textContent = TRANSLATIONS[appState.currentLanguage].lightMode;
            }
            appState.darkMode = true;
            localStorage.setItem('sos_guide_theme', 'dark');
            showNotification(TRANSLATIONS[appState.currentLanguage].darkModeOn);
        }

        function enableLightMode() {
            document.body.classList.remove('dark-mode');
            const themeToggle = document.getElementById('themeToggle');
            const drawerThemeText = document.getElementById('drawerThemeText');
            if (themeToggle) {
                themeToggle.textContent = '🌙';
            }
            if (drawerThemeText) {
                drawerThemeText.textContent = TRANSLATIONS[appState.currentLanguage].darkMode;
            }
            appState.darkMode = false;
            localStorage.setItem('sos_guide_theme', 'light');
            showNotification(TRANSLATIONS[appState.currentLanguage].darkModeOff);
        }

        // ============ GESTION PWA ============
        function initPWA() {
            // Vérifier si l'app est déjà installée
            if (window.matchMedia('(display-mode: standalone)').matches || 
                window.navigator.standalone === true) {
                appState.pwaInstalled = true;
                const welcomeCard = document.getElementById('welcomeCard');
                if (welcomeCard) {
                    welcomeCard.style.display = 'none';
                }
            }
            
            // Gérer l'installation PWA
            const installButton = document.getElementById('installButton');
            const welcomeClose = document.getElementById('welcomeClose');
            
            if (installButton) {
                installButton.addEventListener('click', handleInstallClick);
            }
            
            if (welcomeClose) {
                welcomeClose.addEventListener('click', () => {
                    const welcomeCard = document.getElementById('welcomeCard');
                    if (welcomeCard) {
                        welcomeCard.style.display = 'none';
                    }
                    localStorage.setItem('sos_welcome_closed', 'true');
                    showNotification(TRANSLATIONS[appState.currentLanguage].installLater);
                });
            }
            
            // Événement pour la proposition d'installation
            window.addEventListener('beforeinstallprompt', (e) => {
                e.preventDefault();
                appState.deferredPrompt = e;
                
                if (installButton) {
                    installButton.style.display = 'flex';
                }
            });
            
            // Masquer la carte si l'app est déjà installée
            window.addEventListener('appinstalled', () => {
                appState.pwaInstalled = true;
                const welcomeCard = document.getElementById('welcomeCard');
                if (welcomeCard) {
                    welcomeCard.style.display = 'none';
                }
                showNotification(TRANSLATIONS[appState.currentLanguage].installSuccess);
            });
        }

        async function handleInstallClick() {
            if (appState.deferredPrompt) {
                try {
                    appState.deferredPrompt.prompt();
                    const { outcome } = await appState.deferredPrompt.userChoice;
                    
                    if (outcome === 'accepted') {
                        showNotification(TRANSLATIONS[appState.currentLanguage].installSuccess);
                        const welcomeCard = document.getElementById('welcomeCard');
                        if (welcomeCard) {
                            welcomeCard.style.display = 'none';
                        }
                        appState.pwaInstalled = true;
                    } else {
                        showNotification(TRANSLATIONS[appState.currentLanguage].installCancelled);
                    }
                    
                    appState.deferredPrompt = null;
                } catch (error) {
                    console.error('Erreur d\'installation:', error);
                    showPWAInstructions();
                }
            } else {
                showPWAInstructions();
            }
        }

        function showPWAInstructions() {
            const lang = appState.currentLanguage;
            const instructions = {
                fr: {
                    title: '📱 Installation Manuelle',
                    iphone: '1. Appuyez sur "Partager"<br>2. "Sur l\'écran d\'accueil"<br>3. "Ajouter"',
                    android: '1. Menu (⋮) > "Ajouter à l\'écran d\'accueil"<br>2. "Ajouter"',
                    desktop: 'Chrome/Edge: Menu (⋮) > "Installer SOS-GUIDE"'
                },
                en: {
                    title: '📱 Manual Installation',
                    iphone: '1. Tap "Share"<br>2. "Add to Home Screen"<br>3. "Add"',
                    android: '1. Menu (⋮) > "Add to Home Screen"<br>2. "Add"',
                    desktop: 'Chrome/Edge: Menu (⋮) > "Install SOS-GUIDE"'
                },
                de: {
                    title: '📱 Manuelle Installation',
                    iphone: '1. Tippen Sie auf "Teilen"<br>2. "Zum Home-Bildschirm"<br>3. "Hinzufügen"',
                    android: '1. Menü (⋮) > "Zum Startbildschirm hinzufügen"<br>2. "Hinzufügen"',
                    desktop: 'Chrome/Edge: Menü (⋮) > "SOS-GUIDE installieren"'
                },
                es: {
                    title: '📱 Instalación Manual',
                    iphone: '1. Pulse "Compartir"<br>2. "Añadir a inicio"<br>3. "Añadir"',
                    android: '1. Menú (⋮) > "Añadir a la pantalla de inicio"<br>2. "Añadir"',
                    desktop: 'Chrome/Edge: Menú (⋮) > "Instalar SOS-GUÍA"'
                },
                it: {
                    title: '📱 Installazione Manuale',
                    iphone: '1. Tocca "Condividi"<br>2. "Aggiungi a Home"<br>3. "Aggiungi"',
                    android: '1. Menu (⋮) > "Aggiungi alla schermata Home"<br>2. "Aggiungi"',
                    desktop: 'Chrome/Edge: Menu (⋮) > "Installa SOS-GUIDA"'
                },
                pt: {
                    title: '📱 Instalação Manual',
                    iphone: '1. Toque "Partilhar"<br>2. "Adicionar à Tela Inicial"<br>3. "Adicionar"',
                    android: '1. Menu (⋮) > "Adicionar à tela inicial"<br>2. "Adicionar"',
                    desktop: 'Chrome/Edge: Menu (⋮) > "Instalar SOS-GUIA"'
                },
                ar: {
                    title: '📱 التثبيت اليدوي',
                    iphone: '1. انقر على "مشاركة"<br>2. "أضف إلى الشاشة الرئيسية"<br>3. "أضف"',
                    android: '1. القائمة (⋮) > "أضف إلى الشاشة الرئيسية"<br>2. "أضف"',
                    desktop: 'Chrome/Edge: القائمة (⋮) > "تثبيت دليل الإنقاذ"'
                },
                ru: {
		    title: '📱 Ручная установка',
		    iphone: '1. Нажмите "Поделиться"<br>2. "На экран «Домой»"<br>3. "Добавить"',
		    android: '1. Меню (⋮) > "Добавить на главный экран"<br>2. "Добавить"',
		    desktop: 'Chrome/Edge: Меню (⋮) > "Установить SOS-GUIDE"'
		},
                tr: {
		    title: '📱 Manuel Kurulum',
		    iphone: '1. "Paylaş"a dokunun<br>2. "Ana Ekrana"<br>3. "Ekle"',
		    android: '1. Menü (⋮) > "Ana ekrana ekle"<br>2. "Ekle"',
		    desktop: 'Chrome/Edge: Menü (⋮) > "SOS REHBER\'i Yükle"'
		},
                nl: {
		    title: '📱 Handmatige Installatie',
		    iphone: '1. Tik op "Delen"<br>2. "Zet op beginscherm"<br>3. "Toevoegen"',
		    android: '1. Menu (⋮) > "Toevoegen aan beginscherm"<br>2. "Toevoegen"',
		    desktop: 'Chrome/Edge: Menu (⋮) > "SOS-GIDS installeren"'
		},
                sv: {
		    title: '📱 Manuell Installation',
		    iphone: '1. Tryck på "Dela"<br>2. "Lägg till på hemskärmen"<br>3. "Lägg till"',
		    android: '1. Meny (⋮) > "Lägg till på hemskärmen"<br>2. "Lägg till"',
		    desktop: 'Chrome/Edge: Meny (⋮) > "Installera SOS-GUIDE"'
		}
            };
            
            const instr = instructions[lang] || instructions.fr;
            
            const modal = document.createElement('div');
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.95);
                z-index: 4000;
                padding: 80px 20px 20px;
                overflow-y: auto;
                color: white;
            `;
            
            modal.innerHTML = `
                <button onclick="this.parentElement.remove()" style="position: fixed; top: 20px; right: 20px; background: #333; border: none; color: white; width: 44px; height: 44px; border-radius: 50%; font-size: 1.2rem; z-index: 4001; cursor: pointer;">✕</button>
                <div style="max-width: 600px; margin: 0 auto;">
                    <h1 style="font-size: 1.8rem; margin-bottom: 25px; font-weight: 900; text-align: center;">${instr.title}</h1>
                    
                    <div style="background: #222; padding: 25px; border-radius: 20px; margin-bottom: 20px;">
                        <div style="display: flex; align-items: center; gap: 15px; margin-bottom: 20px;">
                            <div style="font-size: 2rem;">📱</div>
                            <div>
                                <div style="font-weight: 700; font-size: 1.1rem;">iPhone (Safari)</div>
                                <div style="opacity: 0.9;">${instr.iphone}</div>
                            </div>
                        </div>
                        
                        <div style="display: flex; align-items: center; gap: 15px; margin-bottom: 20px;">
                            <div style="font-size: 2rem;">🤖</div>
                            <div>
                                <div style="font-weight: 700; font-size: 1.1rem;">Android (Chrome)</div>
                                <div style="opacity: 0.9;">${instr.android}</div>
                            </div>
                        </div>
                        
                        <div style="display: flex; align-items: center; gap: 15px;">
                            <div style="font-size: 2rem;">💻</div>
                            <div>
                                <div style="font-weight: 700; font-size: 1.1rem;">Desktop</div>
                                <div style="opacity: 0.9;">${instr.desktop}</div>
                            </div>
                        </div>
                    </div>
                    
                    <div style="background: #333; padding: 20px; border-radius: 15px;">
                        <strong>🎯 Avantages de l'installation :</strong><br><br>
                        • Accès direct depuis l'écran d'accueil<br>
                        • Fonctionne comme une vraie application<br>
                        • Lancement rapide<br>
                        • 100% hors-ligne<br>
                        • Mises à jour automatiques
                    </div>
                </div>
            `;
            
            document.body.appendChild(modal);
            
            // Fermer la modal en cliquant à l'extérieur
            modal.addEventListener('click', function(e) {
                if (e.target === modal) {
                    modal.remove();
                }
            });
        }

        // ============ UTILITAIRES ============
        function showNotification(message, duration = 3000) {
            const notification = document.getElementById('notification');
            if (notification) {
                notification.textContent = message;
                notification.style.display = 'block';
                
                setTimeout(() => {
                    notification.style.display = 'none';
                }, duration);
            }
        }

        function initEvents() {
            // Écran d'urgence
            const skipUrgence = document.getElementById('skipUrgence');
            if (skipUrgence) {
                skipUrgence.addEventListener('click', function() {
                    const urgenceScreen = document.getElementById('urgenceScreen');
                    const mainApp = document.getElementById('mainApp');
                    if (urgenceScreen && mainApp) {
                        urgenceScreen.style.display = 'none';
                        mainApp.style.display = 'block';
                        showNotification(TRANSLATIONS[appState.currentLanguage].guideLoaded);
                    }
                });
            }
            
            
            
            // Détection hors-ligne
            window.addEventListener('offline', () => {
                showNotification(TRANSLATIONS[appState.currentLanguage].offlineMode);
                const drawerStatus = document.getElementById('drawerStatus');
                if (drawerStatus) drawerStatus.textContent = TRANSLATIONS[appState.currentLanguage].drawerStatus;
            });
            
            window.addEventListener('online', () => {
                const drawerStatus = document.getElementById('drawerStatus');
                if (drawerStatus) drawerStatus.textContent = '● EN LIGNE';
            });
        }

        // ============ FONCTIONS GLOBALES ============
        window.openDocumentModal = openDocumentModal;
        window.scrollToSection = function(sectionId) {
            const element = document.getElementById(sectionId);
            if (element) {
                element.scrollIntoView({ behavior: 'smooth' });
            }
        };
