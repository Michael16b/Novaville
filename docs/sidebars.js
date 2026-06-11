/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  // Main documentation
  tutorialSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Prise en main',
      link: { type: 'doc', id: 'getting-started/index' },
      items: [
        'getting-started/introduction',
        'getting-started/installation',
        'getting-started/configuration',
      ],
    },
    'contributing',
    {
      type: 'category',
      label: 'Documentation technique',
      link: { type: 'doc', id: 'technical/index' },
      items: [
        'technical/architecture',
        'technical/backend',
        'technical/local-deployment',
        'technical/internal-guides',
        'technical/azure-deployment',
        'technical/docs-deployment',
      ],
    },
  ],

  // API documentation
  apiSidebar: [
    {
      type: 'category',
      label: 'Documentation API',
      link: { type: 'doc', id: 'api/index' },
      items: [
        {
          type: 'category',
          label: 'Authentification',
          link: { type: 'doc', id: 'api/auth/index' },
          items: [
            'api/auth/login',
            'api/auth/refresh-token',
          ],
        },
        {
          type: 'category',
          label: 'Utilisateurs',
          link: { type: 'doc', id: 'api/users/index' },
          items: [
            'api/users/list',
            'api/users/create',
            'api/users/update',
            'api/users/delete',
          ],
        },
        {
          type: 'category',
          label: 'Événements',
          link: { type: 'doc', id: 'api/events/index' },
          items: [
            'api/events/list',
            'api/events/create',
            'api/events/update',
            'api/events/delete',
          ],
        },
        {
          type: 'category',
          label: 'Rapports',
          link: { type: 'doc', id: 'api/reports/index' },
          items: [
            'api/reports/list',
            'api/reports/create',
            'api/reports/update',
            'api/reports/delete',
          ],
        },
      ],
    },
  ],

  // Onboarding
  onboardingSidebar: [
    'dev-onboarding',
  ],
};

module.exports = sidebars;
