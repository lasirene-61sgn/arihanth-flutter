# Arihanth Jewelry Management System

![Arihanth Logo](assets/image/tara_logo_color.jpeg)

Arihanth is a comprehensive B2B Jewelry Management Solution built with Flutter. It streamlines the entire jewelry production and sales lifecycle, from design and catalogue management to work orders, purchase orders, and repairs.

## 🚀 Key Features

### 👥 Role-Based Management
- **Super Admin & Admin**: Full oversight of the platform, user management, and configuration.
- **Buyers**: Browse catalogues, place orders, and track repairs.
- **Craftsmen**: Manage assigned work orders and process repairs.
- **Key Users**: Facilitate operations and manage business partners.

### 📦 Inventory & Catalogue
- **Design Repository**: Centralized database for unique jewelry designs.
- **Product Management**: Categorized view of available jewelry items.
- **Digital Catalogue**: Shareable and searchable product catalogues for buyers.

### 📝 Order Lifecycle
- **Work Orders**: Track production tasks assigned to craftsmen.
- **Purchase Orders**: Manage procurement and sales orders seamlessly.
- **Repairs**: Dedicated module for tracking jewelry repair requests and status.

### 🛠️ Advanced Utilities
- **KYC Management**: Onboard business partners with integrated KYC verification.
- **OCR Integration**: Text recognition for efficient data entry using Google ML Kit.
- **Real-time Rates**: Quick access to live Gold and Silver rates.
- **Multilingual Support**: Built-in localization support for a global user base.
- **PDF Rendering**: High-quality document viewing for orders and reports.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/) (Core logic) & [GetX](https://pub.dev/packages/get) (Navigation)
- **Networking**: [Dio](https://pub.dev/packages/dio) for robust API handling
- **Storage**: [SharedPreferences](https://pub.dev/packages/shared_preferences) for local data
- **Notifications**: [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)
- **OCR**: [Google ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition)

## 📂 Project Structure

```text
lib/
├── app_color/          # Centralized theme and color tokens
├── screens/            # UI Layer (organized by feature)
│   ├── dashboard/      # Main navigation hub
│   ├── purchase_order/ # PO management
│   ├── work_orders/    # Production tracking
│   └── ...             # Feature-specific modules
├── services/           # Business logic & Utilities
│   ├── api/            # API endpoints and interceptors
│   ├── localization/   # i18n support
│   ├── routes/         # App routing configuration
│   └── ...             # Core service modules
└── theme/              # Global app styling
```

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK: `^3.9.2`
- Android Studio / VS Code
- Firebase Project setup (for notifications)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-repo/arianth.git
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Place your `google-services.json` in `android/app/`
   - Place your `GoogleService-Info.plist` in `ios/Runner/`

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📄 Documentation

- **State Management**: Uses `ConsumerStatefulWidget` and `StateNotifier` via Riverpod for predictable state updates.
- **Localization**: Language files are found in `lib/services/localization/`.
- **API**: Centralized `Dio` instance with interceptors for auth and error handling.

---

Built with ❤️ for the Jewelry Industry.
