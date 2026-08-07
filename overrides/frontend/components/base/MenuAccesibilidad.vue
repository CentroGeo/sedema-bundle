<script setup>
const props = defineProps({
  objetoStore: {
    type: Object,
    default: () => null,
  },
});

const abierto = ref(false);
const escalaTexto = ref(1);
const altoContraste = ref(false);
const temaOscuro = ref(false);

function alternarMenu() {
  abierto.value = !abierto.value;
}

function aplicarEscala() {
  document.documentElement.style.fontSize = `${escalaTexto.value * 100}%`;
}
function aumentar() {
  if (escalaTexto.value < 1.4) {
    escalaTexto.value = +(escalaTexto.value + 0.1).toFixed(2);
    aplicarEscala();
  }
}
function disminuir() {
  if (escalaTexto.value > 0.8) {
    escalaTexto.value = +(escalaTexto.value - 0.1).toFixed(2);
    aplicarEscala();
  }
}
function reiniciar() {
  escalaTexto.value = 1;
  altoContraste.value = false;
  temaOscuro.value = false;
  aplicarEscala();
  document.body.removeAttribute('data-contraste');
  document.body.removeAttribute('data-tema');
}
function alternarContraste() {
  altoContraste.value = !altoContraste.value;
  if (altoContraste.value) {
    document.body.setAttribute('data-contraste', 'alto');
  } else {
    document.body.removeAttribute('data-contraste');
  }
}
function alternarTema() {
  temaOscuro.value = !temaOscuro.value;
  document.body.setAttribute('data-tema', temaOscuro.value ? 'oscuro' : 'claro');
  if (props.objetoStore?.cambiarTema) {
    props.objetoStore.cambiarTema(temaOscuro.value ? 'oscuro' : 'claro');
  }
}

function alCerrar(e) {
  if (!e.target.closest('.menu-accesibilidad')) abierto.value = false;
}

onMounted(() => {
  document.addEventListener('click', alCerrar);
});
onBeforeUnmount(() => {
  document.removeEventListener('click', alCerrar);
});
</script>

<template>
  <div class="menu-accesibilidad" :class="{ 'is-open': abierto }">
    <button
      type="button"
      class="ma-toggle"
      :aria-expanded="abierto"
      aria-controls="menu-accesibilidad-panel"
      aria-label="Menú de accesibilidad"
      @click.stop="alternarMenu"
    >
      <i class="fa-solid fa-universal-access" />
    </button>

    <div
      v-show="abierto"
      id="menu-accesibilidad-panel"
      class="ma-panel"
      role="dialog"
      aria-label="Opciones de accesibilidad"
    >
      <h4>Accesibilidad</h4>

      <div class="ma-row">
        <span>Tamaño de texto</span>
        <div class="ma-controls">
          <button type="button" aria-label="Disminuir texto" @click="disminuir">A−</button>
          <button type="button" aria-label="Aumentar texto" @click="aumentar">A+</button>
        </div>
      </div>

      <button type="button" class="ma-action" @click="alternarContraste">
        <i class="fa-solid fa-circle-half-stroke" />
        {{ altoContraste ? 'Contraste normal' : 'Alto contraste' }}
      </button>

      <button type="button" class="ma-action" @click="alternarTema">
        <i :class="temaOscuro ? 'fa-solid fa-sun' : 'fa-solid fa-moon'" />
        {{ temaOscuro ? 'Tema claro' : 'Tema oscuro' }}
      </button>

      <button type="button" class="ma-action ma-reset" @click="reiniciar">
        <i class="fa-solid fa-rotate-left" /> Reiniciar
      </button>
    </div>
  </div>
</template>

<style scoped>
.menu-accesibilidad {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 1000;
  font-family: 'Montserrat', sans-serif;
}
.ma-toggle {
  width: 56px;
  height: 56px;
  border-radius: 999px;
  border: none;
  background: #064635;
  color: #fff;
  font-size: 1.6rem;
  cursor: pointer;
  box-shadow: 0 12px 28px rgba(6, 70, 53, 0.3);
  transition:
    transform 0.2s ease,
    background 0.25s ease;
}
.ma-toggle:hover {
  background: #519171;
  transform: translateY(-2px);
}
.ma-panel {
  position: absolute;
  bottom: 70px;
  right: 0;
  width: 280px;
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 18px 48px rgba(0, 0, 0, 0.18);
  border: 1px solid rgba(6, 70, 53, 0.12);
  padding: 18px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.ma-panel h4 {
  margin: 0;
  color: #064635;
  font-size: 1rem;
}
.ma-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 0.9rem;
  color: #4b4b4b;
}
.ma-controls {
  display: flex;
  gap: 6px;
}
.ma-controls button {
  width: 36px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid rgba(6, 70, 53, 0.3);
  background: #fff;
  color: #064635;
  font-weight: 700;
  cursor: pointer;
}
.ma-controls button:hover {
  background: rgba(6, 70, 53, 0.08);
}
.ma-action {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid rgba(6, 70, 53, 0.2);
  background: #fff;
  color: #4b4b4b;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  text-align: left;
}
.ma-action:hover {
  background: rgba(6, 70, 53, 0.08);
  color: #064635;
}
.ma-action i {
  color: #064635;
  width: 16px;
}
.ma-reset {
  border-color: rgba(0, 0, 0, 0.08);
  color: #888;
}
.ma-reset:hover {
  color: #064635;
}

@media (max-width: 640px) {
  .menu-accesibilidad {
    bottom: 16px;
    right: 16px;
  }
  .ma-panel {
    width: calc(100vw - 32px);
    max-width: 280px;
  }
}
</style>
