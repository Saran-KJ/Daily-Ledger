# Deployment Guide

This guide explains how to build and install the **Release Version** of the Daily Ledger app.

> [!IMPORTANT]
> **Why use the Release Version?**
> When you run the app using `flutter run` (Debug Mode), it relies on the connection to your computer. If you unplug the cable, the app will stop.
> The **Release Version** is a standalone app that runs without any computer connection and is optimized for performance.

## 1. Build the Release APK

Open your terminal in the project folder and run:

```bash
flutter build apk --release
```

This command may take a few minutes. Once finished, it will create an APK file at:
`build/app/outputs/flutter-apk/app-release.apk`

## 2. Install on Your Device

Make sure your Android device is connected via USB.

Run the following command to install the release version onto your phone:

```bash
flutter install
```

## 3. Run Offline

1.  Disconnect the USB cable.
2.  Find the "Daily Ledger" app icon on your phone's home screen or app drawer.
3.  Tap to open it.

The app will now work perfectly without any computer connection!

## 4. Data Persistence

> [!WARNING]
> **Do not uninstall the app if you want to keep your data!**
> Since this is an offline-first app, all data is stored **locally on your device**.
> *   **Updating the app:** If you build and install a new version over the old one (using `flutter install`), your data **WILL BE SAFE**.
> *   **Uninstalling:** If you manually uninstall/delete the app from your phone, your data **WILL BE DELETED** permanently.
