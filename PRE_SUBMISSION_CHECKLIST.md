# Pre-Submission Checklist

## ✅ Critical (Must Complete)

- [ ] **Remove hardcoded Supabase credentials** from `supabase_constants.dart`
- [ ] **Replace all `print()` statements** with proper logging (use `AppLogger`)
- [ ] **Test app on real Android device**
- [ ] **Verify offline mode** works correctly
- [ ] **Test admin features** thoroughly
- [ ] **Check all permissions** in AndroidManifest.xml

## 🔧 Code Quality

- [ ] Run `flutter analyze` and fix all warnings
- [ ] Run tests: `flutter test`
- [ ] Format code: `flutter format lib/`
- [ ] Remove unused imports
- [ ] Add missing documentation comments for public APIs

## 📱 Testing Checklist

### User Features
- [ ] Guest mode login works
- [ ] Email/password authentication works
- [ ] Browse categories
- [ ] View entity details
- [ ] Search functionality
- [ ] Submit reviews (authenticated users)
- [ ] View reviews
- [ ] Pull to refresh
- [ ] Offline browsing works

### Admin Features (requires admin user)
- [ ] Access admin dashboard
- [ ] Create new category
- [ ] Edit category
- [ ] Delete category
- [ ] Create new entity
- [ ] Edit entity
- [ ] Delete entity
- [ ] Upload images from camera
- [ ] Upload images from gallery
- [ ] Delete media

### Edge Cases
- [ ] No internet connection behavior
- [ ] Empty states display correctly
- [ ] Error handling shows user-friendly messages
- [ ] Long text content doesn't overflow
- [ ] Images load properly (or show placeholder)

## 📄 Documentation

- [ ] Update project_report.md with screenshots
- [ ] Add your team names to README.md
- [ ] Document any known issues or limitations
- [ ] Create user guide (optional but recommended)

## 🚀 Pre-Release

- [ ] Change app name in `AndroidManifest.xml` (currently "Village Explorer")
- [ ] Update version in `pubspec.yaml` if needed
- [ ] Test app icon displays correctly
- [ ] Build release APK: `flutter build apk --release`
- [ ] Install and test release APK on device
- [ ] Check APK size (should be reasonable, ~20-50MB)

## 📊 Project Presentation

- [ ] Prepare demo scenario/script
- [ ] Take screenshots of key features
- [ ] Record demo video (optional)
- [ ] Prepare to explain architecture
- [ ] Be ready to discuss challenges and solutions
- [ ] Highlight unique features (Chinese design, offline support, admin features)

## 🎓 Academic Requirements

Based on project_requirements.md:
- [ ] **More than 5 views** ✅ (Home, Category List, Detail, Search, Profile, Admin Dashboard, Login, etc.)
- [ ] **Data persistence** ✅ (Hive for local storage)
- [ ] **Remote interaction** ✅ (Supabase backend)
- [ ] **Advanced features** ✅ (Optimistic updates, offline-first, media upload)
- [ ] **Device features** ✅ (Camera, Gallery, Internet)
- [ ] **User-friendly interface** ✅ (Chinese-themed design)
- [ ] **Documentation** ✅ (README, project_report.md)

## 📝 Notes

- Keep backup of your Supabase database
- Don't delete test data until after presentation
- Have a fallback demo ready in case of internet issues
- Know your RLS policies and security measures
