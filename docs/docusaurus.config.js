// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Novaville',
  tagline: 'Documentation technique et guide pour reprise par une équipe de développement',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://michael16b.github.io',
  // GitHub Pages is served under https://<user>.github.io/<project>/
  baseUrl: '/Novaville/',

  customFields: {
    appLogoUrl: 'https://raw.githubusercontent.com/Michael16b/Novaville/main/frontend/assets/images/logo.png',
    releaseBaseUrl: 'https://github.com/Michael16b/Novaville/releases/latest/download',
    releasePageUrl: 'https://github.com/Michael16b/Novaville/releases/latest',
    authors: 'BESILY Michaël, CRONIER Romain, JAN Charlène',
  },

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'Michael16b', // Usually your GitHub org/user name.
  projectName: 'Novaville', // Usually your repo name.

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  // Multi-language setup: French (default) and English
  i18n: {
    defaultLocale: 'fr',
    locales: ['fr', 'en'],
    localeConfigs: {
      fr: {
        label: 'Français',
        direction: 'ltr',
        htmlLang: 'fr-FR',
      },
      en: {
        label: 'English',
        direction: 'ltr',
        htmlLang: 'en-US',
      },
    },
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/Michael16b/Novaville/tree/main/docs/',
        },
        blog: {
          showReadingTime: true,
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/Michael16b/Novaville/tree/main/docs/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  plugins: [
    [
      'docusaurus-plugin-papersaurus',
      {
        addDownloadButton: true,
        downloadButtonText: process.env.DOCUSAURUS_CURRENT_LOCALE === 'en' ? 'Download as PDF' : 'Télécharger en PDF',
        autoBuildPdfs: true,
        keepDebugHtmls: true,

        // ── Page de couverture professionnelle ──────────────────────────
        getPdfCoverPage: (siteConfig, _pluginConfig, pageTitle, version) => {
          const authors = siteConfig.customFields?.authors || '';
          const isEn = process.env.DOCUSAURUS_CURRENT_LOCALE === 'en';
          
          const today = new Date().toLocaleDateString(isEn ? 'en-US' : 'fr-FR', {
            year: 'numeric', month: 'long', day: 'numeric',
          });
          const displayVersion = (version === 'Next' || !version) ? '3.0' : version;
          const showTitle = pageTitle && 
                            pageTitle.toLowerCase() !== 'novaville' && 
                            !pageTitle.toLowerCase().includes('reprise par') && 
                            !pageTitle.toLowerCase().includes('handover');
          
          const subtitle = isEn 
            ? 'Technical documentation and developer handover guide' 
            : 'Documentation technique et guide pour reprise par une équipe de développement';
          const generatedText = isEn ? 'Generated on' : 'Généré le';

          return `
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"></head>
            <body style="margin:0;padding:0;font-family:'Segoe UI',Arial,Helvetica,sans-serif;">
              <div style="
                height:100vh;
                display:flex;
                flex-direction:column;
                justify-content:center;
                align-items:center;
                text-align:center;
                background:linear-gradient(135deg, #0e291e 0%, #1c4d39 50%, #081a13 100%);
                color:#fff;
                padding:3cm;
                box-sizing:border-box;
              ">
                <!-- Logo -->
                <img src="${siteConfig.customFields?.appLogoUrl || ''}"
                     alt="Novaville"
                     style="width:120px;height:120px;border-radius:24px;
                            margin-bottom:2cm;
                            border:3px solid #F9C846;
                            box-shadow:0 8px 32px rgba(0,0,0,0.4);" />

                <!-- Titre du projet -->
                <h1 style="
                  font-size:42px;font-weight:700;margin:0 0 0.3cm 0;
                  letter-spacing:1px;
                  background:linear-gradient(135deg,#ffffff,#f1f5f9);
                  -webkit-background-clip:text;-webkit-text-fill-color:transparent;
                ">NOVAVILLE</h1>

                <!-- Sous-titre -->
                <p style="
                  font-size:18px;color:#cbd5e1;margin:0 0 1.5cm 0;
                  max-width:16cm;line-height:1.5;
                ">${subtitle}</p>

                <!-- Barre décorative aux couleurs de l'application (Vert et Or) -->
                <div style="width:6cm;height:3px;background:linear-gradient(90deg,#F9C846,#2e8555);
                            border-radius:2px;margin-bottom:1.5cm;"></div>

                <!-- Titre de la section PDF -->
                ${showTitle ? `
                <h2 style="font-size:22px;font-weight:400;margin:0 0 0.8cm 0;color:#cbd5e1;">
                  ${pageTitle}
                </h2>
                ` : ''}

                <p style="font-size:13px;color:#a3a3a3;margin:0 0 0.5cm 0;">Version ${displayVersion}</p>

                <!-- Auteurs -->
                <p style="font-size:12px;color:#a3a3a3;margin:0 0 0.3cm 0;">
                  ${authors}
                </p>

                <!-- Date -->
                <p style="font-size:12px;color:#737373;margin:0;">
                  ${generatedText} ${today}
                </p>
              </div>
            </body>
            </html>`;
        },

        // ── En-tête de page ────────────────────────────────────────────
        getPdfPageHeader: (siteConfig, _pluginConfig, pageTitle) => {
          const isMain = pageTitle.toLowerCase() === 'novaville';
          const isEn = process.env.DOCUSAURUS_CURRENT_LOCALE === 'en';
          const displayTitle = isMain 
            ? (isEn ? 'Technical Documentation' : 'Documentation technique') 
            : pageTitle;
          return `
            <div style="
              height:1.2cm;
              display:flex;
              justify-content:center;
              align-items:center;
              margin:0 1.5cm;
              padding-top:0.3cm;
              border-top:2px solid #2e8555;
              font-family:'Segoe UI',Arial,Helvetica,sans-serif;
              font-size:8px;
              color:#64748b;
              font-weight:600;
            ">
              <span>${displayTitle}</span>
            </div>`;
        },

        // ── Pied de page ───────────────────────────────────────────────
        getPdfPageFooter: (_siteConfig, _pluginConfig, pageTitle) => {
          const isMain = pageTitle.toLowerCase() === 'novaville';
          return `
            <div style="
              height:1cm;
              display:flex;
              align-items:center;
              margin:0 1.5cm;
              border-top:1px solid #e2e8f0;
              font-family:'Segoe UI',Arial,Helvetica,sans-serif;
              font-size:8px;
              color:#94a3b8;
              width:100%;
            ">
              <span style="flex:1;">© Novaville</span>
              <span style="flex:1;text-align:center;color:#cbd5e1;">${isMain ? '' : pageTitle}</span>
              <span style="flex:1;text-align:right;">
                Page <span class='pageNumber'></span> / <span class='totalPages'></span>
              </span>
            </div>`;
        },

        // Noms personnalisés pour les fichiers PDF générés
        getPdfFileName: (siteConfig, pluginConfig, pageTitle, pageId, parentTitles, parentIds, version, versionPath) => {
          const isEn = versionPath === 'en' || process.env.DOCUSAURUS_CURRENT_LOCALE === 'en';
          if (pageId && pageId.toLowerCase() === 'novaville') {
            return isEn ? 'Novaville Technical Documentation' : 'Documentation technique de Novaville';
          }
          return (parentIds.length ? parentIds.join('-') + '-' : '') + pageId;
        },

        // Marges zéro pour la couverture (le layout est intégralement dans le HTML)
        coverMargins: { top: '0', right: '0', bottom: '0', left: '0' },
        // Marges des pages de contenu
        margins: { top: '2.5cm', right: '2cm', bottom: '2.3cm', left: '2cm' },
        // Timeout Puppeteer plus large pour les machines lentes
        puppeteerTimeout: 60000,

        // Matcher "Page X / Y" SANS groupe capturant pour que split() consomme le séparateur
        footerParser: /Page \d+ \/ \d+/g,
      },
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'img/docusaurus-social-card.jpg',
      navbar: {
        title: 'Novaville',
        logo: {
          alt: 'Novaville Logo',
          src: 'https://raw.githubusercontent.com/Michael16b/Novaville/main/frontend/assets/images/logo.png',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Documentation',
          },
          {
            type: 'docSidebar',
            sidebarId: 'apiSidebar',
            position: 'left',
            label: 'API',
          },
          {
            type: 'docSidebar',
            sidebarId: 'onboardingSidebar',
            position: 'left',
            label: "Onboarding Devs",
          },
          { to: '/blog', label: 'Notes de version', position: 'left' },
          {
            type: 'localeDropdown',
            position: 'right',
          },
          {
            label: 'PDF Global',
            to: (process.env.DOCUSAURUS_CURRENT_LOCALE === 'en')
              ? 'pathname:///pdfs/docs/novaville-technical-documentation.pdf'
              : 'pathname:///pdfs/docs/documentation-technique-de-novaville.pdf',
            position: 'right',
          },
          {
            href: 'https://github.com/Michael16b/Novaville',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Documentation',
            items: [
              {
                label: 'Guide de démarrage',
                to: '/docs/intro',
              },
              {
                label: 'Onboarding Devs',
                to: '/docs/dev-onboarding',
              },
              {
                label: 'Documentation API',
                to: '/docs/api/',
              },
            ],
          },
          {
            title: 'Ressources',
            items: [
              {
                label: 'Notes de version',
                to: '/blog',
              },
              {
                label: 'Architecture',
                to: '/docs/technical/architecture',
              },
            ],
          },
          {
            title: 'Plus',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/Michael16b/Novaville',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Novaville. Auteurs : BESILY Michaël, CRONIER Romain, JAN Charlène. Documentation construite avec Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['python', 'dart', 'bash', 'json', 'yaml'],
      },
    }),
};

module.exports = config;
