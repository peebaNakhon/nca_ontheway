import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:nca_ontheway/class/api_calling.dart';
import 'package:nca_ontheway/class/Commom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:geolocator/geolocator.dart';

class InHouseUp extends StatefulWidget {
  final String par_qtimedt;
  final String action;
  final String pageName;
  final String pointid;
  final par_busdata;

  const InHouseUp({super.key, required this.par_qtimedt, required this.action, required this.pointid, required this.pageName, required this.par_busdata});

  @override
  _InHouseUpState createState() => _InHouseUpState();
}

class _InHouseUpState extends State<InHouseUp> {
  late List itemList = []; // Initialize with empty list
  late String _methodPull;
  late String _methodPush;
  late String _userCheckMode;
  late String _userCheckModeText;

  late String _lat;
  late String _long;

  late String _employee_name = "";
  late String _employee_type = "";
  late String _employee_code = "";
  late String _employee_id = "";
  late String _employee_status = "";
  late String _employee_typeName = "";
  late String _employee_pic = "https://cdn-icons-png.flaticon.com/512/219/219983.png";

  late String _dcType = "";
  late String _action1 = "";
  late String _action2 = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // print("par_action : ${widget.action}");
    switch (widget.action) {
      case 'parcelInHouseUp':
        setState(() {
          _methodPull = "getParcelUPdt";
          _methodPush = "1";
          _userCheckMode = "3";
          _userCheckModeText = "รับพัสดุภายในขึ้นรถ";
        });
        break;
      case 'parcelInDownUp':
        setState(() {
          _methodPull = "getParcelDowndt";
          _methodPush = "2";
          _userCheckMode = "4";
          _userCheckModeText = "รับพัสดุภายในลงรถ";
        });
        break;
    }
    _loadUserData();

    // print("_userCheckMode : " + _userCheckMode);
    // print("par_qtimedt : ${widget.par_qtimedt}");
    // print("par_busdata : ${widget.par_busdata}");
    getParcelsList();
  }

  void _checkDcType() {
    if (_employee_type == "1") {
      var typeName = "พขร.";
      setState(() {
        _dcType = typeName;
      });
    } else if (_employee_type == "2") {
      var typeName = "โค้ช";
      setState(() {
        _dcType = typeName;
      });
    } else {
      var typeName = "";
      setState(() {
        _dcType = typeName;
      });
    }

    if (_methodPull == "ncaGetParcelDown") {
      setState(() {
        _action1 = "(ขึ้น)";
        _action2 = "(ลง)";
      });
    }
  }

  Future<void> _loadUserData() async {
    EasyLoading.show(status: 'รอซักครู่...');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // _stf = prefs.getString("stf")!;
      // _staffId = prefs.getString("staffId")!;
      // _userdspms = prefs.getString("userdspms")!;

      _employee_name = prefs.getString("employee_name")!;
      _employee_type = prefs.getString("employee_type")!;
      _employee_code = prefs.getString("employee_code")!;
      _employee_id = prefs.getString("employee_id")!;
      _employee_status = prefs.getString("employee_status")!;
      _employee_typeName = prefs.getString("employee_typeName")!;
      _employee_pic = prefs.getString("employee_pic")!;
    });

    // print("employee_id : $_employee_id");
    // print("employee_type : $_employee_type");
    // print("employee_pic : $_employee_pic");

    // print(prefs.getString("rawUserData"));

    _checkDcType();
    EasyLoading.dismiss();
  }

  Future<void> getParcelsList() async {
    const String apiUrl = 'https://www.nakhonchaiair.com/service/Service.php';
    EasyLoading.show(status: 'รอซักครู่...');
    // print(widget.par_qtimedt);
    // print("_userCheckMode : ${_userCheckMode}");
    // print("-----------------------------");
    // print(_methodPull);
    // print(widget.pointid);
    // print(widget.par_busdata["queue_busnumber"]);
    // print(thaiDateToGregorian(
    //     getYearFormString(widget.par_busdata["queue_send"])));
    // print(widget.par_busdata["queue_time"]);
    // print(widget.pointid);

    // print("-----------------------------");
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'method': _methodPull,
          'queuedt_id': widget.par_qtimedt,
          'pointid': widget.pointid,
          'busnumber': widget.par_busdata["queue_busnumber"],
          'quedate': thaiDateToGregorian(getYearFormString(widget.par_busdata["queue_send"])),
          'quetime': widget.par_busdata["queue_time"],
          'formprovince': widget.pointid
        },
      );

      final responseData = json.decode(response.body);

      setState(() {
        itemList = responseData;
      });
    } catch (error) {
      // Handle network or other errors
      // print('An error occurred: $error');
    } finally {
      EasyLoading.dismiss();
    }
  }

  int tappedIndex = -1; // Track the tapped index
  @override
  void dispose() {
    EasyLoading.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent.shade100,
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pageName),
            Text(
              "${widget.par_busdata["queue_routename"]} ${Commom().getYearFormString(widget.par_busdata["queue_send"])} ${widget.par_busdata["queue_time"]}",
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
      body: itemList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: itemList.length,
              itemBuilder: (context, index) {
                return Material(
                  color: (tappedIndex == index)
                      ? Colors.grey[300]
                      : (index % 2 == 0)
                          ? Colors.grey[200]
                          : Colors.white, // Apply colors based on conditions
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        tappedIndex = index; // Update the tapped index
                      });

                      // Reset the tapped index after a delay (500ms)
                      Future.delayed(const Duration(milliseconds: 500), () {
                        setState(() {
                          tappedIndex = -1; // Reset to remove the changed color effect
                        });
                      });
                    },
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_userCheckMode == "3" || _userCheckMode == "4")
                            Text(
                              "${itemList[index]['title']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          Text(
                            "รหัสพัสดุ : ${itemList[index]['id_data']}",
                            style: const TextStyle(fontSize: 15),
                          ),
                          Text(
                            "ส่ง : ${itemList[index]['toprovince']}",
                            style: const TextStyle(fontWeight: FontWeight.normal),
                          ),
                          (itemList[index]['statusup'] == 0)
                              ? const Text(
                                  "สถานะ : ยังไม่รับขึ้นรถ",
                                  style: TextStyle(color: Colors.red),
                                )
                              : const Text(
                                  "สถานะ : รับขึ้นรถแล้ว",
                                  style: TextStyle(color: Colors.green),
                                )

                          // const SizedBox(height: 2),
                        ],
                      ),
                      onTap: () {
                        // Additional actions on tap can be added here
                        // print(itemList[index]);

                        showModalParcelAction(_userCheckModeText, "งง", itemList[index]["id_data"]);
                      },
                    ),
                  ),
                );
              },
            ),
      // floatingActionButton: fabButton(),
      // bottomNavigationBar: BottomAppBar(
      //   child: Row(
      //     children: <Widget>[
      //       Expanded(
      //         child: ElevatedButton(
      //           style: ElevatedButton.styleFrom(
      //             backgroundColor: Colors.red, // Red color for the button
      //             minimumSize:
      //                 const Size(double.infinity, 50), // Full-width button
      //           ),
      //           onPressed: () {
      //             Navigator.pop(context); // Navigate back
      //           },
      //           child: const Text('ย้อนกลับ',
      //               style: TextStyle(color: Colors.white)),
      //         ),
      //       ),
      //       // SizedBox(width: 8), // Adjust the space between buttons
      //       // Expanded(
      //       //   child: ElevatedButton(
      //       //     style: ElevatedButton.styleFrom(
      //       //       backgroundColor: Colors.green, // Green color for the button
      //       //       minimumSize: Size(double.infinity, 50), // Full-width button
      //       //     ),
      //       //     onPressed: () {
      //       //       // Save data and send POST request
      //       //       // Implement the logic to send data to the API
      //       //       saveData();
      //       //     },
      //       //     child: Text('Save', style: TextStyle(color: Colors.white)),
      //       //   ),
      //       // ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget fabButton() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          showDragHandle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          context: context,
          builder: (BuildContext builder) {
            return SizedBox(
              height: 200.0,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.barcode_reader),
                    title: const Text('สแกนพัสดุ'),
                    onTap: () {
                      // Do something when "Take a Photo" is tapped
                      scanBarcode();
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.numbers_rounded),
                    title: const Text('ตรวจสอบโดยระบุจำนวน'),
                    onTap: () {
                      // Do something when "Choose from Gallery" is tapped
                      Navigator.pop(context);
                      checkParcelsByNumber();
                    },
                  ),
                  // ListTile(
                  //   leading: Icon(Icons.location_on),
                  //   title: Text('Share Location'),
                  //   onTap: () {
                  //     // Do something when "Share Location" is tapped
                  //     Navigator.pop(context);
                  //   },
                  // ),
                ],
              ),
            );
          },
        );
      },
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add),
    );
  }

  Future<void> scanBarcode() async {
    try {
      // List<BarcodeFormat> selectedFormats = [BarcodeFormat.code39];

      // print('barcode format list : $selectedFormats');

      final flashOnController = TextEditingController(text: 'Flash on');
      final flashOffController = TextEditingController(text: 'Flash off');
      final cancelController = TextEditingController(text: 'Cancel');

      var aspectTolerance = 0.0;
      //var numberOfCameras = 0;
      //var selectedCamera = -1;
      var useAutoFocus = true;
      var autoEnableFlash = false;

      var result = await BarcodeScanner.scan(
        options: ScanOptions(
          strings: {
            'cancel': cancelController.text,
            'flash_on': flashOnController.text,
            'flash_off': flashOffController.text,
          },
          // restrictFormat: selectedFormats,
          //useCamera: selectedCamera,
          autoEnableFlash: autoEnableFlash,
          android: AndroidOptions(
            aspectTolerance: aspectTolerance,
            useAutoFocus: useAutoFocus,
          ),
        ),
      );

      // print(result.type
      //     .toString()); // The result type (barcode, cancelled, failed)
      // print(result.rawContent.toString()); // The barcode content
      // print(result.format.toString()); // The barcode format (as enum)
      // print(result.formatNote
      //     .toString()); // If a unknown format was scanned this field contains a note
      if (result.type.toString() == 'Cancelled') {
        return;
      }
      String barcodeScanResult = result.rawContent.toString();
      // print('barcodeScanResult : $barcodeScanResult');
      // print('barcodeScanResult.length : ${barcodeScanResult.length}');
      if (barcodeScanResult.length < 12) {
        showModalAlert("แจ้งเตือน", "เลขพัสดุไม่ถูกต้อง ลองใหม่อีกครั้ง");
        return;
      } else {
        showModalParcelAction("แจ้งเตือน", "", barcodeScanResult);
      }
    } catch (e) {
      // print("ERROR : $e");
    }
  }

  Future<void> showModalAlert(String title, String infomation) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_userCheckModeText),
          content: Text(infomation),
          actions: <Widget>[
            // TextButton(
            //   child: const Text('ยกเลิก'),
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //   },
            // ),
            // Text(infomation),
            ElevatedButton(
              child: const Text('ตกลง'),
              onPressed: () {
                // Update itemList with the new amount
                // ncaUpdsvitemRecieve(
                //     itemList[index]['svitem_name'],
                //     newAmount);
                // setState(() {
                //   itemList[index]['svitemqdt_amount'] =
                //       newAmount.toString();
                // });
                // fetchData();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showModalParcelAction(String title, String infomation, String RefNo) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_userCheckModeText),
          content: Text("รหัสพัสดุ : $RefNo"),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('ยืนยัน'),
              onPressed: () async {
                Navigator.of(context).pop();
                ApiCalling()
                    .saveReceived(RefNo, widget.par_busdata["queue_busnumber"], widget.par_busdata["queue_busline"], widget.par_busdata["queue_buslinetype"],
                        thaiDateToGregorian(getYearFormString(widget.par_busdata["queue_send"])), widget.par_busdata["queue_time"], _employee_id)
                    .then((value) => {
                          Future.delayed(const Duration(seconds: 3)).then((val) {
                            getParcelsList();
                          })
                        });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> getUserLatLog() async {
    EasyLoading.show();
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    // print(position.latitude);
    // print(position.longitude);

    String long = position.longitude.toString();
    String lat = position.latitude.toString();

    setState(() {
      _lat = lat;
      _long = long;
    });
    EasyLoading.dismiss();
  }

  Future<void> saveAll() async {}

  Future<void> checkParcelsByNumber() async {
    TextEditingController controller = TextEditingController(text: "0");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int parcelsInt = 0; // Initialize newAmount with the current amount
        return AlertDialog(
          title: const Text("ตรวจสอบโดยระบุจำนวน"),
          content: TextField(
            keyboardType: TextInputType.number,
            controller: controller, // Set the text controller
            decoration: const InputDecoration(
              labelText: 'จำนวนพัสดุ',
            ),
            onChanged: (value) {
              parcelsInt = int.tryParse(value) ?? parcelsInt;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('ตรวจสอบ'),
              onPressed: () {
                // print(itemList.length);
                if (parcelsInt == itemList.length) {
                  EasyLoading.showSuccess("ตรวจสอบสำเร็จ\nพัสดุครบ");
                  Navigator.of(context).pop();
                } else {
                  EasyLoading.showError("จำนวนพัสดุไม่ครบ");
                }
              },
            ),
          ],
        );
      },
    );
  }

  String getYearFormString(String value) {
    RegExp dateRegex = RegExp(r'\b\d{2}/\d{2}/\d{2}\b');
    String extractedDate = dateRegex.stringMatch(value) ?? '';
    // print("extractedDate : ${extractedDate}");
    return extractedDate;
  }

  String thaiDateToGregorian(String thaiDate) {
    List<String> dateParts = thaiDate.split('/');
    if (dateParts.length != 3) {
      // Invalid date format
      return '';
    }

    int? day = int.tryParse(dateParts[0]);
    int? month = int.tryParse(dateParts[1]);
    int? thaiYear = int.tryParse(dateParts[2]);

    if (day == null || month == null || thaiYear == null) {
      // Invalid numeric values
      return '';
    }

    // Convert Thai year to Gregorian year
    int gregorianYear = (thaiYear >= 43) ? thaiYear - 43 + 2000 : thaiYear + 2500;

    // Construct DateTime object with adjusted year
    DateTime gregorianDate = DateTime(gregorianYear, month, day);

    // Format the date as YYYY-MM-DD
    String formattedDate = '${gregorianDate.year.toString().padLeft(4, '0')}-'
        '${gregorianDate.month.toString().padLeft(2, '0')}-'
        '${gregorianDate.day.toString().padLeft(2, '0')}';

    return formattedDate;
  }
}
