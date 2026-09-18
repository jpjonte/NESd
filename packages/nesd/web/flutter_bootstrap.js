{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    registerServiceWorker();
  },
});

async function registerServiceWorker() {
  if (!('serviceWorker' in navigator)) {
    return;
  }

  try {
    await navigator.serviceWorker.register('sw.js', { updateViaCache: 'none' });

    const registration = await navigator.serviceWorker.ready;
    const urls = performance
      .getEntriesByType('resource')
      .map((entry) => entry.name);

    registration.active.postMessage({ type: 'loaded', urls });
  } catch (error) {
    console.warn('nesd: service worker unavailable:', error);
  }
}
