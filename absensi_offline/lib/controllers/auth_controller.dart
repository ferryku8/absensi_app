import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final emailC = TextEditingController();
  final passC = TextEditingController();

  final box = GetStorage();

  // GANTI IP INI SESUAI BACKEND (SAMA SEPERTI ATTENDANCE CONTROLLER)
  // Emulator: 10.0.2.2 | HP Fisik: IP Laptop (misal 192.168.1.x)
  final String baseUrl = "http://192.168.70.45:8000/api";

  Future<void> login() async {
    if (emailC.text.isEmpty || passC.text.isEmpty) {
      Get.snackbar("Error", "Email dan Password harus diisi");
      return;
    }

    try {
      print("Mencoba login ke $baseUrl/auth/login..."); // Debug Log

      var response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailC.text, "password": passC.text}),
      );

      print("Status Login: ${response.statusCode}");
      print("Body Login: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String token = data['data']['token'];
        String name = data['data']['name'];

        // // --- INI BAGIAN PENTING YANG MUNGKIN HILANG DULU ---
        await box.write('token', token);
        await box.write('user_name', name);
        // ---------------------------------------------------

        print("Token berhasil disimpan: ${token.substring(0, 10)}...");

        Get.snackbar("Sukses", "Login Berhasil");
        Get.offAllNamed('/dashboard');
      } else {
        Get.snackbar("Gagal", "Login gagal. Cek email/password.");
      }
    } catch (e) {
      print("Error Login: $e");
      Get.snackbar("Error", "Tidak bisa konek ke server: $e");
    }
  }

  void logout() {
    box.remove('token');
    box.remove('user_name');
    Get.offAllNamed('/login');
  }
}
