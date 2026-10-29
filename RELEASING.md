# Releasing Trente

```
develop ──► scripts/release.sh 1.0.1 ──► prod + tag v1.0.1 ──► git push ──► Xcode Cloud ──► TestFlight ──► App Review ──► App Store
```

## Every release

1. On `develop`, everything merged and pushed, tests green.
2. `scripts/release.sh <version>`: sets `MARKETING_VERSION` on every target, merges `develop` into `prod` with a `Release <version>` commit, tags `v<version>`, fast-forwards `develop`. Nothing is pushed.
3. `git push origin develop prod v<version>`.
4. Xcode Cloud's **Release** workflow starts on the `prod` push: tests on the iOS Simulator, archives iOS and macOS, uploads both to TestFlight. Build numbers come from Xcode Cloud. `ci_scripts/ci_post_xcodebuild.sh` writes TestFlight's *What to Test* from the `feat`/`fix` commits since the previous tag.
5. Install from TestFlight on iPhone and Mac. Check iCloud sync between the two and the widget.
6. App Store Connect: new version `<version>` for iOS and macOS, pick the builds, paste release notes in every language, submit. Phased release on for iOS.
7. After approval: GitHub release from the tag (`gh release create v<version> --notes-file …`).

## One-time setup

- Xcode › Integrate › Create Workflow: connect GitHub, product **Trente**, workflow **Release**: start condition *Branch Changes* on `prod`; actions *Test* (Trente scheme, iOS Simulator; macOS test hosts can't launch with Xcode Cloud's ad-hoc signing), *Archive* iOS, *Archive* macOS; post-action *TestFlight Internal Testing*.
- App Store Connect: one app record `louiscarboestaque.Trente` with iOS and macOS platforms, internal testing group.
- CloudKit schema deployed to Production before the first TestFlight build.

## Before the first submission

- Privacy nutrition label: *Data Not Collected* (matches `PrivacyInfo.xcprivacy`).
- Subscriptions `Trente+` monthly and yearly approved with the first version.
- Privacy policy URL live (carbo-estaque.fr/trente/privacy).
