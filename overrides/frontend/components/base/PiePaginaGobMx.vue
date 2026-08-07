<script setup>
const config = useRuntimeConfig();
const anio = new Date().getFullYear();
</script>

<template>
  <footer class="site-footer">
    <div class="site-footer__topline" />
    <div class="footer-container footer-grid">
      <section class="footer-block footer-block--brand">
        <img
          :src="`${config.app.baseURL}img/sedema/logo_cdmx_sin_dependencia.svg`"
          alt="Gobierno de la Ciudad de México"
          class="footer-logo"
        />

        <h3>Atención ciudadana</h3>
        <p>
          <strong>Dirección:</strong> Plaza de la Constitución 1, piso tercero<br />
          Colonia Centro, Alcaldía Cuauhtémoc C.P. 06000, Ciudad de México
        </p>
        <p><strong>Teléfonos:</strong><br />55 5345 8187, 55 5345 8188</p>
        <p><strong>Correo electrónico:</strong><br />atencionciudadana@sedema.cdmx.gob.mx</p>
        <p><strong>Horario:</strong><br />Martes 10:00 a 13:00 hrs.</p>

        <div class="socials" aria-label="Redes sociales">
          <a
            href="https://www.facebook.com/SedemaCDMX/"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Facebook"
          >
            <i class="fab fa-facebook-f" />
          </a>
          <a
            href="https://x.com/SEDEMA_CDMX"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="X"
          >
            <i class="fab fa-x-twitter" />
          </a>
          <a
            href="https://www.youtube.com/@sedema-ciudaddemexico8374"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="YouTube"
          >
            <i class="fab fa-youtube" />
          </a>
          <a
            href="https://www.instagram.com/sedema_cdmx/"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Instagram"
          >
            <i class="fab fa-instagram" />
          </a>
        </div>
      </section>

      <nav class="footer-block" aria-label="Navegación del pie de página">
        <h3>Navegación</h3>
        <ul>
          <li><NuxtLink to="/">Inicio</NuxtLink></li>
          <li>
            <a
              href="https://www.sedema.cdmx.gob.mx/secretaria"
              target="_blank"
              rel="noopener noreferrer"
            >
              Secretaría
            </a>
          </li>
          <li>
            <a
              href="https://www.sedema.cdmx.gob.mx/servicios"
              target="_blank"
              rel="noopener
              noreferrer"
            >
              Servicios
            </a>
          </li>
          <li>
            <a
              href="https://www.sedema.cdmx.gob.mx/programas"
              target="_blank"
              rel="noopener
              noreferrer"
            >
              Programas
            </a>
          </li>
          <li>
            <a
              href="https://www.sedema.cdmx.gob.mx/convocatorias"
              target="_blank"
              rel="noopener noreferrer"
            >
              Convocatorias
            </a>
          </li>
          <li>
            <a href="https://www.sedema.cdmx.gob.mx/" target="_blank" rel="noopener noreferrer">
              Ver más
            </a>
          </li>
        </ul>
      </nav>

      <nav class="footer-block" aria-label="Sitios relacionados">
        <h3>Sitios relacionados</h3>
        <ul>
          <li>
            <a
              href="https://www.sedema.cdmx.gob.mx/atencion-ciudadana"
              target="_blank"
              rel="noopener noreferrer"
            >
              Atención Ciudadana
            </a>
          </li>
          <li>
            <a
              href="https://www.sedema.cdmx.gob.mx/agencia-de-atencion-animal"
              target="_blank"
              rel="noopener noreferrer"
            >
              Agencia de Atención Animal CDMX
            </a>
          </li>
          <li>
            <a href="http://www.aire.cdmx.gob.mx/" target="_blank" rel="noopener noreferrer">
              Calidad del Aire
            </a>
          </li>
          <li>
            <a
              href="https://www.chapultepec.cdmx.gob.mx/"
              target="_blank"
              rel="noopener noreferrer"
            >
              Bosque de Chapultepec
            </a>
          </li>
          <li>
            <a
              href="https://www.sedema.cdmx.gob.mx/dependencias/museo-de-historia-natural"
              target="_blank"
              rel="noopener noreferrer"
            >
              Museo de Historia Natural
            </a>
          </li>
          <li>
            <a
              href="https://www.sedema.cdmx.gob.mx/programas/programa/sitios-autorizados-para-manejo-de-residuos"
              target="_blank"
              rel="noopener noreferrer"
            >
              Sitios autorizados manejo de residuos
            </a>
          </li>
        </ul>
      </nav>

      <section class="footer-block footer-block--banners" aria-label="Banners relacionados">
        <a
          href="https://www.cdmx.gob.mx/"
          target="_blank"
          rel="noopener noreferrer"
          class="footer-banner"
        >
          <img
            :src="`${config.app.baseURL}img/sedema/programa_cdmx_2019_2024.png`"
            alt="Programa de Gobierno de la Ciudad de México 2019-2024"
          />
        </a>
        <a
          href="https://datos.cdmx.gob.mx/"
          target="_blank"
          rel="noopener noreferrer"
          class="footer-banner"
        >
          <img
            :src="`${config.app.baseURL}img/sedema/portal_de_datos_de_la_cdmx.png`"
            alt="Portal de datos de la Ciudad de México"
          />
        </a>
        <a
          href="https://tianguisdigital.cdmx.gob.mx/"
          target="_blank"
          rel="noopener noreferrer"
          class="footer-banner"
        >
          <img
            :src="`${config.app.baseURL}img/sedema/tianguis_digital.png`"
            alt="Tianguis Digital"
          />
        </a>
      </section>
    </div>

    <div class="subfooter">
      <div class="subfooter__container">
        <img
          :src="`${config.app.baseURL}img/sedema/logo_centrogeo_wide.png`"
          alt="CentroGeo"
          class="subfooter__logo"
        />
        <p class="subfooter__text">
          Desarrollado por: Centro de Investigación en Ciencias de Información Geoespacial, A.C.©
          {{ anio }}
        </p>
      </div>
    </div>
  </footer>
</template>

<style scoped>
.site-footer {
  background: #f4f1e8;
  color: #666;
  position: relative;
  overflow: hidden;
  font-family: 'Montserrat', sans-serif;
}
.site-footer__topline {
  height: 7px;
  background: linear-gradient(90deg, #a65ac5 0%, #8a43a8 100%);
}
.footer-container {
  width: min(calc(100% - 48px), 1280px);
  margin-inline: auto;
}
.footer-grid {
  display: grid;
  grid-template-columns: 1.45fr 0.95fr 1fr 250px;
  gap: 54px;
  padding: 58px 0 56px;
}
.footer-logo {
  width: 440px;
  max-width: 100%;
  margin-bottom: 26px;
  display: block;
}
.footer-block h3 {
  margin: 0 0 18px;
  color: #064635;
  font-size: 1.02rem;
}
.footer-block p,
.footer-block li,
.footer-block a {
  font-size: 1rem;
  line-height: 1.55;
  color: #666;
  text-decoration: none;
}
.footer-block ul {
  margin: 0;
  padding: 0;
  list-style: none;
}
.footer-block li {
  margin-bottom: 12px;
  padding-left: 18px;
  position: relative;
}
.footer-block li::before {
  content: '○';
  position: absolute;
  left: 0;
  top: 0;
  color: #8f8f8f;
  font-size: 12px;
}
.footer-block a:hover {
  color: #064635;
}
.footer-block--brand p {
  margin: 0 0 16px;
}
.socials {
  display: flex;
  gap: 10px;
  margin-top: 18px;
}
.socials a {
  width: 56px;
  height: 56px;
  display: grid;
  place-items: center;
  background: #064635;
  color: #fff;
  font-size: 1.45rem;
  transition:
    transform 0.2s ease,
    background 0.25s ease;
}
.socials a:hover {
  transform: translateY(-3px);
  background: #519171;
}
.footer-block--banners {
  display: flex;
  flex-direction: column;
  gap: 18px;
}
.footer-banner {
  display: block;
  overflow: hidden;
  transition:
    transform 0.2s ease,
    box-shadow 0.25s ease;
}
.footer-banner:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.14);
}
.footer-banner img {
  width: 100%;
  height: auto;
  display: block;
}

.subfooter {
  background: #222;
  padding: 18px 40px;
}
.subfooter__container {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}
.subfooter__logo {
  height: 45px;
  object-fit: contain;
  display: block;
}
.subfooter__text {
  color: #bfbfbf;
  font-size: 14px;
  font-weight: 300;
  text-align: right;
  margin: 0;
}

@media (max-width: 1150px) {
  .footer-grid {
    grid-template-columns: 1.25fr 1fr 1fr;
  }
  .footer-block--banners {
    grid-column: 1 / -1;
    flex-direction: row;
    align-items: flex-start;
  }
  .footer-banner {
    width: min(240px, 100%);
  }
}

@media (max-width: 900px) {
  .footer-grid {
    grid-template-columns: 1fr;
    gap: 36px;
  }
  .subfooter__container {
    flex-direction: column;
    text-align: center;
  }
  .subfooter__text {
    text-align: center;
  }
}

@media (max-width: 640px) {
  .footer-container {
    width: min(calc(100% - 28px), 1280px);
  }
  .footer-block p,
  .footer-block li,
  .footer-block a {
    font-size: 0.96rem;
  }
  .socials a {
    width: 50px;
    height: 50px;
    font-size: 1.3rem;
  }
  .footer-block--banners {
    flex-direction: column;
  }
}
</style>
