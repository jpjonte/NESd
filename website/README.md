# NESd website

The static site for https://nesd.jpj.dev, built with [jaspr](https://jaspr.site) in static mode.
It is a standalone Dart package.

All commands run from this directory.

```bash
fvm dart pub get
tool/fetch_release.sh                 # needs gh CLI, writes build/release.json
fvm dart run jaspr_cli:jaspr serve    # check http://localhost:8080
fvm dart run jaspr_cli:jaspr build --sitemap-domain https://nesd.jpj.dev
                                      # -> build/jaspr/
tool/stage.sh                         # -> build/site/ (what gets deployed)
fvm dart test
```

The landing page's download links come from `build/release.json`, which is the GitHub release API response for the latest release.
The privacy page is rendered from `../PRIVACY.md`.
Both are read at build time and a missing file fails the build.
