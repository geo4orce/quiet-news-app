# Quiet News Android proof

The Flutter reader loads November 6, 2026 from the public Quiet News feed. All stories display in full. Tap a named source to open its HTTPS link in Android, then press Back to return to the reader. A saved quiet day displays `Quiet.` and a failed load offers Retry.

## Run on the development PC

In PowerShell, open this project folder and set up the current shell:

```powershell
$kit = Join-Path $env:LOCALAPPDATA 'QuietNewsTools'
$env:ANDROID_HOME = Join-Path $kit 'android-sdk'
$env:JAVA_HOME = Join-Path $kit 'jdk-17.0.21+9'
$env:Path = "$kit\flutter\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
```

To start the proof emulator, run `flutter emulators --launch Quiet_News_Pixel`. You can also connect an Android phone with USB debugging enabled. Run `flutter devices`, then `flutter run -d DEVICE_ID` using the listed Android ID. To run the automated checks, use `flutter analyze` and `flutter test`.

## Proof check

Compare the date and first headline with the [saved day](https://quietnews.ai/2026-11-06/). Open the first Associated Press source, verify the destination, and return with Android Back. The proof uses a fixed date so this check also works on days when no stories are published.
