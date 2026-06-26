import 'dart:convert';
// import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:nca_ontheway/InHouseParcels/InHouseDown.dart';
import 'package:nca_ontheway/InHouseParcels/InHouseUp.dart';
import 'package:nca_ontheway/ParcelsAction.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class Parcels extends StatefulWidget {
  final String par_qtimedt;
  final String action;
  final String pageName;
  final par_busdata;

  const Parcels({super.key, required this.par_qtimedt, required this.action, required this.par_busdata, required this.pageName});

  @override
  _PaccelsState createState() => _PaccelsState();
}

class _PaccelsState extends State<Parcels> {
  late List itemList = []; // Initialize with empty list
  late String _methodPull;
  late String _nextAction;
  String _waitingText = "กำลังเรียกรายการพัสดุ";
  late String _nextPageName;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // print("par_action : ${widget.action}");
    switch (widget.action) {
      case 'parcelUp':
        setState(() {
          _methodPull = "ncaGetPointToup";
          _nextAction = "parcelUp";
          _nextPageName = "สแกนพัสดุขึ้นรถ";
        });
        break;
      case 'parcelDown':
        setState(() {
          _methodPull = "ncaGetPointToDown";
          _nextAction = "parcelDown";
          _nextPageName = "สแกนพัสดุลงรถ";
        });
        break;
      case 'getParcelUP':
        setState(() {
          _methodPull = "getParcelUP";
          _nextAction = "parcelInHouseUp";
          _nextPageName = "สแกนพัสดุภายในขึ้นรถ";
        });
        break;
      case 'getParcelDown':
        setState(() {
          _methodPull = "getParcelDOWN";
          _nextAction = "parcelInHouseDown";
          _nextPageName = "สแกนพัสดุภายในลงรถ";
        });
        break;
    }
    // print("par_qtimedt : ${widget.par_qtimedt}");
    getParcelsData();
  }

  Future<void> getParcelsData() async {
    const String apiUrl = 'https://www.nakhonchaiair.com/service/Service.php';
    EasyLoading.show(status: 'รอซักครู่...');
    // print("queuedt_id :${widget.par_qtimedt}");
    // print(widget.par_busdata["queue_busnumber"]);
    // print(thaiDateToGregorian(
    //     getYearFormString(widget.par_busdata["queue_send"])));
    // print(widget.par_busdata["queue_time"]);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'method': _methodPull,
          'queuedt_id': widget.par_qtimedt,
          'busnumber': widget.par_busdata["queue_busnumber"],
          'quedate': thaiDateToGregorian(getYearFormString(widget.par_busdata["queue_send"])),
          'quetime': widget.par_busdata["queue_time"],
        },
      );

      final responseData = json.decode(response.body);

      // print(response.body);
      if (responseData == null) {
        setState(() {
          itemList = [];
        });
      } else if (responseData[0]["is_pointnm"] == "") {
        setState(() {
          itemList = [];
        });
      } else {
        setState(() {
          itemList = responseData;
        });
      }

      if (itemList.isEmpty) {
        setState(() {
          _waitingText = "ไม่มีรายการพัสดุ";
        });
      }
    } catch (error) {
      // Handle network or other errors
      // print('An error occurred: $error');
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  void dispose() {
    EasyLoading.dismiss();
    super.dispose();
  }

  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(widget.pageName),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pageName),
            Text(
              "${widget.par_busdata["queue_routename"]} ${widget.par_busdata["queue_time"]} ${getYearFormString(widget.par_busdata["queue_send"])}",
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        onRefresh: () {
          _refreshController.refreshCompleted();
          getParcelsData();
        },
        child: itemList.isEmpty
            ? Center(child: Text(_waitingText))
            : ListView.builder(
                itemCount: itemList.length,
                itemBuilder: (context, index) {
                  return Container(
                    color: index % 2 == 0 ? Colors.grey[200] : Colors.white, // Alternate colors
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Image.network(
                          //   "https://cdn-icons-png.flaticon.com/512/2821/2821882.png",
                          //   width: 50,
                          //   height: 50,
                          //   fit: BoxFit.cover,
                          // ),
                          Image.asset('assets/n-parcels.png', width: 50, height: 50, fit: BoxFit.cover),
                          Expanded(
                            child: (_methodPull == "ncaGetPointToup" || _methodPull == "ncaGetPointToDown")
                                ? Text(
                                    "  " + itemList[index]['is_pointnm'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                : (_methodPull == "getParcelUP")
                                    ? Text(
                                        "  " + itemList[index]['formprovince'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      )
                                    : Text(
                                        "  " + itemList[index]['toprovince'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                          ),
                          Container(
                            width: 50, // Set the width for the amount box
                            alignment: Alignment.center,
                            color: Colors.grey[300],
                            child: (_methodPull == "ncaGetPointToup" || _methodPull == "ncaGetPointToDown")
                                ? Text(
                                    itemList[index]['is_total'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                : Text(
                                    itemList[index]['amount'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          )
                        ],
                      ),
                      onTap: () {
                        // Show modal or popup to input amount
                        // Implement logic for updating item_amount here
                        // print(_methodPull);
                        // print(itemList[index]['is_pointid']);
                        if (_methodPull == "ncaGetPointToup" || _methodPull == "ncaGetPointToDown") {
                          openParcelsActionPage(_nextAction, itemList[index]['is_pointid']);
                        } else {
                          Map<String, dynamic> mergedMap = {};
                          itemList.forEach((map) {
                            map.forEach((key, value) {
                              mergedMap[key] = value;
                            });
                          });
                          // print(mergedMap);
                          if (mergedMap.containsKey("toprovince")) {
                            openParcelsActionPage(_nextAction, itemList[index]['toprovince']);
                          } else {
                            openParcelsActionPage(_nextAction, itemList[index]['formprovince']);
                          }
                        }
                      },
                    ),
                  );
                },
              ),
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
      ),
    );
  }

  void openParcelsActionPage(String action, String pointid) {
    // print(action);
    if (action == "parcelInHouseUp") {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => InHouseUp(
            par_qtimedt: widget.par_qtimedt,
            action: action,
            pointid: pointid,
            pageName: _nextPageName,
            par_busdata: widget.par_busdata,
          ),
        ),
      );
      return;
    } else {
      if (action == "parcelInHouseDown") {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => InHouseDown(
              par_qtimedt: widget.par_qtimedt,
              action: action,
              pointid: pointid,
              pageName: _nextPageName,
              par_busdata: widget.par_busdata,
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ParcelsAction(
            par_qtimedt: widget.par_qtimedt,
            action: action,
            pointid: pointid,
            pageName: _nextPageName,
            par_busdata: widget.par_busdata,
          ),
        ),
      );
    }
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
