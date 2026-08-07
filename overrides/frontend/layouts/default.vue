<script setup>
import TopbarGobMx from '~/components/base/TopbarGobMx.vue';
import MenuAccesibilidad from '~/components/base/MenuAccesibilidad.vue';
import PiePaginaGobMx from '~/components/base/PiePaginaGobMx.vue';
import MainNavegacion from '~/components/base/MainNavegacion.vue';
import { useAccesibilidadStore } from '~/stores/accesibilidad';

const accesibilidadStore = useAccesibilidadStore();
const route = useRoute();
const currentPath = computed(() => route.fullPath);

useHead(() => ({
  meta: [
    { property: 'og:url', content: currentPath.value, key: 'og-url' },
    { name: 'twitter:url', content: currentPath.value, key: 'twitter-url' },
  ],
  link: [
    { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
    { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
    {
      rel: 'stylesheet',
      href: 'https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700;800&display=swap',
    },
    {
      rel: 'stylesheet',
      href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css',
      crossorigin: 'anonymous',
      referrerpolicy: 'no-referrer',
    },
  ],
}));
</script>

<template>
  <div>
    <a href="#principal" class="ir-contenido-principal"> Ir a contenido principal </a>
    <TopbarGobMx />

    <MainNavegacion />

    <div class="contenido">
      <slot />
    </div>

    <client-only>
      <MenuAccesibilidad :objeto-store="accesibilidadStore" />
    </client-only>

    <PiePaginaGobMx />
  </div>
</template>
