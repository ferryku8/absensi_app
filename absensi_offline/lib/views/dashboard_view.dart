import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/attendance_controller.dart';

// Import file-file Tab yang terpisah
import 'tabs/home_tab.dart';
import 'history_tab.dart';
import 'profile_tab.dart'; // <--- Ini penting agar membaca file profile_tab.dart yang baru

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  // Pastikan controller di-init di sini agar tersedia untuk Home & Profile
  final AttendanceController controller = Get.put(AttendanceController());

  // Daftar Halaman
  final List<Widget> _views = [
    HomeTab(),
    HistoryTab(), // Pastikan file history_tab.dart ada di folder views
    ProfileTab(), // Akan memanggil ProfileTab dari file profile_tab.dart
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _views),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
