import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/core/constants/supabase_constants.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/providers/local_storage_provider.dart';
import 'app/routes/app_pages.dart';
import 'bindings/initial_binding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive (local storage)
  final localStorage = LocalStorageProvider();
  await localStorage.init();
  Get.put(localStorage, permanent: true);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const VillageExplorerApp());
}

class VillageExplorerApp extends StatelessWidget {
  const VillageExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Village Explorer',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,

      // Routing
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,

      // Initial Binding
      initialBinding: InitialBinding(),

      // Default transition
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),

      // Localization (can be expanded later)
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
