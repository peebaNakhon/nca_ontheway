// nfcReader.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nca_ontheway/class/Commom.dart';
import 'package:nca_ontheway/landingPage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OilUseReport extends StatefulWidget {
  final data_oiluse;
  final data_busnumber;
  const OilUseReport({super.key, required this.data_oiluse, required this.data_busnumber});

  @override
  State<OilUseReport> createState() => _OilUseReportState();
}

class _OilUseReportState extends State<OilUseReport> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _askReturnToMainMenu(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('แจ้งเตือน'),
              content: const Text('ย้อนกลับไปเมนูหนักหรือไม่?'),
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
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("การใช้น้ำมัน"),
                Text(
                  "รถเบอร์ ${widget.data_busnumber}",
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: widget.data_oiluse.length == 0
              ? const Center(child: Text("ไม่มีข้อมูลการใช้น้ำมันในช่วง 3 วันที่ผ่านมา"))
              : ListView.builder(
                  padding: const EdgeInsets.all(5),
                  itemCount: widget.data_oiluse.length,
                  itemBuilder: (context, index) {
                    var item = widget.data_oiluse[index];
                    inspect(item);
                    return Card(
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text("วันที่ : ${item["queue"]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  child: Text("เส้นทาง : ${item["busway"]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text("เติม : ${item["private"]} ลิตร", textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  child: Text("ใช้ : ${item["use"]} ลิตร", textAlign: TextAlign.center),
                                ),
                                if (double.parse(item["private"]) - double.parse(item["use"]) >= 0)
                                  Expanded(
                                    child: Text("เหลือ : ${(double.parse(item["private"]) - double.parse(item["use"])).abs().toStringAsFixed(2)} ลิตร",
                                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ),
                                if (double.parse(item["private"]) - double.parse(item["use"]) < 0)
                                  Expanded(
                                    child: Text("เกิน : ${((double.parse(item["private"]) - double.parse(item["use"]))).abs().toStringAsFixed(2)} ลิตร",
                                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // ListTile(
                      //   title: Text("วันที่ : ${item["queue"]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      //   subtitle: Text(
                      //     "เส้นทาง : ${item["busway"]}",
                      //     style: const TextStyle(fontSize: 18),
                      //   ),
                      // ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
