#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
script="$root/website/web/js/visit.js"

fail() { echo "visit_script check: $*" >&2; exit 1; }

[ -f "$script" ] || fail "$script missing"
command -v node >/dev/null || fail "node is required"

node - "$script" <<'JS'
const fs = require('fs');
const vm = require('vm');

const source = fs.readFileSync(process.argv[2], 'utf8');

function run(hostname, pathname, storage) {
  const appended = [];
  const context = {
    location: { hostname, pathname },
    sessionStorage: storage,
    document: {
      createElement(tag) {
        return {
          tag,
          attrs: {},
          setAttribute(name, value) { this.attrs[name] = value; },
        };
      },
      head: { appendChild(el) { appended.push(el); } },
    },
  };

  vm.runInNewContext(source, context);

  return appended;
}

function memoryStorage() {
  const data = {};

  return {
    getItem: (key) => (key in data ? data[key] : null),
    setItem: (key, value) => { data[key] = String(value); },
  };
}

const throwingStorage = {
  getItem() { throw new Error('blocked'); },
  setItem() { throw new Error('blocked'); },
};

function assert(condition, message) {
  if (!condition) {
    console.error('visit_script check: ' + message);
    process.exit(1);
  }
}

// Only the production host counts.
assert(run('localhost', '/', memoryStorage()).length === 0,
  'localhost must not count');
assert(run('nesd.example.org', '/', memoryStorage()).length === 0,
  'a foreign host must not count');

// The first load of a page counts exactly once, via GoatCounter.
const storage = memoryStorage();
const added = run('nesd.jpj.dev', '/', storage);

assert(added.length === 1, 'the first load must count once');
assert(added[0].tag === 'script', 'must append a script element');
assert(added[0].async === true, 'count.js must load async');
assert(added[0].src === 'https://stats.jpj.dev/count.js',
  'must load count.js from stats.jpj.dev');
assert(added[0].attrs['data-goatcounter'] === 'https://stats.jpj.dev/count',
  'must post to stats.jpj.dev/count');

// A reload in the same tab does not count again.
assert(run('nesd.jpj.dev', '/', storage).length === 0,
  'a reload must not count');

// Another page in the same tab counts once.
assert(run('nesd.jpj.dev', '/play/', storage).length === 1,
  'a new path must count');
assert(run('nesd.jpj.dev', '/play/', storage).length === 0,
  'reloading the new path must not count');

// Unavailable storage means no count at all.
assert(run('nesd.jpj.dev', '/', throwingStorage).length === 0,
  'a storage failure must fail closed');

console.log('visit_script check: ok');
JS
