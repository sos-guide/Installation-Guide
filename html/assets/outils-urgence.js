// ============ OUTILS D'URGENCE VITAUX ============
// 3 outils seulement : Métronome RCP + Flash SOS + Sifflet

const OUTILS = {
  metronome: { actif: false, timer: null },
  flash: { actif: false, timer: null }
};

// === 1. MÉTRONOME RCP (110 BPM) ===
function toggleMetronome() {
  const etat = OUTILS.metronome;
  
  if (etat.actif) {
    clearInterval(etat.timer);
    etat.actif = false;
    updateCardUI('metronome', false);
  } else {
    etat.actif = true;
    updateCardUI('metronome', true);
    
    // Bip immédiat puis toutes les 545ms (110 BPM)
    jouerBip();
    etat.timer = setInterval(jouerBip, 545);
  }
}

function jouerBip() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    osc.frequency.value = 800;
    osc.connect(ctx.destination);
    osc.start();
    setTimeout(() => osc.stop(), 100);
  } catch(e) {}
}

// === 2. FLASH SOS ===
function toggleFlash() {
  if (OUTILS.flash.actif) {
    stopFlash();
  } else {
    startFlash();
  }
}

function startFlash() {
  OUTILS.flash.actif = true;
  updateCardUI('flash', true);
  
  // Créer div flash
  const flashDiv = document.createElement('div');
  flashDiv.id = 'flashSOS';
  flashDiv.style.cssText = `
    position: fixed;
    top: 0; left: 0;
    width: 100vw; height: 100vh;
    z-index: 9999;
    background: white;
    opacity: 0;
    transition: opacity 0.1s;
  `;
  document.body.appendChild(flashDiv);
  
  // Pattern SOS : ... --- ...
  const pattern = [
    // 3 courts
    300, // Flash blanc
    300, // Noir
    300, // Blanc
    // 3 longs
    700, // Noir
    700, // Blanc
    700, // Noir
    // 3 courts
    300, // Blanc
    300, // Noir
    300  // Blanc
  ];
  
  let index = 0;
  
  function pulse() {
    if (!OUTILS.flash.actif) return;
    
    // Alterner entre visible (1) et invisible (0)
    flashDiv.style.opacity = (index % 2 === 0) ? '1' : '0';
    
    // Prochain flash après la durée du pattern
    OUTILS.flash.timer = setTimeout(() => {
      index++;
      if (index < pattern.length) {
        pulse();
      } else {
        // Recommencer après 1 seconde
        index = 0;
        OUTILS.flash.timer = setTimeout(pulse, 1000);
      }
    }, pattern[index]);
  }
  
  pulse();
}

function stopFlash() {
  OUTILS.flash.actif = false;
  clearTimeout(OUTILS.flash.timer);
  OUTILS.flash.timer = null;
  updateCardUI('flash', false);
  const flashDiv = document.getElementById('flashSOS');
  if (flashDiv) flashDiv.remove();
}

// === 3. SIFFLET (simple) ===
function jouerSifflet() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    osc.frequency.value = 1200;
    osc.connect(ctx.destination);
    osc.start();
    setTimeout(() => osc.stop(), 2000);
    
    // Feedback visuel
    const card = document.querySelector('[data-outil="sifflet"]');
    if (card) {
      card.classList.add('active');
      setTimeout(() => card.classList.remove('active'), 2000);
    }
  } catch(e) {}
}

// === INITIALISATION ===
function initOutils() {
  const html = `
    <div class="outil-card" data-outil="metronome" onclick="toggleMetronome()">
      <div class="outil-icon">❤️</div>
      <div class="outil-title" data-i18n="outilMetronome">MÉTRONOME RCP</div>
      <div class="outil-desc" data-i18n="outilMetronomeDesc">110 BPM - Compressions cardiaques</div>
      <div class="outil-status"></div>
    </div>
    
    <div class="outil-card" data-outil="flash" onclick="toggleFlash()">
      <div class="outil-icon">🔦</div>
      <div class="outil-title" data-i18n="outilFlash">FLASH SOS</div>
      <div class="outil-desc" data-i18n="outilFlashDesc">··· --- ··· Signal lumineux</div>
      <div class="outil-status"></div>
    </div>
    
    <div class="outil-card" data-outil="sifflet" onclick="jouerSifflet()">
      <div class="outil-icon">📢</div>
      <div class="outil-title" data-i18n="outilSifflet">SIFFLET URGENCE</div>
      <div class="outil-desc" data-i18n="outilSiffletDesc">Son d'alerte - 2 secondes</div>
      <div class="outil-status pulse"></div>
    </div>
  `;
  
  const container = document.getElementById('outilsUrgenceContainer');
  if (container) container.innerHTML = html;
}

// === MISE À JOUR UI ===
function updateCardUI(outilId, actif) {
  const card = document.querySelector(`[data-outil="${outilId}"]`);
  if (!card) return;
  
  const status = card.querySelector('.outil-status');
  if (status) status.style.backgroundColor = actif ? '#32d74b' : '';
  
  card.classList.toggle('active', actif);
}

// === ARRÊTER TOUT ===
function arreterTout() {
  if (OUTILS.metronome.actif) toggleMetronome();
  if (OUTILS.flash.actif) toggleFlash();
}

// === EXPORT ===
window.OUTILS_URGENCE = { 
  initOutils, 
  arreterTout,
  toggleMetronome,
  toggleFlash,
  jouerSifflet
};
