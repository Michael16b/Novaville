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
  href: string;
  label: string;
  icon: React.ReactNode;
};

function AndroidIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M7 7.5c.4 0 .75-.16 1.01-.42l1 1.03a4.7 4.7 0 0 0-1.56 3.52V16a1 1 0 0 0 1 1h1.25V19a1 1 0 1 0 2 0v-2h1.5V19a1 1 0 1 0 2 0v-2H16a1 1 0 0 0 1-1v-4.37c0-1.34-.56-2.55-1.56-3.52l1-1.03A1.49 1.49 0 0 0 18.5 7.5a1.5 1.5 0 1 0-1.51-1.5c0 .24.06.47.15.67l-1.12 1.15A6.73 6.73 0 0 0 12 6.5a6.73 6.73 0 0 0-3.99 1.32L6.89 6.67c.09-.2.15-.43.15-.67A1.5 1.5 0 1 0 7 7.5Zm2.5 3A.5.5 0 1 1 9.5 10a.5.5 0 0 1 0 1Zm5 0A.5.5 0 1 1 14.5 10a.5.5 0 0 1 0 1Z" />
    </svg>
  );
}

function WindowsIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M3 5.5 11 4v7H3V5.5Zm0 13V13h8v7l-8-1.5Zm9-14.5L21 3v8h-9V4Zm0 16v-7h9v8l-9-1Z" />
    </svg>
  );
}

function LinuxIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 3c2.21 0 4 1.79 4 4v2.1c0 .48.19.94.53 1.28l1.12 1.12c.84.84 1.35 1.99 1.35 3.21V19a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-4.29c0-1.22.49-2.37 1.35-3.21l1.12-1.12c.34-.34.53-.8.53-1.28V7c0-2.21 1.79-4 4-4Zm-2.2 8.2c-.6 0-1.1.5-1.1 1.1s.5 1.1 1.1 1.1 1.1-.5 1.1-1.1-.5-1.1-1.1-1.1Zm4.4 0c-.6 0-1.1.5-1.1 1.1s.5 1.1 1.1 1.1 1.1-.5 1.1-1.1-.5-1.1-1.1-1.1ZM9.1 18c.62-1.2 1.63-1.8 2.9-1.8s2.28.6 2.9 1.8H9.1Z" />
    </svg>
  );
}

function WebIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 3a9 9 0 1 0 9 9 9 9 0 0 0-9-9Zm5.93 8h-2.78a12.18 12.18 0 0 0-1.08-4.15A7.03 7.03 0 0 1 17.93 11ZM12 5.1c.7 1.06 1.3 2.54 1.66 4.9h-3.32c.36-2.36.96-3.84 1.66-4.9ZM5.47 13h2.78c.2 1.5.58 2.93 1.08 4.15A7.03 7.03 0 0 1 5.47 13Zm2.78-2H5.47a7.03 7.03 0 0 1 3.86-4.15A12.18 12.18 0 0 0 8.25 11Zm1.93 2h3.64A10.22 10.22 0 0 1 12 18.88 10.22 10.22 0 0 1 10.18 13Zm3.64-2H10.18A10.22 10.22 0 0 1 12 5.12 10.22 10.22 0 0 1 13.82 11Zm.33 6.15c.5-1.22.88-2.65 1.08-4.15h2.78a7.03 7.03 0 0 1-3.86 4.15Z" />
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M16.2 12.4c-.02-2.2 1.8-3.25 1.88-3.3a4.1 4.1 0 0 0-3.2-1.73c-1.38-.14-2.69.81-3.39.81-.72 0-1.8-.79-2.96-.77a4.33 4.33 0 0 0-3.64 2.22c-1.56 2.7-.4 6.68 1.1 8.86.75 1.07 1.63 2.27 2.78 2.22 1.12-.05 1.54-.72 2.89-.72 1.34 0 1.72.72 2.9.69 1.22-.02 1.99-1.11 2.73-2.19a9.4 9.4 0 0 0 1.24-2.51 3.96 3.96 0 0 1-2.33-3.58ZM14.04 5.76c.62-.75 1.04-1.77.93-2.79-.9.04-1.99.6-2.64 1.35-.58.67-1.1 1.71-1 2.7 1 .08 2.02-.5 2.71-1.26Z" />
    </svg>
  );
}

function getDownloads(customFields: CustomFields, locale: string | undefined): DownloadItem[] {
  const localeSafe = typeof locale === 'string' ? locale : undefined;
  const isEnglish = typeof localeSafe === 'string' ? localeSafe.startsWith('en') : false;
  const {releaseBaseUrl, releasePageUrl} = customFields;

  return isEnglish
    ? [
        {
          key: 'android-apk',
          title: 'Android APK',
          description: 'Direct installation on an Android phone or tablet.',
          href: `${releaseBaseUrl}/novaville-android.apk`,
          label: 'Download APK',
          icon: <AndroidIcon />,
        },
        {
          key: 'android-aab',
          title: 'Android AAB',
          description: 'Recommended package for Google Play Store publishing.',
          href: `${releaseBaseUrl}/novaville-android.aab`,
          label: 'Download AAB',
          icon: <AndroidIcon />,
        },
        {
          key: 'web-pwa',
          title: 'Web / PWA',
          description: 'Web build packed for installable PWA use or static hosting.',
          href: `${releaseBaseUrl}/novaville-web-pwa.zip`,
          label: 'Download web build',
          icon: <WebIcon />,
        },
        {
          key: 'windows',
          title: 'Windows',
          description: 'Desktop application for Windows.',
          href: `${releaseBaseUrl}/novaville-windows.zip`,
          label: 'Download Windows',
          icon: <WindowsIcon />,
        },
        {
          key: 'linux',
          title: 'Linux',
          description: 'Desktop application for Linux.',
          href: `${releaseBaseUrl}/novaville-linux.zip`,
          label: 'Download Linux',
          icon: <LinuxIcon />,
        },
        {
          key: 'macos-ios',
          title: 'macOS / iOS',
          description: 'Best-effort publication depending on signing and certificates.',
          href: releasePageUrl,
          label: 'View release',
          icon: <AppleIcon />,
        },
      ]
    : [
        {
          key: 'android-apk',
          title: 'Android APK',
          description: 'Installation directe sur téléphone ou tablette Android.',
          href: `${releaseBaseUrl}/novaville-android.apk`,
          label: 'Télécharger APK',
          icon: <AndroidIcon />,
        },
        {
          key: 'android-aab',
          title: 'Android AAB',
          description: 'Format recommandé pour la publication sur Google Play.',
          href: `${releaseBaseUrl}/novaville-android.aab`,
          label: 'Télécharger AAB',
          icon: <AndroidIcon />,
        },
        {
          key: 'web-pwa',
          title: 'Web / PWA',
          description: 'Version web packagée pour installation ou hébergement statique.',
          href: `${releaseBaseUrl}/novaville-web-pwa.zip`,
          label: 'Télécharger le build web',
          icon: <WebIcon />,
        },
        {
          key: 'windows',
          title: 'Windows',
          description: 'Application desktop pour Windows.',
          href: `${releaseBaseUrl}/novaville-windows.zip`,
          label: 'Télécharger Windows',
          icon: <WindowsIcon />,
        },
        {
          key: 'linux',
          title: 'Linux',
          description: 'Application desktop pour Linux.',
          href: `${releaseBaseUrl}/novaville-linux.zip`,
          label: 'Télécharger Linux',
          icon: <LinuxIcon />,
        },
        {
          key: 'macos-ios',
          title: 'macOS / iOS',
          description: 'Publication best effort selon la signature et les certificats disponibles.',
          href: releasePageUrl,
          label: 'Voir la release',
          icon: <AppleIcon />,
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
  const {siteConfig} = useDocusaurusContext();
  const customFields = siteConfig.customFields as unknown as CustomFields;
  const locale = siteConfig.i18n.currentLocale;
  const downloads = getDownloads(customFields, locale);
  const isEnglish = locale.startsWith('en');
  const releasePageUrl = customFields.releasePageUrl;
  const appLogoUrl = customFields.appLogoUrl;

  return (
    <section className={styles.downloadsSection}>
      <div className="container">
        <div className={styles.downloadsHeader}>
          <div className={styles.downloadsBrandRow}>
            <img className={styles.appLogo} src={appLogoUrl} alt="Novaville app logo" />
            <div>
              <h2 className={styles.downloadsTitle}>{isEnglish ? 'Downloads' : 'Téléchargements'}</h2>
              <p className={styles.downloadsIntro}>
                {isEnglish
                  ? 'The links below always point to the latest published GitHub release. When a new app version is published, the links stay the same and automatically move to the updated assets.'
                  : 'Les liens ci-dessous pointent vers la dernière release GitHub publiée. Quand une nouvelle version de l\'application sort, les liens restent identiques et basculent automatiquement vers les nouveaux assets.'}
              </p>
            </div>
          </div>
        </div>

        <div className={styles.downloadsGrid}>
          {downloads.map((item) => (
            <article key={item.key} className={styles.downloadCard}>
              <div className={styles.downloadCardTop}>
                <div className={styles.platformIcon}>{item.icon}</div>
                <img className={styles.inlineAppLogo} src={appLogoUrl} alt="Novaville" />
              </div>
              <h3 className={styles.downloadCardTitle}>{item.title}</h3>
              <p className={styles.downloadCardDescription}>{item.description}</p>
              <Link className="button button--primary button--md" href={item.href}>
                {item.label}
              </Link>
            </article>
          ))}
        </div>

        <p className={styles.downloadsNote}>
          {isEnglish
            ? 'For web installation, the PWA version is also available directly in the browser after the public frontend is deployed.'
            : 'Pour l\'installation web, la version PWA reste également accessible via le navigateur après déploiement du frontend public.'}
        </p>

        <p className={styles.downloadsNote}>
          {isEnglish
            ? `The app logo used here is the same one shipped with the Flutter frontend.`
            : 'Le logo affiché ici est le même que celui embarqué dans le frontend Flutter.'}
        </p>

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
      title={siteConfig.title}
      description="Documentation technique, onboarding et téléchargements des builds applicatifs">
      <HomepageHeader />
      <main>
        <DownloadsSection />
        <FeaturesSection />
      </main>
    </Layout>
  );
}
