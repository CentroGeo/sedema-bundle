<script setup>
const config = useRuntimeConfig();
</script>

<template>
  <header class="topbar" aria-label="Barra superior institucional">
    <div class="topbar-container topbar__inner">
      <a
        href="https://www.cdmx.gob.mx/"
        target="_blank"
        rel="noopener noreferrer"
        class="topbar__brand"
        aria-label="Inicio CDMX"
      >
        <img
          :src="`${config.app.baseURL}img/sedema/logo_cdmx_sin_dependencia.svg`"
          alt="Gobierno de la Ciudad de México"
        />
      </a>

      <nav class="topbar__links" aria-label="Enlaces institucionales">
        <a href="https://www.cdmx.gob.mx/" target="_blank" rel="noopener noreferrer">CDMX</a>
        <a href="https://www.sectei.cdmx.gob.mx/" target="_blank" rel="noopener noreferrer">
          SECTEI
        </a>
        <a href="https://www.sedema.cdmx.gob.mx/" target="_blank" rel="noopener noreferrer">
          SEDEMA
        </a>
      </nav>
    </div>
  </header>
</template>

<style scoped>
.topbar {
  background: #fff;
  height: 40px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
  position: relative;
  z-index: 20;
}
.topbar-container {
  width: min(calc(100% - 48px), 1280px);
  margin-inline: auto;
}
.topbar__inner {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}
.topbar__brand img {
  height: 32px;
  width: auto;
  display: block;
}
.topbar__links {
  display: flex;
  align-items: center;
  gap: 34px;
}
.topbar__links a {
  color: #6b6b6b;
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.02em;
  position: relative;
  transition: color 0.25s ease;
  text-decoration: none;
}
.topbar__links a::after {
  content: '';
  position: absolute;
  left: 0;
  bottom: -6px;
  width: 100%;
  height: 1px;
  background: rgba(107, 107, 107, 0.4);
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.25s ease;
}
.topbar__links a:hover {
  color: #064635;
}
.topbar__links a:hover::after {
  transform: scaleX(1);
}

@media (max-width: 900px) {
  .topbar {
    height: auto;
    padding: 8px 0;
  }
  .topbar__inner {
    min-height: 50px;
    flex-wrap: wrap;
  }
  .topbar__brand img {
    height: 34px;
  }
  .topbar__links {
    gap: 18px;
    margin-left: auto;
  }
}

@media (max-width: 640px) {
  .topbar-container {
    width: min(calc(100% - 28px), 1280px);
  }
  .topbar__inner {
    justify-content: center;
  }
  .topbar__links {
    width: 100%;
    justify-content: center;
    gap: 16px;
  }
  .topbar__links a {
    font-size: 13px;
  }
}
</style>
