# Daily Ledger 📒

**Daily Ledger** is a comprehensive, **offline-first** mobile application built with Flutter designed to help you manage your daily expenses and worker payments efficiently.

## 🚀 Key Features

*   **Offline-First Architecture**: No internet connection required. All data is stored securely on your device using SQLite.
*   **Secure Authentication**:
    *   User registration and login with secure password hashing (SHA-256).
    *   **Forgot Password** recovery using a 4-digit Security PIN.
    *   Persistent login session.
*   **Dashboard & Analytics**:
    *   Real-time overview of **Total Paid**, **Total Earned**, and **Pending Payments**.
    *   Smart calculation of pending amounts from both worker and personal entries.
    *   User profile avatar with quick access to account information.
*   **Entry Management**:
    *   **Worker Entries**: Track payments made to workers with detailed information.
    *   **Personal Entries**: Record your personal daily expenses.
    *   **Full CRUD**: Add, Edit, and Delete entries with ease.
*   **Advanced Filtering**:
    *   Filter entries by **Name**, **Date Range**, **Payment Status** (Paid/Pending), and **Type**.
    *   View complete entry history with search capabilities.
*   **PDF Export** 📄:
    *   Generate comprehensive PDF reports of all entries.
    *   **Share PDF**: Use Android's native share dialog to save or share via apps.
    *   **Save to Device**: Directly save PDFs to your Downloads folder.
    *   Fully compatible with Android 9 and above.
*   **Payment Tracking**:
    *   Dedicated payments screen to manage pending and completed transactions.
    *   Mark payments as received/paid with a single tap.
*   **User Experience**:
    *   Clean, modern Material Design UI.
    *   Password visibility toggles for better security.
    *   Swipe-to-delete functionality.
    *   Responsive design optimized for mobile devices.

## 🛠️ Tech Stack

*   **Framework**: Flutter
*   **Language**: Dart
*   **Local Database**: `sqflite` (SQLite)
*   **State Management**: `setState` (Simple & Effective)
*   **Authentication**: Local Auth with SHA-256 Hashing
*   **PDF Generation**: `pdf` & `printing` packages
*   **Permissions**: `permission_handler` for storage access

## 📱 Platform Support

*   ✅ Android (API 21+) - Optimized for Android 9 and above
*   ✅ iOS
*   ✅ Windows
*   ✅ macOS
*   ✅ Linux
*   ✅ Web

## 📋 Prerequisites

*   Flutter SDK (3.8.1 or higher)
*   Dart SDK (3.8.1 or higher)
*   For Android builds: Android Studio or Android SDK
*   For Windows builds: Developer Mode enabled

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/Saran-KJ/Daily-Ledger.git
cd Daily-Ledger/frontend
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App

**For Development (Debug Mode):**
```bash
flutter run
```

**For Android Release Build:**
```bash
flutter build apk --release
```
The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

**For Windows:**
```bash
# Enable Developer Mode first (one-time setup)
start ms-settings:developers

# Then build
flutter build windows --release
```

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔧 Configuration

### Android Permissions
The app requires the following permissions (already configured in `AndroidManifest.xml`):
- `INTERNET` - For printing package functionality
- `WRITE_EXTERNAL_STORAGE` - For saving PDFs (Android 12 and below)
- `READ_EXTERNAL_STORAGE` - For reading files (Android 12 and below)

### Windows Setup
Enable Developer Mode for building with plugins:
```powershell
start ms-settings:developers
```

## 📖 Usage Guide

### First Time Setup
1. Launch the app
2. Create an account with your name, email, and password
3. Set a 4-digit Security PIN for password recovery
4. Login with your credentials

### Adding Entries
1. From the Dashboard, tap **Add Worker** or **Add Personal Entry**
2. Fill in the required details (name, description, cost, date)
3. Mark as "Not Received/Paid" if payment is pending
4. Tap **Submit**

### Exporting PDF Reports
1. Tap **Export PDF** from the Dashboard
2. Choose between:
   - **Share PDF**: Opens Android share dialog (save to Files, share via WhatsApp, etc.)
   - **Save to Device**: Directly saves to Downloads folder
3. The PDF includes all worker and personal entries with totals

### Managing Payments
1. Navigate to **Payments** from Quick Actions
2. View all pending and completed payments
3. Tap on any entry to mark as paid/received

### Password Recovery
1. On login screen, tap **Forgot Password?**
2. Enter your email and 4-digit Security PIN
3. Set a new password

## 🗂️ Project Structure

```
frontend/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── screens/                     # UI screens
│   │   ├── login_screen.dart
│   │   ├── add_worker_screen.dart
│   │   ├── add_personal_entry_screen.dart
│   │   ├── entry_history_screen.dart
│   │   └── payments_screen.dart
│   ├── services/                    # Business logic
│   │   ├── api_service.dart         # Data operations
│   │   ├── auth_service.dart        # Authentication
│   │   ├── database_helper.dart     # SQLite database
│   │   └── pdf_service.dart         # PDF generation
│   └── widgets/                     # Reusable components
│       ├── dashboard_card.dart
│       └── quick_action_button.dart
├── android/                         # Android-specific files
├── ios/                            # iOS-specific files
└── pubspec.yaml                    # Dependencies
```

## 🐛 Known Issues & Solutions

### Export PDF not visible on Android 9
**Solution**: The Export PDF button is positioned 2nd in Quick Actions (after "Add Worker"). If you don't see it, try scrolling down or update to the latest release.

### Windows Build Fails
**Solution**: Enable Developer Mode in Windows Settings:
```powershell
start ms-settings:developers
```

## 🔐 Security Features

- Passwords are hashed using SHA-256 before storage
- Security PIN for password recovery
- All data stored locally on device
- No data transmitted to external servers

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**Saran KJ**

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## 📞 Support

For support or questions, please open an issue in the GitHub repository.

---

**Made with ❤️ using Flutter**
