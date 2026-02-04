import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Import Views
import 'views/login_view.dart';
import 'views/dashboard_view.dart';

// Import Controllers (untuk dependency injection awal jika diperlukan)
import 'controllers/auth_controller.dart';

void main() async {
  // Inisialisasi Storage (Local DB)
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Absensi Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'sans-serif',
      ),
      // Route Awal
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => LoginView(),
          // Binding AuthController dibuat saat masuk halaman Login
          binding: BindingsBuilder(() {
            Get.put(AuthController());
          }),
        ),
        GetPage(name: '/dashboard', page: () => DashboardView()),
      ],
    );
  }
}
