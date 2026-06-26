import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:nca_ontheway/class/api_calling.dart';
import 'package:nca_ontheway/class/modal.dart';
import 'package:nca_ontheway/class/Commom.dart';
import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';

class FoodService extends StatefulWidget {
  final String pageName;
  final String par_qtimedt;
  final String par_qdate;
  final String par_busline;
  final String par_buslinetype;
  final String par_qdttime;
  final String par_action;
  final par_busdata;

  const FoodService({
    super.key,
    required this.pageName,
    required this.par_qtimedt,
    required this.par_qdate,
    required this.par_busline,
    required this.par_buslinetype,
    required this.par_qdttime,
    required this.par_action,
    required this.par_busdata,
  });

  @override
  _FoodServicePageState createState() => _FoodServicePageState();
}

class _FoodServicePageState extends State<FoodService> {
  late List itemList = []; // Initialize with empty list

  late bool _isSave = false;

  late String foodType = "1";

  TextEditingController foodReciveController = TextEditingController();
  TextEditingController foodReturnController = TextEditingController();

  final key = GlobalKey<CustomRadioButtonState<String>>();

  late int _itemRemaining = 0;

  @override
  void initState() {
    super.initState();

    setState(() {
      foodType = Commom().checkQTimeFood(widget.par_busdata["queue_time"]);
    });

    print("Food Type : $foodType");

    setStateFoodType(foodType);

    foodReciveController.text = "0";
    foodReturnController.text = "0";
  }

  Future<void> fetchData() async {}

  @override
  void dispose() {
    EasyLoading.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isSave) {
          bool willPop = await modal().showNotSaveDialog(context);
          return willPop;
        } else {
          return true;
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pageName),
                Text(
                  "${widget.par_busdata["queue_routename"]} ${Commom().getYearFormString(widget.par_busdata["queue_send"])} ${widget.par_busdata["queue_time"]}",
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          // floatingActionButton: fabButton(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 5,
              ),
              CustomRadioButton(
                elevation: 2,
                absoluteZeroSpacing: false,
                unSelectedColor: Colors.white,
                buttonLables: const [
                  'ข้าวกล่อง',
                  'แซนวิช',
                ],
                buttonValues: const [
                  "1",
                  "2",
                ],
                buttonTextStyle: const ButtonTextStyle(selectedColor: Colors.white, unSelectedColor: Colors.black, textStyle: TextStyle(fontSize: 16)),
                unSelectedBorderColor: Color.fromRGBO(0, 0, 0, 0),
                selectedBorderColor: Colors.blue.shade400,
                enableButtonWrap: true,
                // width: double.infinity,
                height: 150,
                width: 150,
                radius: 0,
                shapeRadius: 0,
                radioButtonValue: (value) {
                  setStateFoodType(value);
                },
                enableShape: true,
                defaultSelected: foodType,
                selectedColor: Colors.blue.shade400,
              ),
              const Divider(),
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Flexible(
                      child: TextField(
                        controller: foodReciveController,
                        decoration: const InputDecoration(labelText: 'รับมา'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          calRemaingFood();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Flexible(
                      child: TextField(
                        controller: foodReturnController,
                        decoration: const InputDecoration(labelText: 'คืน'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          calRemaingFood();
                        },
                      ),
                    )
                  ],
                ),
              ),
              Text("คงเหลือ $_itemRemaining กล่อง/ชิ้น"),
              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade400),
                      onPressed: () {
                        var reciveInt = (foodReciveController.text);
                        var returnInt = (foodReturnController.text);

                        if (reciveInt.isEmpty || returnInt.isEmpty || returnInt == "0" || reciveInt == "0") {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('แจ้งเตือน'),
                                content: const Text("กรุณากรอกข้อมูลให้ครบ"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          EasyLoading.showSuccess("บันทึกสำเร็จ");
                          setState(() {
                            _isSave = true;
                          });
                        }
                      },
                      child: const Text(
                        "บันทึก",
                        style: TextStyle(color: Colors.white),
                      )),
                ),
              )
            ],
          )
          // bottomNavigationBar: BottomAppBar(
          //   child: Row(
          //     children: <Widget>[
          //       Expanded(
          //         child: ElevatedButton(
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.green.shade500, // Red color for the button
          //             minimumSize: const Size(double.infinity, 50), // Full-width button
          //           ),
          //           onPressed: () {
          //             showDialog(
          //               context: context,
          //               builder: (BuildContext context) {
          //                 return AlertDialog(
          //                   title: const Text("บันทึกทั้งหมด"),
          //                   content: const Text("ต้องการบันทึกข้อมูลทั้งหมดหรือไม่?"),
          //                   actions: <Widget>[
          //                     TextButton(
          //                       child: const Text('ไม่'),
          //                       onPressed: () {
          //                         Navigator.of(context).pop();
          //                       },
          //                     ),
          //                     ElevatedButton(
          //                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          //                       child: const Text(
          //                         'ใช่',
          //                         style: TextStyle(color: Colors.white),
          //                       ),
          //                       onPressed: () async {
          //                         Navigator.of(context).pop();
          //                       },
          //                     ),
          //                   ],
          //                 );
          //               },
          //             );
          //           },
          //           child: const Text('บันทึกทั้งหมด', style: TextStyle(color: Colors.white)),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          ),
    );
  }

  void setStateFoodType(value) {
    setState(() {
      foodType = value.toString();
    });
    key.currentState?.selectButton(value);
    print("Food Type : $foodType");
  }

  void calRemaingFood() {
    var intRevice = foodReciveController.text;
    var intReturn = foodReturnController.text;
    if (intRevice != "0" && intReturn != "0" && intRevice.isNotEmpty && intReturn.isNotEmpty) {
      setState(() {
        _itemRemaining = int.parse(intRevice) - int.parse(intReturn);
      });
    } else {
      return;
    }
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
                    leading: const Icon(Icons.save),
                    title: const Text('บันทึกทั้งหมด'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("บันทึกทั้งหมด"),
                            content: const Text("ต้องการบันทึกข้อมูลทั้งหมดหรือไม่?"),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('ไม่'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              ElevatedButton(
                                child: const Text(
                                  'ใช่',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  // print("บันทึก");
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
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
      backgroundColor: Colors.white,
      child: const Icon(Icons.save),
    );
  }
}
