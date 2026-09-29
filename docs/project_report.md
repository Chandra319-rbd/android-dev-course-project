# Village Explorer (村庄探索) - Project Report

## 1. Introduction/Abstract

**Village Explorer (村庄探索)** is a comprehensive mobile application designed to serve as a digital guide for village tourism. Built using **Flutter**, the application targets the Android platform and aims to provide an immersive, culturally rich experience for users exploring the village.

The app allows users to discover various locations (entities) categorized for easy navigation, view detailed information including media galleries, and interact with the community through reviews. It features a distinct **Chinese-style design system**, ensuring the user interface reflects the cultural essence of the village.

Key technical highlights include a robust **offline-first architecture** using Hive for local caching, **Supabase** for real-time backend services (database, authentication, storage), and **GetX** for efficient state management and routing.

## 2. Background

In the era of digital tourism, traditional villages often struggle to present their rich heritage and local businesses to modern travelers. Information is frequently scattered, outdated, or unavailable online.

**Village Explorer** addresses this gap by providing a centralized, easy-to-use platform. It empowers:
*   **Tourists**: To easily find attractions, restaurants, and accommodations with reliable information (opening hours, location, contact).
*   **Locals/Admins**: To manage and update content dynamically without needing technical expertise or app store updates.

The project emphasizes not just utility but also aesthetic alignment with the subject matter, creating a "digital twin" experience of the village's atmosphere.

## 3. Functional Module Diagram

The application is divided into several core functional modules:

```mermaid
graph TD
    App[Village Explorer App]
    
    subgraph User_Side
        Home[Home Module]
        Search[Search Module]
        Category[Category Module]
        Detail[Entity Detail Module]
        Profile[Profile Module]
    end
    
    subgraph Admin_Side
        Dashboard[Dashboard Module]
        ManageCat[Category Management]
        ManageEnt[Entity Management]
        ManageUser[User Management]
        Media[Media Upload]
    end
    
    subgraph Core_Services
        Auth[Authentication]
        Offline[Offline/Cache Service]
        Review[Review System]
    end

    App --> User_Side
    App --> Admin_Side
    App --> Core_Services
```

### Module Descriptions:
*   **Home Module**: Featured places, category grid, pull-to-refresh.
*   **Category Module**: Filtering entities by category, sorting.
*   **Entity Detail Module**: Image carousel, info display, phone calling, map integration.
*   **Admin Dashboard**: Statistics, content CRUD operations (Create, Read, Update, Delete), user management.
*   **User Management**: Search users, toggle admin roles, delete users with cascade handling.
*   **Offline Service**: Syncs data to local Hive storage for access without internet.

## 4. Logical Flow Diagram

The typical user journey through the application:

```mermaid
flowchart LR
    Start((Start)) --> Splash[Splash Screen]
    Splash --> CheckAuth{Auth Check}
    
    CheckAuth -->|Logged In/Guest| Home[Home Screen]
    CheckAuth -->|First Time| Login[Login Screen]
    
    Login -->|Skip/Login| Home
    
    Home --> SelectCat[Select Category]
    Home --> Search[Search]
    
    SelectCat --> EntityList[Entity List]
    Search --> EntityList
    
    EntityList --> ViewDetail[Entity Detail]
    
    ViewDetail --> Actions{User Actions}
    Actions --> Call[Call Phone]
    Actions --> Review[Write Review]
    Actions --> ViewMap[View Address]
    
    Home --> Profile[Profile]
    Profile -->|If Admin| AdminDash[Admin Dashboard]
```

## 5. Technical Architecture Diagram

The project follows a clean architecture pattern separated into Presentation, Domain/Data, and External Services.

```mermaid
graph TD
    subgraph Presentation_Layer
        UI[Flutter Widgets]
        GetX[GetX Controllers]
    end
    
    subgraph Data_Layer
        Repo[Repositories]
        Provider[Data Providers]
        Models[Data Models]
    end
    
    subgraph External_Services
        Supabase[(Supabase Cloud)]
        Hive[(Hive Local DB)]
    end

    UI <--> GetX
    GetX <--> Repo
    Repo --> Provider
    Provider <--> Supabase
    Provider <--> Hive
```

*   **State Management**: GetX is used for reactive state management, dependency injection, and route management.
*   **Backend**: Supabase provides Postgres database, Authentication (Email/Anonymous), and Storage buckets.
*   **Local Storage**: Hive is used to cache Categories and Entities, enabling the "Offline First" capability.

## 6. Class Diagram

Key classes representing the data model and their relationships:

```mermaid
classDiagram
    class CategoryModel {
        +String id
        +String name
        +String iconName
        +String color
        +String imageUrl
        +DateTime createdAt
    }

    class EntityModel {
        +String id
        +String categoryId
        +String name
        +String description
        +String address
        +String openingHours
        +double latitude
        +double longitude
        +double averageRating
        +int reviewCount
        +List~PhoneNumberModel~ phoneNumbers
        +List~MediaModel~ media
        +DateTime createdAt
        +DateTime updatedAt
    }

    class MediaModel {
        +String id
        +String entityId
        +String mediaUrl
        +String mediaType
        +bool isPrimary
        +String uploadedBy
        +DateTime createdAt
    }

    class PhoneNumberModel {
        +String label
        +String number
    }

    class ReviewModel {
        +String id
        +String entityId
        +String userId
        +int rating
        +String comment
        +String userName
        +String userAvatarUrl
        +List~String~ mediaUrls
        +DateTime createdAt
        +DateTime updatedAt
    }

    class ProfileModel {
        +String id
        +String email
        +String fullName
        +String avatarUrl
        +bool isAdmin
        +DateTime createdAt
    }

    CategoryModel "1" -- "*" EntityModel : contains
    EntityModel "1" -- "*" ReviewModel : has
    EntityModel "1" -- "*" MediaModel : has
    EntityModel "1" -- "*" PhoneNumberModel : has
    ProfileModel "1" -- "*" ReviewModel : writes
```

## 7. Unique Features

### 🏮 Chinese Aesthetic Design System
Unlike standard Material Design apps, Village Explorer implements a custom design language tailored to the cultural context.
*   **Color Palette**: Uses traditional colors like Chinese Red (`#C41E3A`), Imperial Gold (`#FFD700`), and Jade Green (`#00A86B`).
*   **Typography & Icons**: Selected to complement the theme.
*   **Decorative Elements**: Custom borders and gradients inspired by traditional architecture.

### 📡 Robust Offline Support
Recognizing that internet connectivity in rural villages can be spotty, the app implements a sophisticated caching strategy.
*   Data is fetched from Supabase and immediately cached in Hive.
*   If the device is offline, the app seamlessly serves data from the local cache.
*   A visual connectivity indicator informs the user of their sync status.

### 🛡️ Integrated Admin Dashboard
The app includes a full-featured administration panel built directly into the mobile client.
*   Admins can add/edit/delete categories and entities on the go.
*   Includes media upload capabilities (Camera/Gallery) directly to Supabase Storage.
*   Real-time statistics view (users, categories, entities, reviews).
*   **User Management**: Search and manage users, toggle admin status, and delete users with proper cascade handling for related data (reviews, media references).

### 👤 Flexible Authentication & User Management
*   **Guest Mode**: Allows tourists to explore immediately without friction.
*   **User Accounts**: Enables interactive features like Reviews.
*   **Role-Based Security**: Simple boolean `is_admin` flag controls access. Row Level Security (RLS) in Supabase ensures only admins can modify core content, while users can manage their own reviews.
*   **Admin Controls**: Admins can promote/demote other users, with self-modification prevention to avoid accidental privilege loss.
*   **Safe User Deletion**: When deleting users, the system properly handles foreign key constraints by nullifying media upload references while cascading review deletions.
