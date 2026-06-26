import 'dart:ffi';
import 'dart:math';

import 'package:countup/countup.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nca_ontheway/class/api_calling.dart';
import 'package:nca_ontheway/class/Commom.dart';
import 'package:nca_ontheway/landingPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Checkpoint extends StatefulWidget {
  final par_busdata;

  // ignore: non_constant_identifier_names
  const Checkpoint({super.key, required this.par_busdata});

  @override
  State<StatefulWidget> createState() => _CheckpointState();
}

class _CheckpointState extends State<Checkpoint> {
  late String _lat = "N/A";
  late String _long = "N/A";

  late String _employee_name = "";
  late String _employee_type = "";
  late String _employee_code = "";
  late String _employee_id = "";
  late String _employee_status = "";
  late String _employee_typeName = "";

  late bool _isCheckPointAvailable = false;

  late double _userDistanceInKm = 0;

  late String _informText = " ไม่อยู่ในระยะที่ลงชื่อจุดเปลี่ยนพ่วงได้\n โปรดอยู่ในระยะ 1 กิโลเมตร";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUserData();
    getUserLatLog();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _employee_name = prefs.getString("employee_name")!;
      _employee_type = prefs.getString("employee_type")!;
      _employee_code = prefs.getString("employee_code")!;
      _employee_id = prefs.getString("employee_id")!;
      _employee_status = prefs.getString("employee_status")!;
      _employee_typeName = prefs.getString("employee_typeName")!;
    });
  }

  Future<void> getUserLatLog() async {
    EasyLoading.show(status: 'กำลังหาตำแหน่ง...');
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    // print(position.latitude);
    // print(position.longitude);

    String long = position.longitude.toString();
    String lat = position.latitude.toString();

    setState(() {
      _lat = lat;
      _long = long;
    });
    await getUserDistanceFromCheckpoint();
    EasyLoading.dismiss();
  }

  Future<void> getUserDistanceFromCheckpoint() async {
    final List? userDistance = await ApiCalling().ncaGetGps(_lat, _long, widget.par_busdata["queuedt_id"]);
    // print(userDistance?[0]);

    if (userDistance != null) {
      if (userDistance[0]["distances"] >= 0 && userDistance[0]["distances"] < 1) {
        setState(() {
          _isCheckPointAvailable = true;
        });
      } else {
        _isCheckPointAvailable = false;
        _informText = " ไม่อยู่ในระยะที่ลงชื่อจุดเปลี่ยนพ่วงได้\n โปรดอยู่ในระยะ 1 กิโลเมตร";
      }

      // print(userDistance?[0]["distances"].runtimeType);

      setState(() {
        _userDistanceInKm = userDistance[0]["distances"];
      });
    } else {
      setState(() {
        _isCheckPointAvailable = false;
        _informText = " รถสายนี้ไม่มีจุดเปลี่ยนพ่วง";
      });
    }
  }

  void ncaSavegps() async {
    // final saveGPSResult = await ApiCalling().ncaSavegps(
    //     widget.par_busdata["queuedt_id"],
    //     _employee_id,
    //     _lat,
    //     _long,
    //     _userDistanceInKm);
    final saveGPSResult = [
      {"is_successlog": "1"}
    ];

    if (saveGPSResult[0]["is_successlog"] == "1") {
      EasyLoading.showSuccess("ลงชื่อสำเร็จ");
    } else {
      EasyLoading.showError("ลงชื่อไม่สำเร็จ\nโปรดลองอีกครั้ง");
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            shadowColor: Colors.grey.shade300,
            elevation: 3,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ลงชื่อจุดเปลี่ยนพ่วง"),
                Text(
                  "${widget.par_busdata["queue_routename"]} ${Commom().getYearFormString(widget.par_busdata["queue_send"])} ${widget.par_busdata["queue_time"]}",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // getUserDistanceFromCheckpoint();
                  getUserLatLog();
                },
                icon: const Icon(Icons.gps_fixed_rounded),
              )
            ],
          ),
          body: RefreshIndicator(
            onRefresh: getUserLatLog,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text("ระยะห่างจากจุดลงชื่อ"),
                  // Text(
                  //   _userDistanceInKm.toStringAsFixed(2),
                  //   style: const TextStyle(
                  //     fontSize: 50,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  Countup(
                    begin: 0,
                    end: _userDistanceInKm,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeIn,
                    precision: 2,
                    style: const TextStyle(
                      fontSize: 69,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text("กิโลเมตร"),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.all(5),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ข้อมูลเที่ยวรถ",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text("เส้นทาง : ${widget.par_busdata["queue_routename"]}"),
                            Text("เบอร์รถ : ${widget.par_busdata["queue_busnumber"]}"),
                            Text("เที่ยวเวลา : ${widget.par_busdata["queue_time"]}"),
                            Text("วันที่ : ${Commom().getYearFormString(widget.par_busdata["queue_send"])}"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.all(5),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ข้อมูลของคุณ",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text('ชื่อ : ${_employee_name}'),
                            Text('รหัสพนักงาน : ${_employee_code}'),
                            // Text('รหัสพนักงาน 2 : ${_employee_id}'),
                            Text('ตำแหน่ง : ${_employee_typeName}'),
                            // SizedBox(height: 10)
                            const Divider(),
                            Text('พิกัดของคุณ : $_lat,$_long'),
                            // Text(''),1
                          ],
                        ),
                      ),
                    ),
                  ),
                  (!_isCheckPointAvailable)
                      ? SizedBox(
                          width: double.infinity,
                          child: Card(
                            color: Colors.redAccent,
                            elevation: 2,
                            margin: const EdgeInsets.all(5),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    _informText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: Card(
                            color: Colors.green,
                            elevation: 2,
                            margin: const EdgeInsets.all(5),
                            child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: SizedBox(
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                                      onPressed: () {
                                        ncaSavegps();
                                      },
                                      child: const Text("ลงชื่อจุดเปลี่ยนพ่วง")),
                                )),
                          ),
                        ),
                  const SizedBox(height: 10),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //   children: [
                  //     (_isCheckPointAvailable)
                  //         ? ElevatedButton(
                  //             onPressed: () {
                  //               getUserLatLog();
                  //             },
                  //             child: const Text("หาตำแหน่ง"))
                  //         : const Text(
                  //             "ยังไม่ถึงจุดลงชื่อได้",
                  //             style: TextStyle(
                  //                 fontWeight: FontWeight.bold,
                  //                 color: Colors.red,
                  //                 fontSize: 35),
                  //           )
                  //   ],
                  // ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
