// nfcReader.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nca_ontheway/class/Commom.dart';
import 'package:nca_ontheway/landingPage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodePage extends StatefulWidget {
  final par_busdata;
  const QRCodePage({super.key, required this.par_busdata});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  final Color _textColor = const Color.fromRGBO(168, 50, 50, 1);

  late String _employee_name = "";
  late String _employee_type = "";
  late String _employee_code = "";
  late String _employee_id = "";
  late String _employee_status = "";

  Map<String, dynamic> qrCodeDataMap = {};

  late String _qrCodeData = "";

  @override
  void initState() {
    super.initState();
    // _showNFCAvailable();
    _loadUserData().then(
      (value) {
        generateQrCode();
      },
    );
    inspect(widget.par_busdata);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> generateQrCode() async {
    Map<String, dynamic> qrCodeData = {
      "type": "bus",
      "busline": widget.par_busdata["queue_busline"],
      "buslineType": widget.par_busdata["queue_buslinetype"],
      "queueRouteName": widget.par_busdata["queue_routename"],
      "queuedtId": widget.par_busdata["queuedt_id"],
      // "queuedtPlan": widget.par_busdata["queue_plan"],
      "queueTime": widget.par_busdata["queue_time"],
      "queueDate": Commom().getYearFormString(widget.par_busdata["queue_send"]),
      "busNumber": widget.par_busdata["queue_busnumber"],
      "provider": _employee_id
    };

    String busDataJson = jsonEncode(qrCodeData);
    log(busDataJson);
    inspect(busDataJson);

    setState(() {
      qrCodeDataMap = qrCodeData;
      _qrCodeData = busDataJson;
    });
  }

  Map<String, String> _extractUrlParameters(String url) {
    Uri uri = Uri.parse(url.replaceAll('+', '%2B'));

    // Extract parameters from the URI
    Map<String, String> parameters = {};
    uri.queryParameters.forEach((key, value) {
      // Replace '+' with '%2B' to preserve it
      String decodedValue = Uri.decodeComponent(value);
      parameters[key] = decodedValue;
    });

    return parameters;
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _employee_name = prefs.getString("employee_name")!;
      _employee_type = prefs.getString("employee_type")!;
      _employee_code = prefs.getString("employee_code")!;
      _employee_id = prefs.getString("employee_id")!;
      _employee_status = prefs.getString("employee_status")!;
    });
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('แจ้งเตือน'),
              content: const Text('ย้อนกลับหรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User doesn't want to logout
                  },
                  child: const Text('ไม่'),
                ),
                TextButton(
                  onPressed: () {
                    // Perform logout actions if needed
                    Navigator.of(context).pop(true); // User confirmed logout
                  },
                  child: const Text('ใช่'),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if the dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        return Future.value(true);
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('แสดง QC ประจำเที่ยว'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(data: _qrCodeData, size: (MediaQuery.of(context).size.width) * 0.75),
                const SizedBox(height: 50),
                const Divider(),
                const Text(
                  "ข้อมูลเที่ยวรถ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text("เส้นทาง : ${widget.par_busdata["queue_routename"]}"),
                Text("เบอร์รถ : ${widget.par_busdata["queue_busnumber"]}"),
                Text("เที่ยวเวลา : ${widget.par_busdata["queue_time"]}"),
                Text("วันที่ : ${Commom().getYearFormString(widget.par_busdata["queue_send"])}"),
                const SizedBox(height: 5),
                const Divider(),
                const SizedBox(height: 5),
                const Icon(Icons.account_circle),
                const Text("ข้อมูลผู้ใช้งาน", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("รหัสพนักงาน : $_employee_code"),
                Text("ชื่อ : $_employee_name")
              ],
            ),
          ),
        ),
      ),
    );
  }
}
