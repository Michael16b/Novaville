// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Novaville',
  tagline: 'Documentation technique et API',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://michael16b.github.io',
  // GitHub Pages is served under https://<user>.github.io/<project>/
  baseUrl: '/Novaville/',

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

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'img/docusaurus-social-card.jpg',
      navbar: {
        title: 'Novaville',
        logo: {
          alt: 'Novaville Logo',
          src: 'img/logo.svg',
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
            sidebarId: 'userManualSidebar',
            position: 'left',
            label: 'Manuel Utilisateur',
          },
          {to: '/blog', label: 'Notes de version', position: 'left'},
          {
            type: 'localeDropdown',
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
                label: 'Manuel Utilisateur',
                to: '/docs/user-manual/intro',
              },
              {
                label: 'Documentation API',
                to: '/docs/api/overview',
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
        copyright: `Copyright © ${new Date().getFullYear()} Novaville. Documentation construite avec Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['python', 'dart', 'bash', 'json', 'yaml'],
      },
    }),
};

module.exports = config;
