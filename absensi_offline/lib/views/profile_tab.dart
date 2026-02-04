import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/attendance_controller.dart';

class ProfileTab extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final AttendanceController attendanceController =
      Get.find<AttendanceController>();

  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 30),
            Center(
              child: Container(
                padding: EdgeInsets.all(5), // Padding border lebih besar
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 3),
                ),
                // --- AVATAR DEFAULT BESAR ---
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade50, // Latar belakang lembut
                  child: Icon(
                    Icons.person,
                    size: 60, // Ukuran Icon Besar
                    color: Colors.blue.shade700,
                  ),
                ),
                // -----------------------------
              ),
            ),
            SizedBox(height: 15),

            // NAMA USER DINAMIS
            Obx(() {
              return Text(
                attendanceController.userName.value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              );
            }),

            Text("Karyawan", style: TextStyle(color: Colors.grey)),

            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Biodata",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  _buildProfileItem("Alamat", "Medan, Indonesia"),
                  _buildProfileItem("Status", "Aktif"),
                ],
              ),
            ),

            Spacer(),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authController.logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "LOGOUT",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text(":  $value"),
        ],
      ),
    );
  }
}
