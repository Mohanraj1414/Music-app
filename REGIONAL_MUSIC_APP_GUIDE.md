# Tamil, English and Kannada discovery

This fork retains the Bloomee Flutter + Rust player and its plugin-based
content resolver. The Explore screen now shows separate Tamil, English and
Kannada discovery cards, plus three quick-pick searches. Cards route through
the existing Search screen, rather than pretending that songs ship with the
app. Searches are retried after the selected content plugin becomes ready.

## Run the Android app

Install Flutter, the Android SDK/Android Studio, and Rust tooling required by
the project's `rust_builder`/Flutter-Rust-Bridge setup. From repository root:

```bash
flutter doctor -v
flutter pub get
flutter test
flutter run
```

On Windows, connect an Android device with USB debugging enabled, or start an
Android emulator. Check the repository build guides for its native Rust/NDK
requirements. To build an installable debug APK:

```bash
flutter build apk --debug
```

For release distribution, configure an **original** Android application ID
and label, launcher icon, signing key (kept outside version control), and
the release signing configuration. Then run:

```bash
flutter build apk --release
# For Play Store distribution:
flutter build appbundle --release
```

The existing Android Gradle script has a debug-signing fallback even for
release builds, so configure and verify release signing before distribution.
This repository has not been compiled or tested in the GitHub connector.

## What these cards do

- They query an installed, loaded **content resolver** for the language's songs.
- Search results and playback depend on the provider and its rights/availability.
- These cards do **not** bundle copyrighted tracks or guarantee an entire
  Tamil/English/Kannada catalogue.
- The original player already supports device-local songs, playlists,
  media controls, lyrics and offline capabilities, subject to content rights.

To offer commercial music streaming to the public, obtain licensed catalog
access and follow provider playback restrictions. Do not extract streams from
third-party apps or bypass subscriptions, ads, DRM or their access controls.
You can ship an ad-free player using user-owned local files, appropriately
licensed music, or your own permission-cleared streaming library.

## Next-stage production checklist

1. Select a legal audio catalogue (local files, permissively licensed tracks,
   or a streaming agreement) and implement its resolver if needed.
2. Add real per-track language metadata to supported providers for precise
   language filtering; simple text searches are only an initial discovery UX.
3. Extend ARB localization for complete Tamil/Kannada **interface**
   translations if desired (separate from music language categories).
4. Test network failures, empty result sets, player queue, lock-screen controls,
   downloads, permissions, and offline playback on physical Android phones.
5. Replace original branding and updater URLs as appropriate, while keeping
   copyright/license notices and complying with applicable GPLv2 obligations.
6. Audit dependency security and disable cleartext HTTP outside approved
   contexts before store distribution.
