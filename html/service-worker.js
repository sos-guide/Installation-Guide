// ============ SERVICE WORKER SOS-GUIDE ULTIME ============
const CACHE_VERSION = 'sos-guide';
const APP_SHELL = [
  '/',
  '/index.html',
  '/cgu.html',
  '/404.html',
  '/assets/styles.css',
  '/assets/styles-outils.css',
  '/assets/translations-outils.js',
  '/assets/outils-urgence.js',
  '/assets/app.js',
  '/manifest.json',
  
  // Données
  '/data/fr/droits.json',
  '/data/fr/documents.json',
  '/data/en/droits.json',
  '/data/en/documents.json',
  '/data/de/droits.json',
  '/data/de/documents.json',
  '/data/es/droits.json',
  '/data/es/documents.json',
  '/data/it/droits.json',
  '/data/it/documents.json',
  '/data/pt/droits.json',
  '/data/pt/documents.json',
  '/data/ar/droits.json',
  '/data/ar/documents.json',
  '/data/ru/droits.json',
  '/data/ru/documents.json',
  '/data/tr/droits.json',
  '/data/tr/documents.json',
  '/data/nl/droits.json',
  '/data/nl/documents.json',
  '/data/sv/droits.json',
  '/data/sv/documents.json',
  
  // Icônes PNG
  '/assets/icons/icon-72.png',
  '/assets/icons/icon-96.png',
  '/assets/icons/icon-128.png',
  '/assets/icons/icon-144.png',
  '/assets/icons/icon-152.png',
  '/assets/icons/icon-192.png',
  '/assets/icons/icon-384.png',
  '/assets/icons/icon-512.png',
  '/assets/icons/apple-touch-icon.png',
  '/assets/icons/favicon-16.png',
  '/assets/icons/favicon-32.png',
  '/assets/icons/mask-icon.svg'
];

// ============ INSTALLATION ============
self.addEventListener('install', event => {
  console.log('🛠️ Service Worker: Installation');
  
  event.waitUntil(
    caches.open(CACHE_VERSION)
      .then(cache => {
        console.log('📦 Mise en cache des fichiers critiques');
        return cache.addAll(APP_SHELL);
      })
      .then(() => {
        console.log('✅ Installation terminée');
        return self.skipWaiting();
      })
  );
});

// ============ ACTIVATION ============
self.addEventListener('activate', event => {
  console.log('⚡ Service Worker: Activation');
  
  event.waitUntil(
    Promise.all([
      caches.keys().then(cacheNames => {
        return Promise.all(
          cacheNames.map(cacheName => {
            if (cacheName !== CACHE_VERSION) {
              console.log(`🗑️ Suppression ancien cache: ${cacheName}`);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      self.clients.claim()
    ]).then(() => {
      console.log('🎯 Service Worker activé');
    })
  );
});

// ============ INTERCEPTION DES REQUÊTES ============
self.addEventListener('fetch', event => {
  const request = event.request;
  
  // Ignorer les requêtes non-HTTP
  if (!request.url.startsWith('http')) {
    return;
  }
  
  // Stratégie: Cache First, Network Fallback
  event.respondWith(
    caches.match(request)
      .then(cachedResponse => {
        // Si dans le cache, retourner
        if (cachedResponse) {
          // Mettre à jour en arrière-plan si en ligne
          if (navigator.onLine) {
            fetch(request).then(response => {
              if (response.ok) {
                caches.open(CACHE_VERSION).then(cache => {
                  cache.put(request, response);
                });
              }
            }).catch(() => {});
          }
          return cachedResponse;
        }
        
        // Sinon, essayer le réseau
        return fetch(request)
          .then(networkResponse => {
            // Mettre en cache pour la prochaine fois
            if (networkResponse.ok) {
              const responseClone = networkResponse.clone();
              caches.open(CACHE_VERSION)
                .then(cache => cache.put(request, responseClone));
            }
            return networkResponse;
          })
          .catch(error => {
            // Fallback pour les pages
            if (request.mode === 'navigate') {
              return caches.match('/index.html');
            }
            
            // Fallback pour les assets
            if (request.url.includes('.css')) {
              return caches.match('/assets/styles.css');
            }
            
            if (request.url.includes('.js')) {
              return new Response('// Script non disponible hors ligne', {
                headers: { 'Content-Type': 'application/javascript' }
              });
            }
            
            // Fallback générique
            return new Response('Service hors ligne', {
              status: 503,
              headers: { 'Content-Type': 'text/plain' }
            });
          });
      })
  );
});

// ============ GESTION DES MESSAGES ============
self.addEventListener('message', event => {
  if (event.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
