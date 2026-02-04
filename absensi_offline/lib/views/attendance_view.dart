import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/attendance_controller.dart';

class AttendanceView extends StatelessWidget {
  final AttendanceController controller = Get.find<AttendanceController>();

  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Clock In",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Tanggal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Text(
                    DateFormat('dd MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // 2. Timeline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() {
              final today = DateFormat('dd MMMM yyyy').format(DateTime.now());
              final log = controller.historyList.firstWhere(
                (e) => e['date'] == today,
                orElse: () => {},
              );
              String clockInTime = log['clockIn'] ?? "-- : --";
              String clockOutTime = log['clockOut'] ?? "-- : --";

              return Column(
                children: [
                  _buildTimelineItem(
                    title: "Clock In",
                    time: clockInTime,
                    isActive: clockInTime != "-- : --",
                    isFirst: true,
                    isLast: false,
                    buttonText: "Clock In",
                    btnColor: clockInTime != "-- : --"
                        ? Colors.grey.shade200
                        : Colors.blue.shade50,
                    btnTextColor: clockInTime != "-- : --"
                        ? Colors.grey
                        : Colors.blue,
                  ),
                  _buildTimelineItem(
                    title: "Clock Out",
                    time: clockOutTime,
                    isActive: clockOutTime != "-- : --",
                    isFirst: false,
                    isLast: true,
                    buttonText: "Clock Out",
                    btnColor: clockOutTime != "-- : --"
                        ? Colors.grey.shade200
                        : Colors.blue,
                    btnTextColor: clockOutTime != "-- : --"
                        ? Colors.grey
                        : Colors.white,
                  ),
                ],
              );
            }),
          ),

          SizedBox(height: 10),

          // 3. LIVE CAMERA PREVIEW (Bagian Utama)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // LAYAR KAMERA / HASIL FOTO
                  Obx(() {
                    // Cek apakah user sudah selesai absen hari ini?
                    final today = DateFormat(
                      'dd MMMM yyyy',
                    ).format(DateTime.now());
                    final log = controller.historyList.firstWhere(
                      (e) => e['date'] == today,
                      orElse: () => {},
                    );

                    bool isClockOutDone =
                        log.isNotEmpty && log['clockOut'] != '--:--:--';
                    bool isClockInDone =
                        log.isNotEmpty && log['clockIn'] != null;

                    // KONDISI 1: Jika sudah Pulang -> Tampilkan Foto Pulang
                    if (isClockOutDone && log['photo_out'] != null) {
                      return SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.file(
                          File(log['photo_out']),
                          fit: BoxFit.cover,
                        ),
                      );
                    }

                    // KONDISI 2: Jika Kamera Siap & Belum Selesai -> TAMPILKAN LIVE CAMERA
                    if (controller.isCameraInitialized.value) {
                      // CameraPreview butuh controller dari camera package
                      return SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CameraPreview(controller.cameraController!),
                      );
                    }

                    // KONDISI 3: Loading / Placeholder
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }),

                  // OVERLAY GRADASI HITAM
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),

                  // TOMBOL SNAPSHOT (JEPRET)
                  Positioned(
                    bottom: 30,
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return CircularProgressIndicator(color: Colors.white);
                      }

                      // Logic Text Status
                      final today = DateFormat(
                        'dd MMMM yyyy',
                      ).format(DateTime.now());
                      final log = controller.historyList.firstWhere(
                        (e) => e['date'] == today,
                        orElse: () => {},
                      );
                      bool isClockInDone =
                          log.isNotEmpty && log['clockIn'] != null;
                      bool isClockOutDone =
                          log.isNotEmpty && log['clockOut'] != '--:--:--';

                      if (isClockOutDone) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Absensi Selesai",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Text(
                            isClockInDone
                                ? "Tekan untuk Pulang"
                                : "Tekan untuk Masuk",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 15),
                          GestureDetector(
                            onTap: () {
                              if (!isClockInDone) {
                                controller.clockIn();
                              } else if (!isClockOutDone) {
                                controller.clockOut();
                              }
                            },
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                color: Colors
                                    .transparent, // Transparan biar kelihatan 'bolong' kyk tombol shutter
                              ),
                              child: Center(
                                child: Container(
                                  height: 65,
                                  width: 65,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    required bool isActive,
    required bool isFirst,
    required bool isLast,
    required String buttonText,
    required Color btnColor,
    required Color btnTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.blue : Colors.white,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: isActive
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
                margin: EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        SizedBox(width: 15),
        Expanded(
          child: SizedBox(
            height: isLast ? null : 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              color: btnTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
