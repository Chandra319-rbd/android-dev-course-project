# 🏮 Village Explorer App - Development Plan

> A beautiful Chinese-style village discovery app for Android Development Course Final Project

---

## 📋 Project Overview

| Item | Details |
|------|---------|
| **App Name** | Village Explorer (村庄探索) |
| **Target Grade** | Excellent Level |
| **Tech Stack** | Flutter + GetX + Supabase |
| **Platform** | Android |

---

## ✅ Progress Tracker

### Legend
- ⬜ Not Started
- 🟡 In Progress
- ✅ Completed

---

## Phase 1: Foundation Setup

### 1.1 Project Structure
- ✅ Create folder structure (app/core, data, modules, routes, widgets)
- ✅ Setup GetX routing (app_routes.dart, app_pages.dart)
- ✅ Create initial binding

### 1.2 Supabase Setup
- ✅ Create Supabase project
- ✅ Create `categories` table
- ✅ Create `entities` table
- ✅ Create `entity_media` table
- ✅ Create `profiles` table
- ✅ Create `reviews` table
- ✅ Setup storage buckets (entity-images, entity-videos, avatars)
- ✅ Configure Row Level Security (RLS) policies
- ✅ Enable Email & Anonymous Auth providers

### 1.3 Theme & Design System
- ✅ Create app_colors.dart (Chinese color palette)
- ✅ Create app_text_styles.dart
- ✅ Create app_theme.dart
- ✅ Create decorative widgets (Chinese borders, gradients)

### 1.4 Models
- ✅ CategoryModel (with Hive adapter)
- ✅ EntityModel (with Hive adapter)
- ✅ MediaModel
- ✅ ProfileModel
- ✅ ReviewModel
- ✅ PhoneNumberModel

### 1.5 Local Storage (Hive)
- ✅ Setup Hive initialization
- ✅ Create Hive boxes for categories
- ✅ Create Hive boxes for entities
- ✅ Create LocalStorageProvider

---

## Phase 2: Core Screens (User Side)

### 2.1 Splash Screen
- ✅ Chinese-style splash design
- ✅ Load cached data
- ✅ Check auth state
- ✅ Navigate to home

### 2.2 Home Screen
- ✅ Custom app bar with search icon
- ✅ Category grid (2 columns)
- ✅ Featured places horizontal scroll
- ✅ Pull to refresh
- ✅ Loading shimmer effect
- ✅ HomeController

### 2.3 Category List Screen
- ✅ Entity list view
- ✅ Entity card widget
- ✅ Filter/sort options
- ✅ Empty state
- ✅ CategoryController

### 2.4 Entity Detail Screen
- ✅ Image/video carousel
- ✅ Entity information display
- ✅ Phone numbers with call button
- ✅ Opening hours
- ✅ Address
- ✅ Reviews section
- ✅ Add review button (auth required)
- ✅ EntityDetailController

### 2.5 Search Screen
- ✅ Search bar with auto-focus
- ✅ Search results list
- ✅ Recent searches (optional)
- ✅ Empty state
- ✅ SearchController

---

## Phase 3: Authentication & Profile

### 3.1 Auth Setup
- ✅ Configure Email/Password Auth
- ✅ Configure Anonymous Auth
- ✅ AuthController
- ✅ AuthRepository
- ✅ Handle auth state changes

### 3.2 Login Screen
- ✅ Chinese-style design
- ✅ Email/Password form
- ✅ Sign Up option
- ✅ Continue as Guest (Anonymous) button

### 3.3 Profile Screen
- ✅ User avatar and name
- ✅ Login/Logout button
- ✅ My Reviews section
- ✅ Admin Dashboard link (if admin)
- ✅ ProfileController

---

## Phase 4: Reviews & Ratings

### 4.1 Review System
- ✅ ReviewRepository
- ✅ Star rating widget
- ✅ Review form (bottom sheet)
- ✅ Submit review functionality
- ✅ Display average rating on entities
- ✅ Review card widget
- ✅ Edit/Delete own review

---

## Phase 5: Admin Dashboard ✅

### 5.1 Admin Dashboard Screen
- ✅ Stats display (categories, entities, reviews count)
- ✅ Quick action buttons
- ✅ Recent entities list
- ✅ AdminDashboardController

### 5.2 Category Management
- ✅ Category form screen
- ✅ Add new category
- ✅ Edit category
- ✅ Delete category
- ✅ Icon picker
- ✅ Color picker
- ✅ CategoryFormController

### 5.3 Entity Management
- ✅ Entity form screen
- ✅ Add new entity
- ✅ Edit entity
- ✅ Delete entity
- ✅ Category dropdown
- ✅ Phone numbers dynamic list
- ✅ EntityFormController

### 5.4 Media Upload
- ✅ Camera capture (image_picker)
- ✅ Gallery selection
- ✅ Video recording
- ✅ Upload to Supabase storage
- ✅ Progress indicator
- ✅ Delete media

---

## Phase 6: Offline Support ✅

### 6.1 Caching Implementation
- ✅ Cache categories on fetch
- ✅ Cache entities on fetch
- ✅ Load from cache when offline
- ✅ Connectivity check (ConnectivityService)
- ✅ Sync indicator in UI (ConnectivityIndicator widget)
- ✅ Image caching with cached_network_image (CachedImage widget)

---


### 8.1 Project Report
- ✅ Write Introduction/Abstract
- ✅ Write Background section
- ✅ Create Functional Module Diagram
- ✅ Create Logical Flow Diagram
- ✅ Create Technical Architecture Diagram
- ✅ Create Class Diagram
- ✅ Document unique features



---

## 🗄️ Database Schema

### categories
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  color TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### entities
```sql
CREATE TABLE entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  address TEXT,
  phone_numbers JSONB DEFAULT '[]',
  opening_hours TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### entity_media
```sql
CREATE TABLE entity_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  is_primary BOOLEAN DEFAULT FALSE,
  uploaded_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### profiles
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### reviews
```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(entity_id, user_id)
);

create table public.review_media (
  id uuid not null default gen_random_uuid (),
  review_id uuid not null references public.reviews (id) on delete cascade,
  media_url text not null,
  media_type text not null default 'image'::text,
  uploaded_by uuid references auth.users(id), -- Explicitly tracks the uploader
  created_at timestamp with time zone not null default now()
)
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management & Routing
  get: ^4.6.6
  
  # Backend (includes built-in auth)
  supabase_flutter: ^2.8.0
  
  # UI Components
  flutter_staggered_grid_view: ^0.7.0
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  flutter_rating_bar: ^4.0.1
  carousel_slider: ^5.0.0
  
  # Media
  image_picker: ^1.1.2
  video_player: ^2.9.2
  
  # Utilities
  url_launcher: ^6.3.1
  connectivity_plus: ^6.1.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.13
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_theme.dart
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── supabase_constants.dart
│   │   └── utils/
│   │       └── helpers.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── category_model.dart
│   │   │   ├── entity_model.dart
│   │   │   ├── media_model.dart
│   │   │   ├── profile_model.dart
│   │   │   └── review_model.dart
│   │   ├── providers/
│   │   │   ├── supabase_provider.dart
│   │   │   └── local_storage_provider.dart
│   │   └── repositories/
│   │       ├── category_repository.dart
│   │       ├── entity_repository.dart
│   │       ├── auth_repository.dart
│   │       ├── review_repository.dart
│   │       └── media_repository.dart
│   │
│   ├── modules/
│   │   ├── splash/
│   │   ├── home/
│   │   ├── category/
│   │   ├── entity_detail/
│   │   ├── search/
│   │   ├── auth/
│   │   ├── profile/
│   │   └── admin/
│   │
│   ├── routes/
│   │   ├── app_routes.dart
│   │   └── app_pages.dart
│   │
│   └── widgets/
│       ├── common/
│       ├── cards/
│       └── decorative/
│
└── bindings/
    └── initial_binding.dart
```

---

## 🎨 Color Palette (Chinese Style)

| Color | Hex | Usage |
|-------|-----|-------|
| Chinese Red | `#C41E3A` | Primary, buttons, accents |
| Imperial Gold | `#FFD700` | Secondary, highlights |
| Jade Green | `#00A86B` | Success states |
| Warm Cream | `#FFF8F0` | Background |
| Pure White | `#FFFFFF` | Cards |
| Dark Gray | `#2D2D2D` | Primary text |
| Medium Gray | `#666666` | Secondary text |
| Light Gray | `#E0E0E0` | Borders, dividers |

---

## 📱 Screens List

1. **SplashScreen** - App loading
2. **HomeScreen** - Category grid + featured
3. **CategoryListScreen** - Entities in category
4. **EntityDetailScreen** - Full entity info
5. **SearchScreen** - Search entities
6. **LoginScreen** - Google sign-in
7. **ProfileScreen** - User profile
8. **AdminDashboardScreen** - Admin home
9. **CategoryFormScreen** - Add/edit category
10. **EntityFormScreen** - Add/edit entity
11. **ReviewFormBottomSheet** - Write review

---

## 🔐 User Roles

| Permission | Guest | User (Google) | Admin |
|------------|-------|---------------|-------|
| Browse categories | ✅ | ✅ | ✅ |
| View entity details | ✅ | ✅ | ✅ |
| Search | ✅ | ✅ | ✅ |
| Call phone numbers | ✅ | ✅ | ✅ |
| Write reviews | ❌ | ✅ | ✅ |
| Edit own reviews | ❌ | ✅ | ✅ |
| Access admin dashboard | ❌ | ❌ | ✅ |
| Add/Edit/Delete entities | ❌ | ❌ | ✅ |
| Add/Edit/Delete categories | ❌ | ❌ | ✅ |
| Upload media | ❌ | ❌ | ✅ |

---

## 📝 Notes

- **Deadline**: _[Fill in your deadline]_
- **Village Name**: _[Fill in village name for branding]_
- **Supabase Project URL**: _[Fill after creation]_
- **Supabase Anon Key**: _[Fill after creation]_

---

## 🐛 Known Issues / TODO

_Track any issues or additional todos here_

1. -
2. -
3. -

---

## 📅 Timeline

| Week | Focus Area | Status |
|------|------------|--------|
| Week 1 | Phase 1: Foundation | ⬜ |
| Week 2 | Phase 2: Core Screens | ⬜ |
| Week 3 | Phase 3 & 4: Auth & Reviews | ⬜ |
| Week 4 | Phase 5: Admin Dashboard | ⬜ |
| Week 5 | Phase 6 & 7: Offline & Polish | ⬜ |
| Week 6 | Phase 8: Documentation | ⬜ |

---

_Last Updated: December 5, 2025_
