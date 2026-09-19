'use strict';

// generated:start
const cacheName = 'nesd-dev';
const shell = {};
const engine = {};
// generated:end

self.addEventListener('install', (event) => {
  event.waitUntil(precache(Object.entries(shell)));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(deleteOldCaches());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;

  if (request.method !== 'GET') {
    return;
  }

  let path = pathOf(request.url);

  if (request.mode === 'navigate' && !(path in shell)) {
    path = 'index.html';
  }

  if (!(path in shell) && !(path in engine)) {
    return;
  }

  event.respondWith(fromCache(path));
});

self.addEventListener('message', (event) => {
  if (!event.data || event.data.type !== 'loaded' || !Array.isArray(event.data.urls)) {
    return;
  }

  const paths = new Set(event.data.urls.map(pathOf));
  const entries = [...paths]
    .filter((path) => path in engine)
    .map((path) => [path, engine[path]]);

  event.waitUntil(
    precache(entries).catch((error) => {
      console.warn('nesd: caching the engine failed:', error);
    }),
  );
});

function urlOf(path) {
  return new URL(path, self.registration.scope).href;
}

function pathOf(url) {
  const parsed = new URL(url);
  parsed.search = '';
  parsed.hash = '';

  const scope = self.registration.scope;

  if (!parsed.href.startsWith(scope)) {
    return null;
  }

  return parsed.href.slice(scope.length);
}

async function precache(entries) {
  const cache = await caches.open(cacheName);

  await Promise.all(
    entries.map(async ([path, hash]) => {
      const url = urlOf(path);

      if (await cache.match(url)) {
        return;
      }

      await cache.put(url, await fetchVerified(path, hash));
    }),
  );
}

async function fetchVerified(path, hash) {
  const url = urlOf(path);

  if (hash !== null) {
    const response = await fetch(url);

    if (response.ok && (await matches(response, hash))) {
      return response;
    }
  }

  const response = await fetch(url, { cache: 'reload' });

  if (!response.ok) {
    throw new Error(`${path}: HTTP ${response.status}`);
  }

  if (hash !== null && !(await matches(response, hash))) {
    throw new Error(`${path} does not match the build`);
  }

  return response;
}

async function matches(response, hash) {
  const bytes = await response.clone().arrayBuffer();
  const digest = await crypto.subtle.digest('SHA-256', bytes);

  return hex(digest) === hash;
}

function hex(buffer) {
  return [...new Uint8Array(buffer)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

async function fromCache(path) {
  const cache = await caches.open(cacheName);
  const url = urlOf(path);
  const cached = await cache.match(url);

  if (cached) {
    return cached;
  }

  const hash = path in shell ? shell[path] : engine[path];
  const response = await fetch(url);

  if (response.ok && (hash === null || (await matches(response, hash)))) {
    await cache.put(url, response.clone());
  }

  return response;
}

async function deleteOldCaches() {
  for (const name of await caches.keys()) {
    if (name.startsWith('nesd-') && name !== cacheName) {
      await caches.delete(name);
    }
  }
}
