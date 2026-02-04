import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io'; // Wajib import ini untuk menampilkan File Foto
import '../../controllers/attendance_controller.dart';

class HistoryTab extends StatelessWidget {
  final AttendanceController controller = Get.find<AttendanceController>();

  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Attendance Data",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        // Tombol Clear All SUDAH DIHAPUS DARI SINI
      ),
      body: Obx(() {
        if (controller.historyList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  "Belum ada riwayat absensi",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: controller.historyList.length,
          itemBuilder: (context, index) {
            final log = controller.historyList[index];
            return Container(
              margin: EdgeInsets.only(bottom: 15),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // Baris Atas: Tanggal & Status
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log['date'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: log['status'] == 'Late'
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                log['status'],
                                style: TextStyle(
                                  color: log['status'] == 'Late'
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20),
                  // Baris Bawah: Jam Masuk/Pulang, Foto & Lokasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTimeColumn(
                          "Clock In",
                          log['clockIn'],
                          log['photo_in'],
                          log['address_in'],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 80,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildTimeColumn(
                          "Clock Out",
                          log['clockOut'],
                          log['photo_out'],
                          log['address_out'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildTimeColumn(
    String label,
    String time,
    String? photoPath,
    String? address,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
        SizedBox(height: 4),
        Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 8),

        // Menampilkan Thumbnail Foto
        if (photoPath != null && photoPath.isNotEmpty)
          InkWell(
            onTap: () => Get.dialog(
              Dialog(child: Image.file(File(photoPath))),
            ), // Zoom foto saat diklik
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(photoPath),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: Icon(Icons.broken_image, size: 20),
                ),
              ),
            ),
          )
        else
          Icon(
            Icons.camera_alt_outlined,
            size: 30,
            color: Colors.grey.shade300,
          ),

        SizedBox(height: 8),

        // Menampilkan Lokasi (Latitude / Longitude)
        if (address != null)
          Text(
            address,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
