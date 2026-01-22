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
  const etat = OUTILS.flash;
  
  if (etat.actif) {
    clearTimeout(etat.timer);
    document.body.style.backgroundColor = '';
    etat.actif = false;
    updateCardUI('flash', false);
  } else {
    etat.actif = true;
    updateCardUI('flash', true);
    flashSOS();
  }
}

function flashSOS() {
  const etat = OUTILS.flash;
  if (!etat.actif) return;
  
  // Morse SOS: ··· (3 courts) --- (3 longs) ··· (3 courts)
  const pattern = [300,300,300,700,700,700,300,300,300];
  let index = 0;
  let flashOn = false;
  
  function cycle() {
    if (!etat.actif) return;
    
    flashOn = !flashOn;
    document.body.style.backgroundColor = flashOn ? 'white' : '';
    document.body.style.transition = 'background-color 0.1s';
    
    if (flashOn) {
      index = (index + 1) % pattern.length;
      clearTimeout(etat.timer);
      etat.timer = setTimeout(cycle, pattern[index]);
    } else {
      etat.timer = setTimeout(cycle, 50);
    }
  }
  
  etat.timer = setTimeout(cycle, 50);
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
window.OUTILS_URGENCE = { initOutils, arreterTout };
