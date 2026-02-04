import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/attendance_controller.dart';
import '../attendance_view.dart';

class HomeTab extends StatelessWidget {
  final AttendanceController controller = Get.find<AttendanceController>();

  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER PROFILE ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selamat Datang,",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 5),
                      // NAMA USER DINAMIS
                      Obx(
                        () => Text(
                          controller.userName.value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // --- AVATAR DEFAULT (ICON USER) ---
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade800,
                      size: 30,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),

              // --- KARTU STATUS ---
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildStatusColumn("Masuk", controller),
                        ),
                        Container(height: 40, width: 1, color: Colors.white30),
                        Expanded(
                          child: _buildStatusColumn("Pulang", controller),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),
              Text(
                "Menu Utama",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

              // --- GRID MENU (HANYA 3 TOMBOL) ---
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(
                    title: "Check In",
                    icon: Icons.login,
                    color: Colors.green,
                    onTap: () => Get.to(() => AttendanceView()),
                  ),

                  _buildMenuCard(
                    title: "Check Out",
                    icon: Icons.logout,
                    color: Colors.orange,
                    onTap: () => Get.to(() => AttendanceView()),
                  ),

                  // TOMBOL SYNC
                  Obx(
                    () => _buildMenuCard(
                      title: controller.isSyncing.value
                          ? "Mengirim..."
                          : "Sync Server",
                      icon: controller.isSyncing.value
                          ? Icons.hourglass_bottom
                          : Icons.cloud_sync,
                      color: Colors.deepPurple,
                      isLoading: controller.isSyncing.value,
                      onTap: () {
                        if (!controller.isSyncing.value) {
                          controller.syncDataToBackend();
                        }
                      },
                    ),
                  ),

                  // --- CALENDAR SUDAH DIHAPUS DARI SINI ---
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusColumn(String label, AttendanceController ctrl) {
    return Obx(() {
      final today = DateFormat('dd MMMM yyyy').format(DateTime.now());
      final log = ctrl.historyList.firstWhere(
        (e) => e['date'] == today,
        orElse: () => {},
      );
      String time =
          (log.isNotEmpty &&
              log[label == "Masuk" ? 'clockIn' : 'clockOut'] != null)
          ? log[label == "Masuk" ? 'clockIn' : 'clockOut']
          : "--:--";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center Text
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 5),
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
