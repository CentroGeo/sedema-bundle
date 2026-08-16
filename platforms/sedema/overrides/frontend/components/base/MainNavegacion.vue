<script setup>
import SisdaiNavegacionPrincipal from '@centrogeomx/sisdai-componentes/src/componentes/navegacion-principal/SisdaiNavegacionPrincipal.vue';

const { status, signIn } = useAuth();
const route = useRoute();
const config = useRuntimeConfig();
const store = useLandingBuilderStore();
const storeCatalogo = useCatalogoStore();
const { esAdmin, cargarEsAdmin } = useEsAdmin();
const { mostrarIdentidadGobMx, alternarIdentidadGobMx } = useIdentidadGobMx();

watch(
  status,
  (nuevoEstado) => {
    if (
      import.meta.client &&
      nuevoEstado === 'authenticated' &&
      !storeCatalogo.userInfo?.is_superuser
    ) {
      storeCatalogo.getUserInfo();
    }
  },
  { immediate: true }
);

onMounted(() => {
  cargarEsAdmin();
});

const esConstructor = computed(() => {
  return route.path.startsWith('/landing-builder');
});

const esPaginaPublica = computed(() => {
  return route.path.startsWith('/paginas/');
});

// MainNavegacion vive en el layout persistente: al navegar entre páginas por
// SPA el componente no se remonta, así que hay que observar la ruta en vez
// de depender solo de onMounted para refrescar la identidad de la página
// pública que se está viendo. La identidad pública (logos, nombre, color,
// pie de página) vive en el store para que MainPiePagina.vue pueda leer el
// mismo dato ya cargado, sin repetir el fetch.
watch(
  () => route.fullPath,
  async () => {
    if (import.meta.server) return;

    if (esConstructor.value) {
      if (!store.logoSecundarioUrl) {
        store.cargarConfiguracion();
      }
      return;
    }

    store.cargarPaginas();
    await store.cargarIdentidadPaginaActual(route);
  },
  { immediate: true }
);

// Color de tema (header + footer) de la página actual: el borrador en modo
// constructor, o la identidad publicada en modo página pública / inicio.
const colorTemaActivo = computed(() => {
  if (esConstructor.value) return store.colorTema;
  if (esPaginaPublica.value || store.paginaInicioActiva) return store.identidadPublica.colorTema;
  return null;
});

const estiloTemaHeader = computed(() => {
  if (!colorTemaActivo.value) return {};
  const tintClaro = calcularColorClaro(colorTemaActivo.value);
  return {
    '--navegacion-primaria-fondo': colorTemaActivo.value,
    '--navegacion-primaria-color': calcularColorTextoContraste(colorTemaActivo.value),
    // Fondo hover/focus de los enlaces del menú: un tinte claro del mismo
    // color elegido (no el rosado fijo de sisdai-css), con su propio
    // contraste de texto, para que siga siendo legible con cualquier color.
    '--tema-pagina-cursor-fondo': tintClaro,
    '--tema-pagina-cursor-color': calcularColorTextoContraste(tintClaro),
  };
});

const popoverColorAbierto = ref(false);
const popoverColorRef = ref(null);
onClickOutside(popoverColorRef, () => {
  popoverColorAbierto.value = false;
});

function alternarPopoverColor() {
  popoverColorAbierto.value = !popoverColorAbierto.value;
}

async function iniciarSesion() {
  await signIn('keycloak', {
    callbackUrl: route.fullPath,
  });
}
const mostrarInicio = computed(() => config.public.defaultPage);
const mostrarCatalogo = computed(() => config.public.enableCatalogoVista);
const mostrarConsulta = computed(() => config.public.enableConsulta);
const mostrarIaa = computed(() => config.public.enableIaa);
const mostrarLevantamiento = computed(() => config.public.enableLevantamiento);
const mostrarAuth = computed(() => config.public.enableAuth);
const mostrarAcercaDe = computed(() => config.public.enableAcercaDe);
const mostrarGeocontenidos = computed(() => config.public.enableGeocontenidos);

const modalCambiarLogo1 = ref(null);
const modalCambiarLogo2 = ref(null);
const modalCambiarLogo3 = ref(null);
const modalCambiarLogo4 = ref(null);

function abrirModalLogo1() {
  modalCambiarLogo1.value?.abrirModal();
}

function abrirModalLogo2() {
  modalCambiarLogo2.value?.abrirModal();
}

function abrirModalLogo3() {
  modalCambiarLogo3.value?.abrirModal();
}

function abrirModalLogo4() {
  modalCambiarLogo4.value?.abrirModal();
}

function seleccionarArchivoLogo1(archivo, redir) {
  store.setLogoFile(archivo);
  store.logoRedirectUrl = redir;
}

function seleccionarEnlaceLogo1(enlace, redir) {
  store.setLogoUrl(enlace);
  store.logoRedirectUrl = redir;
}

function eliminarLogo1() {
  store.eliminarLogo();
}

function seleccionarArchivoLogo2(archivo, redir) {
  store.setLogoSecundarioFile(archivo);
  store.logoSecundarioRedirectUrl = redir;
}

function seleccionarEnlaceLogo2(enlace, redir) {
  store.setLogoSecundarioUrl(enlace);
  store.logoSecundarioRedirectUrl = redir;
}

function eliminarLogo2() {
  store.eliminarLogoSecundario();
}

function seleccionarArchivoLogo3(archivo, redir) {
  store.setLogoTerceroFile(archivo);
  store.logoTerceroRedirectUrl = redir;
}

function seleccionarEnlaceLogo3(enlace, redir) {
  store.setLogoTerceroUrl(enlace);
  store.logoTerceroRedirectUrl = redir;
}

function eliminarLogo3() {
  store.eliminarLogoTercero();
}

function seleccionarArchivoLogo4(archivo, redir) {
  store.setLogoCuartoFile(archivo);
  store.logoCuartoRedirectUrl = redir;
}

function seleccionarEnlaceLogo4(enlace, redir) {
  store.setLogoCuartoUrl(enlace);
  store.logoCuartoRedirectUrl = redir;
}

function eliminarLogo4() {
  store.eliminarLogoCuarto();
}
</script>

<template>
  <SisdaiNavegacionPrincipal :style="estiloTemaHeader">
    <template #identidad>
      <!-- Modo Constructor: 4 logos editables (sin imagen precargada si están vacíos) y nombre de la plataforma -->
      <div v-if="esConstructor" class="contenedor-identidades-nav constructor-identidades-nav">
        <!-- Logotipo 1 (Editable, sin imagen predeterminada si está vacío) -->
        <div class="contenedor-logo-nav editando-logo" :class="{ 'logo-vacio': !store.logoUrl }">
          <div v-if="!store.logoUrl" class="logo-placeholder-nav" @click="abrirModalLogo1">
            <span class="pictograma-agregar" aria-hidden="true"></span>
            <span>Logo 1</span>
          </div>
          <NuxtLink
            v-else
            to="/"
            rel="noopener noreferrer"
            class="nav-hiperviculo-logo pointer-events-none"
          >
            <img
              :src="store.resolverUrlImagen(store.logoUrl)"
              class="nav-logo nav-logo--chip"
              alt="Logo principal"
              height="36"
            />
          </NuxtLink>
          <div class="nav-logo-acciones">
            <button
              type="button"
              class="boton-pictograma boton-sin-contenedor-secundario boton-chico boton-accion-logo"
              aria-label="Cambiar logo principal"
              @click="abrirModalLogo1"
            >
              <span class="pictograma-editar" aria-hidden="true"></span>
            </button>
            <button
              type="button"
              class="boton-pictograma boton-sin-contenedor-secundario boton-chico boton-accion-logo"
              aria-label="Eliminar logo principal"
              @click="eliminarLogo1"
            >
              <span class="pictograma-eliminar" aria-hidden="true"></span>
            </button>
          </div>
        </div>

        <!-- Logotipo 2 (Editable, sin imagen predeterminada si está vacío) -->
        <div
          class="contenedor-logo-nav editando-logo"
          :class="{ 'logo-vacio': !store.logoSecundarioUrl }"
        >
          <div
            v-if="!store.logoSecundarioUrl"
            class="logo-placeholder-nav"
            @click="abrirModalLogo2"
          >
            <span class="pictograma-agregar" aria-hidden="true"></span>
            <span>Logo 2</span>
          </div>
          <NuxtLink
            v-else
            to="/"
            rel="noopener noreferrer"
            class="nav-hiperviculo-logo pointer-events-none"
          >
            <img
              :src="store.resolverUrlImagen(store.logoSecundarioUrl)"
              class="nav-logo nav-logo--chip"
              :alt="store.nombrePlataforma || 'SIGIC'"
              height="36"
            />
          </NuxtLink>
          <div class="nav-logo-acciones">
            <button
              type="button"
              class="boton-pictograma boton-sin-contenedor-secundario boton-chico boton-accion-logo"
              aria-label="Cambiar logo secundario"
              @click="abrirModalLogo2"
            >
              <span class="pictograma-editar" aria-hidden="true"></span>
            </button>
            <button
              type="button"
              class="boton-pictograma boton-sin-contenedor-secundario boton-chico boton-accion-logo"
              aria-label="Eliminar logo secundario"
              @click="eliminarLogo2"
            >
              <span class="pictograma-eliminar" aria-hidden="true"></span>
            </button>
          </div>
        </div>

        <!-- Logotipo 3 (Editable, sin imagen predeterminada si está vacío) -->
        <div
          class="contenedor-logo-nav editando-logo"
          :class="{ 'logo-vacio': !store.logoTerceroUrl }"
        >
          <div v-if="!store.logoTerceroUrl" class="logo-placeholder-nav" @click="abrirModalLogo3">
            <span class="pictograma-agregar" aria-hidden="true"></span>
            <span>Logo 3</span>
          </div>
          <NuxtLink
            v-else
            to="/"
            rel="noopener noreferrer"
            class="nav-hiperviculo-logo pointer-events-none"
          >
            <img
              :src="store.resolverUrlImagen(store.logoTerceroUrl)"
              class="nav-logo nav-logo--chip"
              alt="Logo tercero"
              height="36"
            />
          </NuxtLink>
          <div class="nav-logo-acciones">
            <button
              type="button"
              class="boton-pictograma boton-sin-contenedor-secundario boton-chico boton-accion-logo"
              aria-label="Cambiar logo tercero"
              @click="abrirModalLogo3"
            >
              <span class="pictograma-editar" aria-hidden="true"></span>
            </button>
            <button
              type="button"
              class="boton-pictograma boton-sin-contenedor-secundario boton-chico boton-accion-logo"
              aria-label="Eliminar logo tercero"
              @click="eliminarLogo3"
            >
              <span class="pictograma-eliminar" aria-hidden="true"></span>
            </button>
          </div>
        </div>

        <!-- Logotipo 4 (Editable, sin imagen predeterminada si está vacío) -->
        <div
          class="contenedor-logo-nav editando-logo"
          :class="{ 'logo-vacio': !store.logoCuartoUrl }"
        >
          <div v-if="!store.logoCuartoUrl" class="logo-placeholder-nav" @click="abrirModalLogo4">
            <span class="pictograma-agregar" aria-hidden="true"></span>
            <span>Logo 4</span>
          </div>
          <NuxtLink
            v-else
            to="/"
            rel="noopener noreferrer"
            class="nav-hiperviculo-logo pointer-events-none"
          >
            <img
              :src="store.resolverUrlImagen(store.logoCuartoUrl)"
              class="nav-logo nav-logo--chip"
              alt="Logo cuarto"
              height="36"
            />
          </NuxtLink>
          <div class="nav-logo-acciones">
            <button
              type="button"
              class="boton-pictograma boton-sin-contenedor-secundario boton-chico boton-accion-logo"
              aria-label="Cambiar logo cuarto"
              @click="abrirModalLogo4"
            >
              <span class="pictograma-editar" aria-hidden="true"></span>
            </button>
            <button
              type="button"
              class="boton-pictograma boton-sin-contenedor-secundario boton-chico boton-accion-logo"
              aria-label="Eliminar logo cuarto"
              @click="eliminarLogo4"
            >
              <span class="pictograma-eliminar" aria-hidden="true"></span>
            </button>
          </div>
        </div>

        <!-- Nombre de la plataforma -->
        <div class="contenedor-titulo-plataforma-nav">
          <span
            contenteditable="true"
            class="input-nav-titulo-plataforma"
            data-placeholder="Nombre de la plataforma"
            @blur="store.nombrePlataforma = $event.target.textContent.trim()"
            @keydown.enter.prevent="$event.target.blur()"
          >
            {{ store.nombrePlataforma }}
          </span>
        </div>

        <!-- Color del header y del footer del constructor -->
        <div ref="popoverColorRef" class="contenedor-color-tema-nav">
          <button
            type="button"
            class="boton-color-tema-nav"
            :style="{ backgroundColor: store.colorTema || '#FFFFFF' }"
            aria-label="Elegir color del encabezado y pie de página"
            title="Elegir color del encabezado y pie de página"
            :aria-expanded="popoverColorAbierto"
            @click="alternarPopoverColor"
          ></button>

          <div v-if="popoverColorAbierto" class="popover-color-tema-nav">
            <LandingBuilderSelectorColorHex
              id="color-tema-pagina"
              v-model="store.colorTema"
              etiqueta="Color del encabezado y pie de página"
            />
          </div>
        </div>
      </div>

      <!-- Páginas publicadas del constructor: logos y nombre de la plataforma, en modo solo lectura -->
      <div
        v-else-if="esPaginaPublica || store.paginaInicioActiva"
        class="contenedor-identidades-nav constructor-identidades-nav"
      >
        <div v-if="store.identidadPublica.logoUrl" class="contenedor-logo-nav">
          <NuxtLink
            :to="store.identidadPublica.logoRedirectUrl || '/'"
            :target="store.identidadPublica.logoRedirectUrl ? '_blank' : undefined"
            rel="noopener noreferrer"
            class="nav-hiperviculo-logo"
          >
            <img
              :src="store.resolverUrlImagen(store.identidadPublica.logoUrl)"
              class="nav-logo nav-logo--chip"
              alt="Logo principal"
              height="36"
            />
          </NuxtLink>
        </div>

        <div v-if="store.identidadPublica.logoSecundarioUrl" class="contenedor-logo-nav">
          <NuxtLink
            :to="store.identidadPublica.logoSecundarioRedirectUrl || '/'"
            :target="store.identidadPublica.logoSecundarioRedirectUrl ? '_blank' : undefined"
            rel="noopener noreferrer"
            class="nav-hiperviculo-logo"
          >
            <img
              :src="store.resolverUrlImagen(store.identidadPublica.logoSecundarioUrl)"
              class="nav-logo nav-logo--chip"
              :alt="store.identidadPublica.nombrePlataforma || 'Logo secundario'"
              height="36"
            />
          </NuxtLink>
        </div>

        <div v-if="store.identidadPublica.logoTerceroUrl" class="contenedor-logo-nav">
          <NuxtLink
            :to="store.identidadPublica.logoTerceroRedirectUrl || '/'"
            :target="store.identidadPublica.logoTerceroRedirectUrl ? '_blank' : undefined"
            rel="noopener noreferrer"
            class="nav-hiperviculo-logo"
          >
            <img
              :src="store.resolverUrlImagen(store.identidadPublica.logoTerceroUrl)"
              class="nav-logo nav-logo--chip"
              alt="Logo tercero"
              height="36"
            />
          </NuxtLink>
        </div>

        <div v-if="store.identidadPublica.logoCuartoUrl" class="contenedor-logo-nav">
          <NuxtLink
            :to="store.identidadPublica.logoCuartoRedirectUrl || '/'"
            :target="store.identidadPublica.logoCuartoRedirectUrl ? '_blank' : undefined"
            rel="noopener noreferrer"
            class="nav-hiperviculo-logo"
          >
            <img
              :src="store.resolverUrlImagen(store.identidadPublica.logoCuartoUrl)"
              class="nav-logo nav-logo--chip"
              alt="Logo cuarto"
              height="36"
            />
          </NuxtLink>
        </div>

        <div
          v-if="store.identidadPublica.nombrePlataforma"
          class="contenedor-titulo-plataforma-nav"
        >
          <span class="nav-titulo-plataforma">{{ store.identidadPublica.nombrePlataforma }}</span>
        </div>
      </div>

      <!-- Modo Público (Resto de páginas): Diseño original de 2 logotipos de Sisdai -->
      <div v-else class="contenedor-identidades-nav">
        <a
          href="https://secihti.mx/"
          target="_blank"
          rel="noopener noreferrer"
          class="nav-hiperviculo-logo"
        >
          <img
            :src="`${config.app.baseURL}img/logo_secihiti.svg`"
            class="nav-logo color-invertir"
            alt="SECIHITI"
            height="36"
          />
        </a>

        <NuxtLink to="/" rel="noopener noreferrer" class="nav-hiperviculo-logo">
          <img
            :src="`${config.app.baseURL}img/logo_sigic.svg`"
            class="nav-logo color-invertir"
            alt="SIGIC"
            height="36"
          />
        </NuxtLink>
      </div>
    </template>

    <ul class="nav-menu">
      <li v-if="mostrarInicio">
        <NuxtLink class="nav-hipervinculo" to="/" exact-path>Inicio</NuxtLink>
      </li>
      <li v-if="mostrarCatalogo">
        <NuxtLink class="nav-hipervinculo" to="/catalogo">Catálogo</NuxtLink>
      </li>
      <li v-if="mostrarConsulta">
        <NuxtLink class="nav-hipervinculo" to="/consulta">Consulta</NuxtLink>
      </li>
      <li v-if="mostrarIaa && status === 'authenticated'">
        <NuxtLink class="nav-hipervinculo" to="/ia">Análisis Inteligencia Artificial</NuxtLink>
      </li>
      <li v-if="mostrarLevantamiento && status === 'authenticated'">
        <NuxtLink class="nav-hipervinculo" to="/levantamiento">Levantamiento</NuxtLink>
      </li>
      <li v-if="mostrarGeocontenidos && status === 'authenticated'">
        <NuxtLink class="nav-hipervinculo" to="/geocontenidos">Geocontenidos</NuxtLink>
      </li>   
      <li v-if="status === 'authenticated' && esAdmin">
        <NuxtLink class="nav-hipervinculo" to="/administracion">Administración</NuxtLink>
      </li>
      <li v-if="mostrarAcercaDe">
        <NuxtLink class="nav-hipervinculo" to="/acerca-de">Acerca de</NuxtLink>
      </li>
      <li v-if="esAdmin">
        <!-- Identidad de Gobierno de México (barra + pie de página): ajuste
        global del sitio completo, visible en cualquier módulo. -->
        <button
          type="button"
          class="boton-secundario boton-chico boton-alternar-identidad-gobmx"
          :aria-pressed="mostrarIdentidadGobMx"
          :title="
            mostrarIdentidadGobMx
              ? 'Ocultar la identidad de Gobierno de México en todo el sitio'
              : 'Mostrar la identidad de Gobierno de México en todo el sitio'
          "
          @click="alternarIdentidadGobMx"
        >
          <span
            :class="mostrarIdentidadGobMx ? 'pictograma-ojo-ver' : 'pictograma-ojo-ocultar'"
            aria-hidden="true"
          ></span>
          Identidad GobMX: {{ mostrarIdentidadGobMx ? 'Activada' : 'Desactivada' }}
        </button>
      </li>
      <li v-if="mostrarAuth">
        <NuxtLink v-if="status === 'authenticated'" class="nav-hipervinculo" to="/mi-cuenta">
          Mi cuenta
        </NuxtLink>

        <button
          v-else
          aria-label="Iniciar sesión"
          type="button"
          class="boton-secundario btn-inicio-sesion"
          @click="iniciarSesion"
        >
          Iniciar sesión
        </button>
      </li>
    </ul>

    <LandingBuilderModalCambiarLogo
      v-if="esConstructor"
      ref="modalCambiarLogo1"
      :redireccion-inicial="store.logoRedirectUrl"
      @seleccionar-archivo="seleccionarArchivoLogo1"
      @seleccionar-enlace="seleccionarEnlaceLogo1"
    />
    <LandingBuilderModalCambiarLogo
      v-if="esConstructor"
      ref="modalCambiarLogo2"
      :redireccion-inicial="store.logoSecundarioRedirectUrl"
      @seleccionar-archivo="seleccionarArchivoLogo2"
      @seleccionar-enlace="seleccionarEnlaceLogo2"
    />
    <LandingBuilderModalCambiarLogo
      v-if="esConstructor"
      ref="modalCambiarLogo3"
      :redireccion-inicial="store.logoTerceroRedirectUrl"
      @seleccionar-archivo="seleccionarArchivoLogo3"
      @seleccionar-enlace="seleccionarEnlaceLogo3"
    />
    <LandingBuilderModalCambiarLogo
      v-if="esConstructor"
      ref="modalCambiarLogo4"
      :redireccion-inicial="store.logoCuartoRedirectUrl"
      @seleccionar-archivo="seleccionarArchivoLogo4"
      @seleccionar-enlace="seleccionarEnlaceLogo4"
    />
  </SisdaiNavegacionPrincipal>
</template>

<style lang="scss">
// Con un colorTema elegido, el hover/focus de los enlaces del menú (Inicio,
// Catálogo, etc.) no debe usar el rosado fijo de sisdai-css: se ve pálido
// e ilegible contra el texto ya coloreado. Se sobrescribe con un tinte claro
// del mismo colorTema (ver estiloTemaHeader); si no hay colorTema, las
// variables --tema-pagina-cursor-* quedan sin definir y cae al valor
// original de sisdai-css. Solo aplica al nav principal (.navegacion-conahcyt),
// no al de Gobierno de México, que tiene su propio estilo.
.navegacion-conahcyt .nav-hipervinculo:hover,
.navegacion-conahcyt .nav-hipervinculo:focus {
  background-color: var(
    --tema-pagina-cursor-fondo,
    var(--navegacion-primaria-cursor-fondo)
  ) !important;
  color: var(--tema-pagina-cursor-color, var(--navegacion-primaria-color)) !important;
}

body[data-tema='oscuro'] {
  img.color-invertir {
    filter: grayscale(1) brightness(100);
  }
  .constructor-identidades-nav {
    // El color del texto ya sigue --navegacion-primaria-color (ver más abajo),
    // que en modo oscuro sisdai-css ya resuelve correctamente por sí solo; no
    // hace falta (ni conviene) forzarlo aparte, porque pisaría el colorTema
    // elegido en la página cuando ese color es claro.
    .contenedor-logo-nav.editando-logo:hover {
      background-color: rgba(255, 255, 255, 0.15);
    }
  }
}

.constructor-identidades-nav {
  display: inline-flex;
  align-items: center;
  gap: 12px;

  .contenedor-logo-nav {
    position: relative;
    display: inline-flex;
    align-items: center;

    &:not(:last-of-type)::after {
      content: '';
      display: inline-block;
      width: 1px;
      height: 20px;
      background-color: var(--color-conacyt-oro, #d1a153);
      margin-left: 12px;
      align-self: center;
    }
  }

  .nav-logo {
    height: 36px;
    max-height: 36px;
    width: auto;
    max-width: 140px;
    object-fit: contain;
    display: block;
  }

  .nav-logo--chip {
    box-sizing: border-box;
    padding: 3px 6px;
    border-radius: 6px;
    background: var(--color-neutro-0, #ffffff);
  }

  .editando-logo {
    border: 1px dashed transparent;
    border-radius: 4px;
    padding: 2px;
    transition:
      border-color 0.2s,
      background-color 0.2s;
  }

  .editando-logo:hover {
    border-color: var(--color-primario-2, rgb(105 28 50));
    background-color: rgba(0, 0, 0, 0.12);
  }

  .logo-vacio {
    border-color: var(--color-neutro-3, #bdbdbd);
  }

  .logo-placeholder-nav {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    border: 1px dashed var(--color-neutro-3, #bdbdbd);
    border-radius: 4px;
    height: 36px;
    padding: 0 8px;
    font-size: 0.75rem;
    font-weight: 600;
    color: var(--navegacion-primaria-color, var(--color-neutro-5, #757575));
    cursor: pointer;
    background: rgba(0, 0, 0, 0.02);
    transition:
      border-color 0.2s,
      background-color 0.2s;

    span {
      padding: 0 !important;
    }

    &:hover {
      border-color: var(--color-primario-2, rgb(105 28 50));
      background: rgba(0, 0, 0, 0.05);
    }
  }

  .nav-logo-acciones {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) scale(0.9);
    z-index: 10;
    opacity: 0;
    transition:
      opacity 0.2s,
      transform 0.2s;
    display: inline-flex;
    gap: 8px;
  }

  .contenedor-logo-nav:hover .nav-logo-acciones,
  .nav-logo-acciones:focus-within {
    opacity: 1;
    transform: translate(-50%, -50%) scale(1);
  }

  .boton-accion-logo {
    background-color: var(--color-primario-2, rgb(105 28 50)) !important;
    color: #ffffff !important;
    border-radius: 50% !important;
    width: 28px !important;
    height: 28px !important;
    display: inline-flex !important;
    align-items: center !important;
    justify-content: center !important;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2) !important;
    border: none !important;
    padding: 0 !important;
    cursor: pointer;

    span {
      padding: 0 !important;
      font-size: 14px !important;
    }
  }

  .contenedor-titulo-plataforma-nav {
    margin-left: 8px;
    display: inline-flex;
    align-items: center;
  }

  .nav-titulo-plataforma {
    font-size: 0.875rem;
    font-weight: 400;
    color: var(--navegacion-primaria-color, var(--texto-primario, #141414));
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    vertical-align: middle;
    line-height: 1.2;
    max-height: 2.4em;
    max-width: 320px;
    white-space: normal;
    overflow-wrap: break-word;
  }

  .input-nav-titulo-plataforma {
    font-size: 0.875rem;
    font-weight: 400;
    color: var(--navegacion-primaria-color, var(--texto-primario, #141414));
    border: 1px dashed var(--color-neutro-3, #bdbdbd);
    border-radius: 4px;
    padding: 2px 6px;
    outline: none;
    min-width: 180px;
    max-width: 320px;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    vertical-align: middle;
    line-height: 1.2;
    max-height: 2.4em;
    white-space: normal;
    overflow-wrap: break-word;

    &:empty::before {
      content: attr(data-placeholder);
      color: var(--navegacion-primaria-color, var(--color-neutro-4, #9e9e9e));
      font-style: italic;
      opacity: 0.75;
    }

    &:focus::before {
      content: '' !important;
    }

    &:hover {
      border-color: var(--color-primario-2, rgb(105 28 50));
    }

    &:focus {
      border: 1px solid var(--campo-enfoque-borde);
      box-shadow: 0 0 8px var(--campo-enfoque-sombra);
      background: var(--campo-enfoque-fondo);
    }
  }
}

.contenedor-color-tema-nav {
  position: relative;
  display: inline-flex;
  align-items: center;
  margin-left: 8px;
}

.boton-color-tema-nav {
  width: 24px;
  height: 24px;
  border: 2px solid var(--color-neutro-3, #bdbdbd);
  border-radius: 50%;
  cursor: pointer;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);

  &:hover,
  &:focus-visible {
    border-color: var(--color-primario-2, rgb(105 28 50));
  }
}

.popover-color-tema-nav {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  z-index: 10000;
  width: max-content;
  padding: 12px;
  border-radius: 8px;
  background: var(--color-neutro-6, #141414);
  color: var(--color-neutro-0, #ffffff);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
}
</style>
