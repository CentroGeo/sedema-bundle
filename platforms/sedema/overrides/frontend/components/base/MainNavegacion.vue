<script setup>
const { status, signIn } = useAuth();
const route = useRoute();
const config = useRuntimeConfig();

const menuAbierto = ref(false);

async function iniciarSesion() {
  await signIn('keycloak', {
    callbackUrl: route.fullPath,
  });
}

function alternarMenu() {
  menuAbierto.value = !menuAbierto.value;
}
function cerrarMenu() {
  menuAbierto.value = false;
}

const mostrarInicio = computed(() => config.public.defaultPage);
const mostrarCatalogo = computed(() => config.public.enableCatalogoVista);
const mostrarConsulta = computed(() => config.public.enableConsulta);
const mostrarIaa = computed(() => config.public.enableIaa);
const mostrarLevantamiento = computed(() => config.public.enableLevantamiento);
const mostrarAuth = computed(() => config.public.enableAuth);

const esActiva = (path) => route.path === path;
</script>

<template>
  <section class="mainnav-wrap" aria-label="Navegación principal del sitio">
    <div class="mainnav-accent" />
    <div class="mainnav-container mainnav">
      <NuxtLink to="/" class="mainnav__logo" aria-label="SEDEMA inicio" @click="cerrarMenu">
        <img
          :src="`${config.app.baseURL}img/sedema/Logo_Dependencia_sedema.png`"
          alt="Secretaría del Medio Ambiente"
        />
      </NuxtLink>

      <button
        class="nav-toggle"
        type="button"
        :aria-expanded="menuAbierto"
        aria-controls="main-menu"
        aria-label="Abrir menú"
        @click="alternarMenu"
      >
        <span />
        <span />
        <span />
      </button>

      <nav
        id="main-menu"
        class="menu"
        :class="{ 'is-open': menuAbierto }"
        aria-label="Menú principal"
      >
        <NuxtLink
          v-if="mostrarInicio"
          to="/"
          :class="{ 'is-active': esActiva('/') }"
          @click="cerrarMenu"
        >
          Inicio
        </NuxtLink>
        <NuxtLink
          v-if="mostrarCatalogo"
          to="/catalogo"
          :class="{ 'is-active': esActiva('/catalogo') }"
          @click="cerrarMenu"
        >
          Catálogo
        </NuxtLink>
        <NuxtLink
          v-if="mostrarConsulta"
          to="/consulta"
          :class="{ 'is-active': esActiva('/consulta') }"
          @click="cerrarMenu"
        >
          Consulta
        </NuxtLink>
        <NuxtLink
          v-if="mostrarIaa && status === 'authenticated'"
          to="/ia"
          :class="{ 'is-active': esActiva('/ia') }"
          @click="cerrarMenu"
        >
          IA
        </NuxtLink>
        <NuxtLink
          v-if="mostrarLevantamiento && status === 'authenticated'"
          to="/levantamiento"
          :class="{ 'is-active': esActiva('/levantamiento') }"
          @click="cerrarMenu"
        >
          Levantamiento
        </NuxtLink>

        <template v-if="mostrarAuth">
          <NuxtLink
            v-if="status === 'authenticated'"
            to="/mi-cuenta"
            class="menu__btn"
            :class="{ 'is-active': esActiva('/mi-cuenta') }"
            @click="cerrarMenu"
          >
            Mi cuenta
          </NuxtLink>
          <button v-else type="button" class="menu__btn" @click="iniciarSesion">
            Iniciar sesión
          </button>
        </template>
      </nav>
    </div>
    <div class="mainnav-separator" />
  </section>
</template>

<style scoped>
.mainnav-wrap {
  background: #fcf8e3;
  position: sticky;
  top: 0;
  z-index: 30;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.03);
  font-family: 'Montserrat', sans-serif;
}
.mainnav-accent {
  height: 1px;
  background: rgba(6, 70, 53, 0.15);
}
.mainnav-container {
  width: min(calc(100% - 48px), 1280px);
  margin-inline: auto;
}
.mainnav {
  min-height: 52px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 0;
}
.mainnav__logo {
  display: inline-block;
}
.mainnav__logo img {
  height: 48px;
  width: auto;
  object-fit: contain;
  display: block;
}
.mainnav-separator {
  height: 6px;
  background-color: #064635;
}
.menu {
  display: flex;
  align-items: center;
  gap: 6px;
}
.menu a,
.menu button {
  height: 40px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0 18px;
  border-radius: 12px;
  color: #064635;
  font-size: 15px;
  font-weight: 700;
  font-family: inherit;
  background: transparent;
  border: none;
  cursor: pointer;
  text-decoration: none;
  transition: all 0.25s ease;
}
.menu a:hover,
.menu a.is-active,
.menu button:hover {
  background: rgba(6, 70, 53, 0.08);
}
.menu__btn {
  border: 1px solid rgba(6, 70, 53, 0.35);
  background: rgba(255, 255, 255, 0.45);
}
.menu__btn:hover {
  background: #064635 !important;
  color: #fff !important;
  border-color: #064635;
}
.nav-toggle {
  display: none;
  width: 46px;
  height: 46px;
  border: 1px solid rgba(6, 70, 53, 0.2);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.6);
  padding: 10px;
  cursor: pointer;
}
.nav-toggle span {
  display: block;
  height: 2px;
  background: #064635;
  margin: 5px 0;
  border-radius: 10px;
  transition: 0.25s ease;
}

@media (max-width: 900px) {
  .mainnav {
    position: relative;
  }
  .mainnav__logo img {
    height: 52px;
  }
  .nav-toggle {
    display: block;
  }
  .menu {
    position: absolute;
    top: calc(100% + 10px);
    right: 0;
    width: min(320px, calc(100vw - 32px));
    background: rgba(252, 248, 227, 0.98);
    border: 1px solid rgba(6, 70, 53, 0.12);
    border-radius: 18px;
    box-shadow: 0 22px 40px rgba(0, 0, 0, 0.12);
    padding: 12px;
    flex-direction: column;
    align-items: stretch;
    gap: 4px;
    opacity: 0;
    visibility: hidden;
    transform: translateY(-8px);
    transition: all 0.25s ease;
    z-index: 40;
  }
  .menu.is-open {
    opacity: 1;
    visibility: visible;
    transform: translateY(0);
  }
  .menu a,
  .menu button {
    justify-content: flex-start;
    height: 44px;
  }
}

@media (max-width: 640px) {
  .mainnav-container {
    width: min(calc(100% - 28px), 1280px);
  }
  .mainnav {
    gap: 14px;
  }
  .mainnav__logo img {
    height: 44px;
  }
}
</style>
