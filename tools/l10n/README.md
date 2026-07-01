# tools/l10n — app-side extra-language localizations

trufi-core ships **en / es / de**. This app adds **Arabic (ar)** for every
trufi-core screen *without forking trufi-core*: concrete subclasses of the core
`*Localizations` classes are generated into `lib/l10n/` and registered via
`AppConfiguration(extraLocalizationsDelegates: L10n.delegates)`.

The **generator lives in trufi-core** (`trufi_core_utils/bin/gen_extra_l10n.dart`)
— shared by all Trufi apps. This folder holds only this app's **data**: the
translation `.arb` files. (Why a generator and not `flutter gen-l10n`? gen-l10n
can only emit a new standalone class — it can't subclass another package's
class. Flutter then picks the first delegate per type whose `isSupported(locale)`
is true; the core delegates return false for `ar`, so the app's win.)

## Layout

```
tools/l10n/i18n/<lang>/*.arb   # TRANSLATIONS — the source of truth (edit these)
```
Output (generated, do not edit by hand):
```
lib/l10n/l10n_<lang>.dart   # concrete classes + delegates per language
lib/l10n/l10n.dart          # L10n.delegates (single entry point)
```

## Regenerate

```sh
flutter pub get          # once, so .dart_tool/package_config.json exists
dart run trufi_core_utils:gen_extra_l10n
```

The generator resolves trufi-core's packages from
`.dart_tool/package_config.json`, reads `tools/l10n/i18n/<lang>/*.arb`, and writes
`lib/l10n/` — no hard-coded paths, works wherever the dependency is cached.

> Requires a trufi-core version that ships the generator. For local development
> against a trufi-core checkout, add a `dependency_overrides` path for
> `trufi_core_utils` pointing at it.

## Add a language

1. Drop `tools/l10n/i18n/<lang>/<namespace>.arb` for each namespace (copy the
   `ar` files as a template; keys must match the core packages' `*_en.arb`).
2. `dart run trufi_core_utils:gen_extra_l10n`
3. Add `Locale('<lang>')` to `supportedLocales` in `lib/main.dart`.
