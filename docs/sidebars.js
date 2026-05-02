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
/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  // Main documentation
  tutorialSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Prise en main',
      items: [
        'getting-started/introduction',
        'getting-started/installation',
        'getting-started/configuration',
      ],
    },
    'dev-onboarding',
    'contributing',
    {
      type: 'category',
      label: 'Documentation technique',
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

  // API Documentation
  apiSidebar: [
    'api/overview',
    {
      type: 'category',
      label: 'Authentification',
      items: [
        'api/auth/login',
        'api/auth/refresh-token',
      ],
    },
    {
      type: 'category',
      label: 'Utilisateurs',
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
      items: [
        'api/reports/list',
        'api/reports/create',
        'api/reports/update',
        'api/reports/delete',
      ],
    },
  ],

  
};

module.exports = sidebars;


