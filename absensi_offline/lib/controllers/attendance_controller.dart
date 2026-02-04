import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class AttendanceController extends GetxController {
  final box = GetStorage();

  // IP Laptop (Pastikan ini benar)
  final String baseUrl = "http://192.168.70.45:8000/api";

  CameraController? cameraController;
  var isCameraInitialized = false.obs;
  late List<CameraDescription> cameras;

  var historyList = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isSyncing = false.obs;

  // Default "Loading..." agar kita tahu kalau belum ke-load
  var userName = "Loading...".obs;

  @override
  void onInit() {
    super.onInit();
    print("--- AttendanceController INIT ---");

    // Reset status sync jaga-jaga kalau nyangkut
    isSyncing.value = false;

    // Load Data User & Absensi
    _checkSessionAndLoadData();

    initializeCamera();
  }

  void _checkSessionAndLoadData() {
    // Debugging Nama
    String? storedName = box.read('user_name');
    print("NAMA DI STORAGE: $storedName"); // Cek log ini nanti!

    if (storedName != null && storedName.isNotEmpty) {
      userName.value = storedName;
    } else {
      userName.value = "Pengguna Baru";
    }

    // Logic Hapus Data Lama jika Ganti Akun
    String? lastUser = box.read('last_logged_user');
    print("USER TERAKHIR: $lastUser | USER SEKARANG: $storedName");

    if (storedName != null && lastUser != null && storedName != lastUser) {
      print(">>> GANTI AKUN TERDETEKSI! MENGHAPUS DATA LAMA...");
      box.remove('attendance_logs');
      historyList.clear();
    }

    // Simpan User Sekarang sebagai Last User
    if (storedName != null) {
      box.write('last_logged_user', storedName);
    }

    // Load History
    if (box.hasData('attendance_logs')) {
      List<dynamic> storedData = box.read('attendance_logs');
      historyList.assignAll(
        storedData.map((e) => e as Map<String, dynamic>).toList(),
      );
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      print("Error Camera: $e");
    }
  }

  Future<void> syncDataToBackend() async {
    print("=== MULAI PROSES SYNC (Fungsi Terpanggil) ===");

    var unsyncedData = historyList
        .where((e) => e['is_synced'] == false)
        .toList();
    if (unsyncedData.isEmpty) {
      Get.snackbar("Info", "Tidak ada data yang perlu dikirim.");
      print("Info: Data kosong / sudah sync semua.");
      return;
    }

    String? token = box.read('token');
    if (token == null || token.isEmpty) {
      Get.snackbar("Gagal Auth", "Token kosong. Login ulang.");
      return;
    }

    isSyncing.value = true;
    List<Map<String, dynamic>> recordsToSend = [];

    // Siapkan Payload
    for (var log in unsyncedData) {
      if (log['photo_in'] != null && File(log['photo_in']).existsSync()) {
        recordsToSend.add({
          "local_id": log['local_id'] ?? DateTime.now().millisecondsSinceEpoch,
          "type": "IN",
          "timestamp": "${log['date']} ${log['clockIn']}",
          "latitude": log['lat_in'],
          "longitude": log['long_in'],
          "photo_base64": base64Encode(File(log['photo_in']).readAsBytesSync()),
        });
      }
      if (log['clockOut'] != '--:--:--' && log['photo_out'] != null) {
        recordsToSend.add({
          "local_id": log['local_id'],
          "type": "OUT",
          "timestamp": "${log['date']} ${log['clockOut']}",
          "latitude": log['lat_out'],
          "longitude": log['long_out'],
          "photo_base64": base64Encode(
            File(log['photo_out']).readAsBytesSync(),
          ),
        });
      }
    }

    if (recordsToSend.isEmpty) {
      isSyncing.value = false;
      Get.snackbar("Info", "File foto hilang dari HP.");
      return;
    }

    // Kirim Request
    try {
      print(
        "Mengirim ${recordsToSend.length} data ke $baseUrl/attendance/sync",
      );
      var response = await http.post(
        Uri.parse('$baseUrl/attendance/sync'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"records": recordsToSend}),
      );

      print("Response Sync: ${response.statusCode} | ${response.body}");

      if (response.statusCode == 200) {
        // Update Local Storage
        for (var item in unsyncedData) {
          int index = historyList.indexOf(item);
          if (index != -1) {
            var updated = Map<String, dynamic>.from(item);
            updated['is_synced'] = true;
            historyList[index] = updated;
          }
        }
        box.write('attendance_logs', historyList.toList());
        Get.snackbar("Sukses", "Data terkirim!");
      } else if (response.statusCode == 401) {
        Get.snackbar("Sesi Habis", "Login ulang diperlukan.");
      } else {
        Get.snackbar("Gagal", "Server: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception Sync: $e");
      Get.snackbar("Koneksi Error", "$e");
    } finally {
      isSyncing.value = false;
    }
  }

  // --- LOGIC CLOCK IN/OUT ---
  Future<void> clockIn() async {
    await _performClockAction(isClockIn: true);
  }

  Future<void> clockOut() async {
    await _performClockAction(isClockIn: false);
  }

  Future<void> _performClockAction({required bool isClockIn}) async {
    final now = DateTime.now();
    final today = DateFormat('dd MMMM yyyy').format(now);
    int index = historyList.indexWhere((e) => e['date'] == today);
    if (isClockIn && index != -1) {
      Get.snackbar("Info", "Sudah Clock In hari ini!");
      return;
    }
    if (!isClockIn &&
        (index == -1 || historyList[index]['clockOut'] != '--:--:--')) {
      Get.snackbar(
        "Info",
        index == -1 ? "Belum Clock In!" : "Sudah Clock Out hari ini.",
      );
      return;
    }

    isLoading.value = true;
    try {
      if (!isCameraInitialized.value || cameraController == null) {
        throw "Kamera belum siap";
      }
      XFile photo = await cameraController!.takePicture();
      Position? position = await _getGeoLocation();

      if (isClockIn) {
        Map<String, dynamic> newLog = {
          'local_id': DateTime.now().millisecondsSinceEpoch,
          'date': today,
          'clockIn': DateFormat('HH:mm:ss').format(now),
          'clockOut': '--:--:--',
          'photo_in': photo.path,
          'lat_in': position?.latitude ?? 0.0,
          'long_in': position?.longitude ?? 0.0,
          'status': now.hour > 9 ? 'Late' : 'On Time',
          'is_synced': false,
        };
        historyList.insert(0, newLog);
      } else {
        var updated = Map<String, dynamic>.from(historyList[index]);
        updated['clockOut'] = DateFormat('HH:mm:ss').format(now);
        updated['photo_out'] = photo.path;
        updated['lat_out'] = position?.latitude ?? 0.0;
        updated['long_out'] = position?.longitude ?? 0.0;
        updated['is_synced'] = false;
        historyList[index] = updated;
      }
      box.write('attendance_logs', historyList.toList());
      Get.back();
      Get.snackbar("Sukses", "Berhasil!");
    } catch (e) {
      Get.snackbar("Error", "$e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<Position?> _getGeoLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition();
  }
}
