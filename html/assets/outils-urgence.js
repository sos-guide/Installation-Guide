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
  if (OUTILS.flash.actif) return;
  OUTILS.flash.actif = true;
  updateCardUI('flash', true);

  // Overlay de flash (fond noir/blanc)
  const flashDiv = document.createElement('div');
  flashDiv.id = 'flashSOS';
  flashDiv.style.cssText = `
    position: fixed;
    top: 0; left: 0;
    width: 100vw; height: 100vh;
    z-index: 9999;
    transition: background-color 0.1s;
  `;
  document.body.appendChild(flashDiv);

  // Bouton d'arrêt (toujours visible)
  const stopBtn = document.createElement('button');
  stopBtn.textContent = '✕ ARRÊTER';
  stopBtn.setAttribute('aria-label', 'Arrêter le flash SOS');
  stopBtn.style.cssText = `
    position: fixed;
    bottom: 30px;
    right: 30px;
    padding: 15px 25px;
    background: rgba(255, 69, 58, 0.9);
    color: white;
    border: none;
    border-radius: 50px;
    font-size: 1.2rem;
    font-weight: bold;
    z-index: 10000;
    cursor: pointer;
    box-shadow: 0 4px 15px rgba(0,0,0,0.3);
    backdrop-filter: blur(5px);
    transition: transform 0.2s, background 0.2s;
  `;
  stopBtn.onmouseover = () => {
    stopBtn.style.transform = 'scale(1.05)';
    stopBtn.style.background = '#ff2d55';
  };
  stopBtn.onmouseout = () => {
    stopBtn.style.transform = 'scale(1)';
    stopBtn.style.background = 'rgba(255, 69, 58, 0.9)';
  };
  stopBtn.onclick = (e) => {
    e.stopPropagation();
    stopFlash();
  };
  document.body.appendChild(stopBtn);
  OUTILS.flash.stopButton = stopBtn;

  // Séquence SOS : 3 courts, 3 longs, 3 courts
  // Chaque durée est suivie d'un changement de couleur (blanc/noir)
  const pattern = [
    300, // blanc
    300, // noir
    300, // blanc
    300, // noir
    300, // blanc
    700, // noir
    700, // blanc
    700, // noir
    700, // blanc
    700, // noir
    300, // blanc
    300, // noir
    300, // blanc
    300, // noir
    300  // blanc
  ];

  let index = 0;

  const pulse = () => {
    if (!OUTILS.flash.actif) return;
    // Alterner la couleur de fond : blanc pour les indices pairs, noir pour les impairs
    flashDiv.style.backgroundColor = (index % 2 === 0) ? 'white' : 'black';
    OUTILS.flash.timer = setTimeout(() => {
      index++;
      if (index < pattern.length) {
        pulse();
      } else {
        // Fin de séquence : pause 1 seconde (fond noir) puis recommencer
        index = 0;
        flashDiv.style.backgroundColor = 'black';
        OUTILS.flash.timer = setTimeout(pulse, 1000);
      }
    }, pattern[index]);
  };

  pulse();
}

function stopFlash() {
  OUTILS.flash.actif = false;
  clearTimeout(OUTILS.flash.timer);
  OUTILS.flash.timer = null;

  const flashDiv = document.getElementById('flashSOS');
  if (flashDiv) flashDiv.remove();

  if (OUTILS.flash.stopButton) {
    OUTILS.flash.stopButton.remove();
    OUTILS.flash.stopButton = null;
  }

  updateCardUI('flash', false);
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
