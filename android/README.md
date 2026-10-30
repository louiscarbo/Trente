# Trente for Android

The native Android version of Trente, written in Kotlin with Jetpack Compose. It is a port of the iOS app in the
parent folder: same months, same 50/30/20 split, same recurring transactions, same CSV export, same seven
languages. Data stays on the device (no sync in this first version).

## Opening the project

1. Install [Android Studio](https://developer.android.com/studio) (Ladybug or newer).
2. **File › Open** and pick this `android` folder (not the repository root).
3. Let Gradle sync. The first sync downloads the Android SDK platform 35 and every library; it can take a few minutes.
4. Pick the `app` run configuration and a device or emulator, then **Run**.

Debug builds use an in-memory database filled with sample data, like the `Trente Dev` scheme on iOS, and are
installed as `app.trente.dev` so they live next to the release build. Release builds use the real database.

## Layout

| Path | Contents |
| --- | --- |
| `core/` | Pure Kotlin module: the domain model, services, notification planners, CSV export and presentation logic. No Android dependency, so it is tested on any JVM. |
| `core/src/test/` | The iOS `TrenteTests` translated to JUnit (327 tests). |
| `app/src/main/java/app/trente/data/` | Room database, the `RoomBackend` that persists the in-memory store, preferences, Android formatting. |
| `app/src/main/java/app/trente/ui/` | Compose screens and the design system. |
| `app/src/main/java/app/trente/notifications/` | Alarms and notifications for recurring reminders, new months and inactivity. |
| `app/src/main/java/app/trente/billing/` | The Trente+ subscription through Google Play Billing. |
| `app/src/main/java/app/trente/widgets/` | The "Month Recap" and "Category Recap" home screen widgets (Glance). |
| `scripts/convert_strings.py` | Generates the Android string resources from `../Trente/Localizable.xcstrings`. |

## How it fits together

- **The store.** `TrenteStore` (in `core`) holds the whole object graph in memory, like SwiftData's main context.
  Screens read it on the main thread and observe `AppContainer.dataVersion` to redraw after a save. `store.save()`
  diffs the graph with what was last saved and hands the difference to `RoomBackend`, which writes it on a
  background thread. Transaction photos are files under `files/images/`, loaded only when displayed.
- **Strings.** The code uses the English sentence as the key, exactly like the iOS string catalog:
  `localized("Needs")`. `scripts/convert_strings.py` turns `Localizable.xcstrings` into `res/values-*/strings.xml`
  and `StringKeys.kt`, the key → resource map. Run it again whenever the catalog changes:

  ```sh
  python3 -I scripts/convert_strings.py ../Trente/Localizable.xcstrings app/src/main
  ```

  A few sentences exist only on Android (for example the data section of Settings, "Rate on Google Play"); they
  fall back to English until they are added to the catalog.
- **Catch-up.** `AppContainer.catchUp()` starts the missing months and records the due automatic transactions when
  the app comes to the foreground, after every save and after a reboot, like `CatchUpService` on iOS.
- **Notifications.** `NotificationScheduler` runs the same planners as iOS and schedules one alarm per reminder
  with `AlarmManager`. The "Mark as Paid" and "Skip" buttons are handled by `NotificationActionReceiver`.

## Tests

```sh
./gradlew -PcoreOnly :core:test      # the logic tests, no Android SDK needed
./gradlew :app:assembleDebug         # the app
```

`-PcoreOnly` leaves the `app` module out of the build, which lets the tests run on a machine without the SDK.

## Before publishing

- **Signing.** Create an upload key and add a `release` signing config in `app/build.gradle.kts`.
- **Trente+.** In the Play Console, create a subscription with product id `trente_plus` and two base plans,
  `monthly` and `yearly` (see `TrentePlus` in `core`). Prices and purchases come from Google Play; nothing is
  verified on a server in this version.
- **Icons.** The launcher icons are the iOS icon previews (192 px). Replace them with adaptive icons in
  `res/mipmap-*` when you have the source artwork.
- **Exact alarms.** Reminders use exact alarms when the user allows them (Android 12+ shows a setting), and a
  15-minute window otherwise.

## What differs from iOS

- No iCloud sync, no Apple Pay logging, no Mac layout. The sidebar is the "All Months" screen and months open
  on top of it.
- Row actions use a long press instead of a swipe.
- The paywall is a Trente screen with the plans listed, since Google Play has no equivalent of
  `SubscriptionStoreView`.
