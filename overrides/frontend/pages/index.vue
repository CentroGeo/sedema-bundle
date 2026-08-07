<script setup>
import SelectedLayer from '~/utils/consulta/SelectedLayer';

definePageMeta({ auth: false, key: 'inicio' });

const config = useRuntimeConfig();

useHead({
  title: 'IDE SEDEMA',
  meta: [
    {
      name: 'description',
      content: 'Infraestructura de Datos Espaciales de la Secretaría del Medio Ambiente (SEDEMA).',
    },
  ],
});

const storeResources = useResourcesCatalogoStore();
const storeSelected = useSelectedResources2Store();
const params = {
  'filter{resource_type}': 'dataset',
  'filter{has_geometry}': 'true',
};
storeResources.getResourcesByPage('dataLayer', 1, 4, params);

const capasMasRecientes = computed(() => storeResources.resourcesByType('dataLayer') || []);
const isLoading = ref(true);
watch(
  capasMasRecientes,
  () => {
    isLoading.value = false;
  },
  { deep: true }
);
async function updateSelection(newPk, style) {
  storeSelected.reset();
  storeSelected.add(new SelectedLayer({ pk: newPk }), style, 'dataLayer');
  nextTick(async () => {
    await navigateTo('/consulta/capas');
  });
}

const features = [
  {
    icono: 'fa-solid fa-layer-group',
    titulo: 'Catálogo geoespacial',
    texto:
      'Accede a capas, mapas, documentos y recursos organizados por temática, cobertura y tipo de información.',
  },
  {
    icono: 'fa-solid fa-map-location-dot',
    titulo: 'Consulta interactiva',
    texto:
      'Explora el territorio mediante visores cartográficos con herramientas de navegación, filtros y análisis básico.',
  },
  {
    icono: 'fa-solid fa-database',
    titulo: 'Datos abiertos',
    texto:
      'Descarga información para su uso en procesos técnicos, investigación, planeación y toma de decisiones.',
  },
  {
    icono: 'fa-solid fa-chart-line',
    titulo: 'Indicadores e insumos',
    texto:
      'Consulta información estratégica para seguimiento de variables ambientales, territoriales y de gestión.',
  },
  {
    icono: 'fa-solid fa-exchange-alt',
    titulo: 'Interoperabilidad',
    texto:
      'Facilita el intercambio de información entre áreas técnicas, tomadores de decisión y ciudadanía interesada.',
  },
  {
    icono: 'fa-solid fa-sitemap',
    titulo: 'Gestión institucional',
    texto:
      'Fortalece la administración de recursos geográficos con una arquitectura ordenada, escalable y consistente.',
  },
];
</script>

<template>
  <main id="principal" class="sedema-landing">
    <section id="inicio" class="hero">
      <video class="hero__video" autoplay muted loop playsinline aria-hidden="true">
        <source :src="`${config.app.baseURL}img/sedema/ide_sedema_v3.mp4`" type="video/mp4" />
      </video>

      <div class="hero__overlay" />
      <div class="hero__glow" />

      <div class="hero-container hero__content">
        <span class="eyebrow">Plataforma institucional</span>
        <h1>Infraestructura de Datos Espaciales de la Secretaría del Medio Ambiente (SEDEMA)</h1>
        <p>
          Visualiza, consulta y comparte información geoespacial estratégica para el análisis,
          monitoreo y gestión ambiental de la Ciudad de México.
        </p>
        <div class="hero__actions">
          <NuxtLink to="/catalogo" class="btn btn--primary">Explorar catálogo</NuxtLink>
          <NuxtLink to="/consulta" class="btn btn--primary">Ir al geovisor principal</NuxtLink>
        </div>
      </div>
    </section>

    <section id="funcionalidades" class="features">
      <div class="features-container">
        <div class="section-heading">
          <span class="section-heading__kicker">¿Qué ofrece la plataforma?</span>
          <h2>Un punto de acceso unificado para información ambiental y territorial</h2>
          <p>
            La plataforma integra datos, mapas y servicios para consulta técnica, análisis espacial
            y difusión pública de información geográfica.
          </p>
        </div>

        <div class="cards-grid">
          <article v-for="f in features" :key="f.titulo" class="card">
            <div class="card__icon"><i :class="f.icono" /></div>
            <h3>{{ f.titulo }}</h3>
            <p>{{ f.texto }}</p>
          </article>
        </div>
      </div>
    </section>

    <section class="recursos recursos--center">
      <div class="recursos__header">
        <h2>Explora los recursos más recientes en la plataforma</h2>
        <p>
          Accede a información geoespacial actualizada, datasets y herramientas de análisis
          ambiental.
        </p>
      </div>

      <div v-if="isLoading" class="recursos__loader">
        <img :src="`${config.app.baseURL}img/loader.gif`" alt="...Cargando" height="120" />
      </div>
      <div v-else class="recursos__grid">
        <article
          v-for="capa in capasMasRecientes"
          :key="capa.pk"
          class="recurso-card recurso-card--vertical"
        >
          <div class="recurso-card__image">
            <img :src="capa.thumbnail_url" :alt="capa.title" />
          </div>
          <div class="recurso-card__content">
            <h3>{{ capa.title }}</h3>
            <!-- eslint-disable-next-line vue/no-v-html -->
            <div class="recurso-card__abstract" v-html="capa.abstract"></div>
            <NuxtLink
              :to="`/consulta/capas?capas=${capa.pk}`"
              class="btn-explorar"
              aria-label="Ver capa en visualizador"
              @click.prevent="updateSelection(capa.pk, capa.default_style)"
            >
              Ver capa en visualizador
            </NuxtLink>
          </div>
        </article>
      </div>
    </section>
  </main>
</template>

<style scoped>
.sedema-landing {
  font-family: 'Montserrat', sans-serif;
  color: #5f5f5f;
  background: #fff;
}
.sedema-landing :deep(a) {
  text-decoration: none;
  color: inherit;
}
.sedema-landing :deep(img) {
  display: block;
  max-width: 100%;
}

.hero-container,
.features-container {
  width: min(calc(100% - 48px), 1280px);
  margin-inline: auto;
}

/* Hero */
.hero {
  position: relative;
  min-height: 78vh;
  display: grid;
  place-items: center;
  overflow: hidden;
  background: #1b1b1b;
}
.hero__video {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.hero__overlay {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(
      180deg,
      rgba(20, 20, 20, 0.3) 0%,
      rgba(20, 20, 20, 0.45) 58%,
      rgba(20, 20, 20, 0.62) 100%
    ),
    linear-gradient(
      90deg,
      rgba(6, 70, 53, 0.18) 0%,
      rgba(6, 70, 53, 0.04) 45%,
      rgba(6, 70, 53, 0.14) 100%
    );
}
.hero__glow {
  position: absolute;
  inset: auto auto 8% 50%;
  width: 760px;
  height: 760px;
  transform: translateX(-50%);
  background: radial-gradient(circle, rgba(179, 142, 93, 0.18), transparent 58%);
  pointer-events: none;
}
.hero__content {
  position: relative;
  z-index: 2;
  text-align: center;
  color: #fff;
  padding: 110px 0;
  max-width: 1080px;
}
.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 8px 14px;
  margin-bottom: 20px;
  border: 1px solid rgba(255, 255, 255, 0.18);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(8px);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}
.hero h1 {
  margin: 0;
  font-size: clamp(2rem, 4vw, 4rem);
  line-height: 1.08;
  font-weight: 800;
  text-wrap: balance;
  text-shadow: 0 6px 24px rgba(0, 0, 0, 0.26);
  color: #fff;
}
.hero p {
  max-width: 820px;
  margin: 22px auto 0;
  font-size: clamp(1rem, 1.3vw, 1.18rem);
  line-height: 1.75;
  color: #fff;
}
.hero__actions {
  margin-top: 34px;
  display: flex;
  justify-content: center;
  gap: 14px;
  flex-wrap: wrap;
}
.btn {
  min-height: 48px;
  padding: 12px 22px;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 15px;
  transition:
    transform 0.2s ease,
    background 0.25s ease,
    border-color 0.25s ease,
    color 0.25s ease;
}
.btn:hover {
  transform: translateY(-2px);
}
.btn--primary {
  background: #064635;
  color: #fff !important;
  box-shadow: 0 12px 24px rgba(6, 70, 53, 0.25);
}
.btn--primary:hover {
  background: #519171;
}

/* Features */
.features {
  position: relative;
  padding: 92px 0 100px;
  background:
    radial-gradient(circle at top left, rgba(179, 142, 93, 0.1), transparent 26%),
    linear-gradient(180deg, #fff 0%, #fcfbf6 100%);
}
.section-heading {
  max-width: 860px;
  margin: 0 auto 42px;
  text-align: center;
}
.section-heading__kicker {
  display: inline-block;
  color: #064635;
  font-weight: 800;
  font-size: 12px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  margin-bottom: 12px;
}
.section-heading h2 {
  margin: 0;
  color: #4b4b4b;
  font-size: clamp(1.8rem, 3vw, 2.8rem);
  line-height: 1.15;
}
.section-heading p {
  margin: 18px auto 0;
  max-width: 720px;
  line-height: 1.8;
  font-size: 1rem;
}
.cards-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 22px;
}
.card {
  background: rgba(255, 255, 255, 0.92);
  border: 1px solid rgba(6, 70, 53, 0.08);
  border-radius: 24px;
  padding: 28px 24px 24px;
  box-shadow: 0 14px 40px rgba(62, 37, 45, 0.1);
  transition:
    transform 0.25s ease,
    box-shadow 0.25s ease,
    border-color 0.25s ease;
}
.card:hover {
  transform: translateY(-6px);
  box-shadow: 0 18px 48px rgba(62, 37, 45, 0.14);
  border-color: rgba(6, 70, 53, 0.18);
}
.card__icon {
  width: 58px;
  height: 58px;
  border-radius: 16px;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, rgba(6, 70, 53, 0.12), rgba(179, 142, 93, 0.14));
  color: #064635;
  font-size: 22px;
  margin-bottom: 18px;
}
.card h3 {
  margin: 0 0 10px;
  color: #064635;
  font-size: 1.12rem;
}
.card p {
  margin: 0;
  line-height: 1.75;
  font-size: 0.96rem;
}

/* Recursos */
.recursos {
  padding: 0 0 80px;
}
.recursos--center .recursos__header {
  text-align: center;
  margin: 0 auto 50px auto;
  padding: 0 24px;
}
.recursos--center .recursos__header h2 {
  font-size: 30px;
  color: #4b4b4b;
  margin: 0 0 14px;
}
.recursos--center .recursos__header p {
  max-width: 600px;
  margin: 0 auto;
  line-height: 1.7;
}
.recursos__grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 30px;
  max-width: 1200px;
  margin: 0 auto 40px;
  padding: 0 24px;
}
.recursos__loader {
  display: flex;
  justify-content: center;
  padding: 40px 0;
}
.recurso-card__abstract {
  font-size: 14px;
  color: #666;
  margin-bottom: 20px;
  flex: 1;
  display: -webkit-box;
  -webkit-line-clamp: 4;
  line-clamp: 4;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.recurso-card--vertical {
  background: #fff;
  border-radius: 18px;
  overflow: hidden;
  box-shadow: 0 10px 28px rgba(0, 0, 0, 0.1);
  transition: 0.3s;
  display: flex;
  flex-direction: column;
}
.recurso-card--vertical:hover {
  transform: translateY(-4px);
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.15);
}
.recurso-card--vertical .recurso-card__image img {
  width: 100%;
  height: 320px;
  object-fit: cover;
}
.recurso-card__content {
  padding: 20px;
  display: flex;
  flex-direction: column;
  flex: 1;
}
.recurso-card__content h3 {
  font-size: 18px;
  color: #333;
  margin: 0 0 10px;
}
.recurso-card__content p {
  font-size: 14px;
  color: #666;
  margin-bottom: 20px;
  flex: 1;
}
.btn-explorar {
  align-self: flex-start;
  text-decoration: none;
  font-size: 14px;
  font-weight: 600;
  color: #064635;
  border: 1px solid #064635;
  padding: 8px 16px;
  border-radius: 6px;
  transition: 0.2s;
}
.btn-explorar:hover {
  background: #064635;
  color: #fff !important;
}

/* Responsive */
@media (max-width: 1150px) {
  .cards-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
@media (max-width: 1100px) {
  .recursos__grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
@media (max-width: 900px) {
  .hero {
    min-height: 72vh;
  }
  .hero__content {
    padding: 84px 0;
  }
}
@media (max-width: 640px) {
  .hero-container,
  .features-container {
    width: min(calc(100% - 28px), 1280px);
  }
  .hero h1 {
    font-size: clamp(1.7rem, 8vw, 2.6rem);
  }
  .hero p {
    font-size: 0.98rem;
    line-height: 1.7;
  }
  .hero__actions {
    flex-direction: column;
    align-items: stretch;
  }
  .btn {
    width: 100%;
  }
  .cards-grid {
    grid-template-columns: 1fr;
  }
  .card {
    padding: 24px 20px;
    border-radius: 20px;
  }
}
@media (max-width: 600px) {
  .recursos__grid {
    grid-template-columns: 1fr;
  }
}
</style>
