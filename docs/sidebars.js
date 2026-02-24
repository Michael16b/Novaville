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
      label: 'Getting Started',
      items: [
        'getting-started/introduction',
        'getting-started/installation',
        'getting-started/configuration',
      ],
    },
    {
      type: 'category',
      label: 'Technical Documentation',
      items: [
        'technical/architecture',
        'technical/backend',
      ],
    },
  ],

  // API Documentation
  apiSidebar: [
    'api/overview',
    {
      type: 'category',
      label: 'Authentication',
      items: [
        'api/auth/login',
        'api/auth/refresh-token',
      ],
    },
  ],

  // User Manual
  userManualSidebar: [
    'user-manual/intro',
    {
      type: 'category',
      label: 'First Steps',
      items: [
        'user-manual/first-steps/login',
      ],
    },
    {
      type: 'category',
      label: 'Reports',
      items: [
        'user-manual/reports/create',
      ],
    },
  ],
};

module.exports = sidebars;

