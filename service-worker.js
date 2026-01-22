// service-worker.js
const CACHE_NAME = 'sos-guide';
const urlsToCache = [
  './',
  './index.html',
  './cgu.html',
  './404.html',
  './assets/styles.css',
  './manifest.json',
  './service-worker.js',
  './assets/styles-outils.css',
  './assets/translations-outils.js',
  './assets/outils-urgence.js'
];

// Ajouter les fichiers de toutes les langues
const languages = ['fr', 'en', 'de', 'es', 'it', 'pt', 'ar', 'ru', 'tr', 'nl', 'sv'];
const dataFiles = ['faq.json', 'droits.json', 'documents.json'];

languages.forEach(lang => {
  dataFiles.forEach(file => {
    urlsToCache.push(`./data/${lang}/${file}`);
  });
});

// Installation du Service Worker
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Cache ouvert');
        return cache.addAll(urlsToCache);
      })
  );
});

// Activation du Service Worker
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Suppression de l\'ancien cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Stratégie: Cache d'abord, puis réseau
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Retourner la réponse en cache si elle existe
        if (response) {
          return response;
        }
        
        // Sinon, faire la requête réseau
        return fetch(event.request)
          .then(response => {
            // Vérifier si la réponse est valide
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }
            
            // Cloner la réponse
            const responseToCache = response.clone();
            
            // Mettre en cache la nouvelle ressource
            caches.open(CACHE_NAME)
              .then(cache => {
                cache.put(event.request, responseToCache);
              });
            
            return response;
          })
          .catch(() => {
            // Fallback pour les pages HTML
            if (event.request.headers.get('accept').includes('text/html')) {
              return caches.match('./index.html');
            }
          });
      })
  );
});
