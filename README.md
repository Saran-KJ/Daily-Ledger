# Daily Ledger 📒

**Daily Ledger** is a comprehensive, **offline-first** mobile application built with Flutter designed to help you manage your daily expenses and worker payments efficiently.

## 🚀 Key Features

*   **Offline-First Architecture**: No internet connection required. All data is stored securely on your device using SQLite.
*   **Secure Authentication**:
    *   User registration and login with secure password hashing.
    *   **Forgot Password** recovery using a 4-digit Security PIN.
    *   Persistent login session.
*   **Dashboard & Analytics**:
    *   Real-time overview of **Total Paid**, **Total Earned**, and **Pending Payments**.
    *   Smart calculation of pending amounts from both worker and personal entries.
*   **Entry Management**:
    *   **Worker Entries**: Track payments made to workers.
    *   **Personal Entries**: Record your personal daily expenses.
    *   **Full CRUD**: Add, Edit, and Delete entries with ease.
*   **Advanced Filtering**:
    *   Filter entries by **Name**, **Date Range**, **Payment Status** (Paid/Pending), and **Type**.
*   **User Experience**:
    *   Clean, modern UI.
    *   Password visibility toggles.
    *   Swipe-to-delete functionality.

## 🛠️ Tech Stack

*   **Framework**: Flutter
*   **Language**: Dart
*   **Local Database**: `sqflite` (SQLite)
*   **State Management**: `setState` (Simple & Effective)
*   **Authentication**: Local Auth with SHA-256 Hashing

## 📱 Getting Started

1.  **Prerequisites**: Ensure you have Flutter installed on your machine.
2.  **Clone the repository**:
    ```bash
    git clone https://github.com/Saran-KJ/Daily-Ledger.git
    ```
3.  **Install dependencies**:
    ```bash
    cd Daily-Ledger
    flutter pub get
    ```
4.  **Run the app**:
    ```bash
    flutter run
    ```


## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
