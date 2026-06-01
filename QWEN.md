## Qwen Added Memories
- Working on GROUPE NIKEFA Flutter app branding. Modified brand_name.dart to display "GROUPE" (blue) + "NIKEFA" (red) + logo. Added flutter_svg package. Discovered logo.svg is fake SVG (1.8MB embedded PNG). User has real PNG version. Decision pending: use PNG now vs convert to real SVG later.

## Build Fixes (Session 2026-05-22)

### Issue 1 — Core Library Desugaring
- **Error**: `Dependency ':flutter_local_notifications' requires core library desugaring to be enabled for :app`
- **Fix**: `android/app/build.gradle.kts`:
  - Added `isCoreLibraryDesugaringEnabled = true` in `compileOptions`
  - Added `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`

### Issue 2 — R8 / Play Core Missing Classes
- **Error**: `Missing class com.google.android.play.core.*` during `minifyReleaseWithR8`
- **Fix**: Added to `android/app/proguard-rules.pro`:
  ```
  -dontwarn com.google.android.play.core.**
  -keep class com.google.android.play.core.** { *; }
  ```

### Issue 3 — Missing Release Keystore
- **Error**: `signingConfigData.storeFile specifies file '...release-keystore.jks' which doesn't exist`
- **Fix**: Generated keystore via `keytool` with password `nikefa123`, alias `nikefa-key`
- **Fix**: Added default password fallbacks (`: "nikefa123"`) in `signingConfigs` block

### Build Command
- Always use `flutter clean && flutter build apk --release --split-per-abi` to clear stale Gradle cache before release builds.
