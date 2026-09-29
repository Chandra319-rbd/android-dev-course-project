# 🏮 Village Explorer (村庄探索)

A beautiful Chinese-style village discovery mobile application built with Flutter for Android. This app serves as a comprehensive digital guide for village tourism, allowing users to explore locations, view detailed information, and interact with the community through reviews.

## 📱 Features

### User Features
- **Browse Categories**: Explore different types of village locations (restaurants, hotels, attractions, etc.)
- **Entity Details**: View comprehensive information including images, videos, contact details, and opening hours
- **Search Functionality**: Find specific locations quickly
- **Reviews & Ratings**: Read and write reviews (authentication required)
- **Offline Support**: Browse cached content even without internet connection
- **Guest Mode**: Explore without creating an account

### Admin Features
- **Dashboard**: View statistics and manage content
- **Category Management**: Add, edit, and delete categories
- **Entity Management**: Full CRUD operations for locations
- **Media Upload**: Upload images and videos directly from camera or gallery
- **Role-Based Access**: Secure admin-only features

### Technical Features
- **Offline-First Architecture**: Seamless experience with Hive local caching
- **Optimistic Updates**: Instant UI feedback before server confirmation
- **Chinese-Themed Design**: Custom color palette and UI elements
- **Real-time Connectivity**: Visual indicators for online/offline status

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.10+
- **State Management**: GetX
- **Backend**: Supabase (PostgreSQL, Authentication, Storage)
- **Local Storage**: Hive
- **Architecture**: Clean Architecture with Repository Pattern

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.0 or higher
- Android Studio / VS Code
- Dart SDK
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd jvapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Copy `.env.example` to `.env`
   - Add your Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```
   - Update `lib/app/core/constants/supabase_constants.dart` with your credentials

4. **Generate Hive adapters**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app/
│   ├── core/                 # Core utilities, constants, themes
│   │   ├── constants/        # App-wide constants
│   │   ├── services/         # Global services (connectivity, caching)
│   │   ├── theme/            # Theme and styling
│   │   └── utils/            # Helper functions
│   ├── data/                 # Data layer
│   │   ├── models/           # Data models with Hive adapters
│   │   ├── providers/        # Data providers (local & remote)
│   │   └── repositories/     # Repository pattern implementations
│   ├── modules/              # Feature modules
│   │   ├── home/             # Home screen
│   │   ├── category/         # Category listing
│   │   ├── entity_detail/    # Entity details
│   │   ├── search/           # Search functionality
│   │   ├── auth/             # Authentication
│   │   ├── profile/          # User profile
│   │   └── admin/            # Admin dashboard
│   ├── routes/               # Navigation setup
│   └── widgets/              # Reusable widgets
└── bindings/                 # Dependency injection
```

## 🔐 Security Notes

**IMPORTANT**: Never commit sensitive credentials to version control!

- Use `.env` files for secrets (already in `.gitignore`)
- Keep Supabase RLS (Row Level Security) policies enabled
- Review admin permissions before deployment

## 🧪 Testing

Run tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## 📝 Database Schema

### Tables
- **categories**: Category information
- **entities**: Location/entity details
- **entity_media**: Images and videos for entities
- **profiles**: User profiles
- **reviews**: User reviews and ratings

### Storage Buckets
- `entity-images`: Entity photos
- `entity-videos`: Entity videos
- `avatars`: User profile pictures

## 🎨 Design System

The app uses a custom Chinese-inspired color palette:
- **Primary**: Chinese Red (#C41E3A)
- **Secondary**: Imperial Gold (#FFD700)
- **Accent**: Jade Green (#00A86B)
- **Background**: Warm Cream (#FFF8F0)

## 📄 License

This project is created for academic purposes as part of an Android Development course.

## 👥 Contributors

[Your Name/Team Names Here]

## 📞 Support

For issues or questions, please contact [your email].

---

Built with ❤️ using Flutter
