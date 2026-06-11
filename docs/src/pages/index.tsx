import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';

import styles from './index.module.css';

type CustomFields = {
  appLogoUrl: string;
  releaseBaseUrl: string;
  releasePageUrl: string;
};

type DownloadItem = {
  key: string;
  title: string;
  description: string;
  links: Array<{ href: string; label: string }>;
};

function getDownloads(customFields: CustomFields, locale: string | undefined): DownloadItem[] {
  const localeSafe = typeof locale === 'string' ? locale : undefined;
  const isEnglish = typeof localeSafe === 'string' ? localeSafe.startsWith('en') : false;
  const {releaseBaseUrl, releasePageUrl} = customFields;

  return isEnglish
    ? [
        {
          key: 'android',
          title: 'Android',
          description: 'Direct installation on your device (APK) or recommended package for the Play Store (AAB).',
          links: [
            { href: `${releaseBaseUrl}/novaville-android.apk`, label: 'Download APK' },
            { href: `${releaseBaseUrl}/novaville-android.aab`, label: 'Download AAB' },
          ]
        },
        {
          key: 'web-pwa',
          title: 'Web / PWA',
          description: 'Web build packed for installable PWA use or static hosting.',
          links: [{ href: `${releaseBaseUrl}/novaville-web-pwa.zip`, label: 'Download web build' }],
        },
        {
          key: 'windows',
          title: 'Windows',
          description: 'Windows Installer (.exe).',
          links: [{ href: `${releaseBaseUrl}/novaville-windows.exe`, label: 'Download Windows' }],
        },
        {
          key: 'linux',
          title: 'Linux',
          description: 'Desktop application for Linux.',
          links: [{ href: `${releaseBaseUrl}/novaville-linux.zip`, label: 'Download Linux' }],
        },
        {
          key: 'macos-ios',
          title: 'Apple (macOS / iOS)',
          description: 'Application for Apple devices (Mac, iPhone, iPad).',
          links: [{ href: releasePageUrl, label: 'View release' }],
        },
      ]
    : [
        {
          key: 'android',
          title: 'Android',
          description: 'Installation directe sur téléphone (APK) ou format recommandé pour Google Play (AAB).',
          links: [
            { href: `${releaseBaseUrl}/novaville-android.apk`, label: 'Télécharger APK' },
            { href: `${releaseBaseUrl}/novaville-android.aab`, label: 'Télécharger AAB' },
          ]
        },
        {
          key: 'web-pwa',
          title: 'Web / PWA',
          description: 'Version web packagée pour installation ou hébergement statique.',
          links: [{ href: `${releaseBaseUrl}/novaville-web-pwa.zip`, label: 'Télécharger le build web' }],
        },
        {
          key: 'windows',
          title: 'Windows',
          description: 'Installateur Windows (.exe).',
          links: [{ href: `${releaseBaseUrl}/novaville-windows.exe`, label: 'Télécharger Windows' }],
        },
        {
          key: 'linux',
          title: 'Linux',
          description: 'Application desktop pour Linux.',
          links: [{ href: `${releaseBaseUrl}/novaville-linux.zip`, label: 'Télécharger Linux' }],
        },
        {
          key: 'macos-ios',
          title: 'Apple (macOS / iOS)',
          description: 'Application pour les appareils Apple (Mac, iPhone, iPad).',
          links: [{ href: releasePageUrl, label: 'Voir la release' }],
        },
      ];
}

function FeaturesSection() {
  return (
    <section className={styles.featuresSection}>
      <div className="container">
        <div className="row">
          <div className="col col--4">
            <div className="text--center">
              <img className={styles.featureSvg} src="/img/undraw_docusaurus_mountain.svg" alt="Rapid onboarding" />
            </div>
            <div className="text--center padding-horiz--md">
              <h3>Prise en main rapide</h3>
              <p>Guide d&apos;initialisation pour exécuter le projet localement avec Docker et lancer les services essentiels.</p>
            </div>
          </div>
          <div className="col col--4">
            <div className="text--center">
              <img className={styles.featureSvg} src="/img/undraw_docusaurus_tree.svg" alt="Architecture" />
            </div>
            <div className="text--center padding-horiz--md">
              <h3>Conçu pour les développeurs</h3>
              <p>Information claire sur l&apos;architecture backend/frontend, les APIs et les points d&apos;intégration critiques.</p>
            </div>
          </div>
          <div className="col col--4">
            <div className="text--center">
              <img className={styles.featureSvg} src="/img/undraw_docusaurus_react.svg" alt="Contribution" />
            </div>
            <div className="text--center padding-horiz--md">
              <h3>Prêt pour la contribution</h3>
              <p>Processus de contribution et workflows CI décrits pour faciliter les PR et la revue de code.</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">Documentation technique et guide pour reprise par une équipe de développement</p>
        <div className={styles.buttons}>
          <Link className="button button--secondary button--lg" to="/docs/dev-onboarding">
            Onboarding développeurs — Commencer
          </Link>
        </div>
      </div>
    </header>
  );
}

function DownloadsSection() {
  const {siteConfig, i18n} = useDocusaurusContext();
  const customFields = siteConfig.customFields as unknown as CustomFields;
  const locale = i18n.currentLocale;
  const downloads = getDownloads(customFields, locale);
  const isEnglish = typeof locale === 'string' ? locale.startsWith('en') : false;
  const releasePageUrl = customFields.releasePageUrl;
  const appLogoUrl = customFields.appLogoUrl;

  return (
    <section className={styles.downloadsSection}>
      <div className="container">
        <div className={styles.downloadsHeader}>
          <div className={styles.downloadsBrandRow}>
            <div>
              <h2 className={styles.downloadsTitle}>{isEnglish ? 'Downloads' : 'Téléchargements'}</h2>
              <p className={styles.downloadsIntro}>
                {isEnglish
                  ? 'Download the Novaville application for your device. These links will always provide you with the most recent version.'
                  : 'Téléchargez l\'application Novaville pour votre appareil. Ces liens vous fourniront toujours la version la plus récente.'}
              </p>
            </div>
          </div>
        </div>

        <div className={styles.downloadsGrid}>
          {downloads.map((item) => (
            <article key={item.key} className={styles.downloadCard}>
              <h3 className={styles.downloadCardTitle}>{item.title}</h3>
              <p className={styles.downloadCardDescription}>{item.description}</p>
              <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                {item.links.map(link => (
                  <Link key={link.label} className="button button--primary button--md" href={link.href}>
                    {link.label}
                  </Link>
                ))}
              </div>
            </article>
          ))}
        </div>

        <div className={styles.downloadsNote}>
          <Link className="button button--secondary button--sm" href={releasePageUrl}>
            {isEnglish ? 'Open latest release' : 'Ouvrir la dernière release'}
          </Link>
        </div>
      </div>
    </section>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="Docs"
      description="Documentation technique, onboarding et téléchargements des builds applicatifs">
      <HomepageHeader />
      <main>
        <DownloadsSection />
        <FeaturesSection />
      </main>
    </Layout>
  );
}
