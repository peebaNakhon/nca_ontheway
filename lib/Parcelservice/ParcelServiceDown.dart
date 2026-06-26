import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:nca_ontheway/class/modal.dart';
import 'package:nca_ontheway/class/Commom.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class ParcelServiceDown extends StatefulWidget {
  final String pageName;
  final String par_qtimedt;
  final String par_qdate;
  final String par_busline;
  final String par_buslinetype;
  final String par_qdttime;
  final String par_action;
  final par_busdata;
  final String mode;
  final Color pageMainColor;

  const ParcelServiceDown({
    super.key,
    required this.pageName,
    required this.par_qtimedt,
    required this.par_qdate,
    required this.par_busline,
    required this.par_buslinetype,
    required this.par_qdttime,
    required this.par_action,
    required this.par_busdata,
    required this.mode,
    required this.pageMainColor,
  });

  @override
  _ParcelServiceDownState createState() => _ParcelServiceDownState();
}

class _ParcelServiceDownState extends State<ParcelServiceDown> {
  late List itemList = []; // Initialize with empty list
  late String _methodPull;
  late String _methodPush;
  late Color _itemTotalColor;

  late bool _isSave = true;

  // GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // print("par_action : ${widget.par_action}");
    switch (widget.par_action) {
      case 'SPRecieve':
        setState(() {
          _methodPull = "ncaGetSvitem";
          _methodPush = "ncaUpdsvitemRecieve";
          _itemTotalColor = Colors.green.shade100;
        });
        break;
      case 'SPReturn':
        setState(() {
          _methodPull = "ncaGetSvitemReturn";
          _methodPush = "ncaUpdsvitemReturn";
          _itemTotalColor = Colors.red.shade100;
        });
        break;
    }
    // print("_methodPull" + _methodPull);
    // print("_methodPush" + _methodPush);
    fetchData(); // Fetch data when the page is loaded
  }

  Future<void> fetchData() async {
    const String apiUrl = 'https://www.nakhonchaiair.com/service/Service.php';
    EasyLoading.show(status: 'รอซักครู่...');
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'method': _methodPull,
          'par_qtimedt': widget.par_qtimedt,
          'par_qdate': widget.par_qdate,
          'par_busline': widget.par_busline,
          'par_buslinetype': widget.par_buslinetype,
          'par_qdttime': widget.par_qdttime
        },
      );

      // print("par_qtimedt : " + widget.par_qtimedt);
      // print("par_qdate : " + widget.par_qdate);
      // print("par_busline : " + widget.par_busline);
      // print("par_buslinetype : " + widget.par_buslinetype);
      // print("par_qdttime : " + widget.par_qdttime);

      // print("RTN : " + response.body);

      inspect(response.body);

      late List responseData = json.decode(response.body);

      if (widget.mode == "ServiceItems") {
        responseData = Commom().filterItemsByCategory(responseData, "25", false);
      } else if (widget.mode == "SellItems") {
        responseData = Commom().filterItemsByCategory(responseData, "25", true);
      }

      for (var item in responseData) {
        item["oldvalue"] = item["svitemqdt_amount"];
        item["remark"] = "";
      }

      inspect(responseData);

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

  Future<void> saveAll() async {
    EasyLoading.show(status: "รอซักครู่....");
    // print("SAVE ALL");
    // print("ITEM LIST LENGTH : ${itemList.length}");
    int rowCount = 0;
    for (var i = 0; i < itemList.length; i++) {
      try {
        // print(itemList[i]);
        final response = await http.post(
          Uri.parse('https://www.nakhonchaiair.com/service/Service.php'),
          body: {'method': _methodPush, 'par_svitemqdt': itemList[i]["svitemqdt"], 'par_amountreturn': itemList[i]["svitemqdt_amount"].toString(), 'pc_remark': itemList[i]["remark"]},
        );
        final responseData = json.decode(response.body);
        // final List responseData = [
        //   {"is_update": 1}
        // ];
        // print(responseData);
        if (responseData[0]['is_update'] == 0) {
          EasyLoading.showError("พบข้อผิดพลาดขณะบันทึก\nโปรดลองอีกครั้ง", dismissOnTap: true, duration: const Duration(seconds: 3));
          break;
        }
        if (responseData[0]['is_update'] == 2) {
          EasyLoading.showError('ไม่สามารถบันทึกได้ หากยังไม่ได้รับของกรุณารับของก่อนจากนั้น ลองทำการคืนของอีกครั้ง', dismissOnTap: true, duration: const Duration(seconds: 5));
          break;
        } else {
          rowCount++;
        }
        if (rowCount == itemList.length) {
          EasyLoading.showSuccess("บันทึกสำเร็จ", dismissOnTap: true, duration: const Duration(milliseconds: 2000));
          setState(() {
            _isSave = true;
          });
          await Future.delayed(const Duration(seconds: 2));
          fetchData();
        }
      } catch (error) {
        // Handle network or other errors
        // print('An error occurred: $error');
      }
    }

    // fetchData();
  }

  @override
  void dispose() {
    EasyLoading.dismiss();
    super.dispose();
  }

  void updateStateOfItem(int index, dynamic value, dynamic remark) {
    setState(() {
      itemList[index]['svitemqdt_amount'] = value;
      itemList[index]['remark'] = remark;
      _isSave = false;
    });
    // print("itemList");
    inspect(itemList);
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
              Text(
                widget.pageName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "${widget.par_busdata["queue_routename"]} ${Commom().getYearFormString(widget.par_busdata["queue_send"])} ${widget.par_busdata["queue_time"]}",
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: widget.pageMainColor,
        ),
        // floatingActionButton: fabButton(),
        body: RefreshIndicator(
          onRefresh: () async {
            await fetchData(); // Replace with your actual data-fetching function
          },
          child: itemList.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh even when empty
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8, // Fill screen height
                    child: const Center(child: Text("ไม่มีของที่ต้องคืน")),
                  ),
                )
              : ListView.builder(
                  itemCount: itemList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      color: index % 2 == 0 ? Colors.grey[200] : Colors.white, // Alternate colors
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Container(
                                width: 25, // Set the width for the amount box
                                alignment: Alignment.center,
                                color: Colors.grey.shade300,
                                child: itemList[index]['svitemqdt_return'] == null
                                    ? const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      )
                                    : const Icon(Icons.check, color: Colors.green),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                itemList[index]['svitem_name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              width: 60,
                              alignment: Alignment.center,
                              // color: _itemTotalColor,
                              color: (itemList[index]['svitemqdt_return'] != null) ? Colors.green.shade100 : Colors.red.shade100,
                              child: (itemList[index]['svitemqdt_return'] != null)
                                  ? Text(
                                      itemList[index]['svitemqdt_return'].toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    )
                                  : Text(
                                      itemList[index]['svitemqdt_amount'].toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        ),
                        onTap: () {
                          int currentAmount = convertToInteger(itemList[index]['svitemqdt_amount']);
                          TextEditingController remark = TextEditingController(text: itemList[index]['remark']);
                          if (itemList[index]['svitemqdt_return'] != "" && itemList[index]['svitemqdt_receipt'] != null) {
                            final itemName = itemList[index]['svitem_name'];
                            EasyLoading.showInfo("$itemName\r\nถูกส่งคืนแล้ว", dismissOnTap: true, duration: const Duration(milliseconds: 3000));
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              int firstValue = currentAmount;
                              String? remakeText = itemList[index]['remark'];
                              return StatefulBuilder(
                                builder: (BuildContext context, setState) {
                                  return AlertDialog(
                                    title: Text(itemList[index]['svitem_name']),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                if (firstValue > 0) {
                                                  setState(() {
                                                    firstValue--;
                                                  });
                                                }
                                              },
                                            ),
                                            Text(
                                              '$firstValue',
                                              style: const TextStyle(fontSize: 20.0),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                setState(() {
                                                  firstValue++;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[],
                                        ),
                                        TextField(
                                          controller: remark,
                                          decoration: const InputDecoration(
                                            hintText: 'หมายเหตุ (ถ้ามี)',
                                          ),
                                          onChanged: (value) {
                                            if (value.trim().isNotEmpty) {
                                              remakeText = value;
                                            } else {
                                              remakeText = null; // Clear the value if it's empty
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('ยกเลิก'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // if (remakeText == "" && firstValue != itemList[index]['oldvalue']) {
                                          //   EasyLoading.showError("กรุณากรอกหมายเหตุ", dismissOnTap: true, duration: const Duration(milliseconds: 2000));
                                          //   return;
                                          // }
                                          updateStateOfItem(index, firstValue, remakeText);
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                          'อัปเดต',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: widget.pageMainColor,
          child: Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500, // Red color for the button
                    minimumSize: const Size(double.infinity, 50), // Full-width button
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("บันทึกการคืนของ"),
                          content: const Text("คุณสามารถบันทึกคืนของได้เพียงครั้งเดียวเท่านั้น หากต้องการแก้ไขกรุณาติดต่อเจ้าหน้าที่สต๊อก\n\nต้องการบันทึกการคืนหรือไม่?"),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('ไม่'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text(
                                'ใช่',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () async {
                                // print("บันทึก");
                                Navigator.of(context).pop();
                                await saveAll();
                                // await fetchData();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('บันทึกทั้งหมด', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
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
                    leading: const Icon(Icons.save),
                    title: const Text('บันทึกทั้งหมด'),
                    onTap: () {
                      // Do something when "Take a Photo" is tapped
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
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text(
                                  'ใช่',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  // print("บันทึก");
                                  Navigator.of(context).pop();
                                  await saveAll();
                                  // await fetchData();
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

  int convertToInteger(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        throw const FormatException("Value cannot be converted to integer");
      }
    } else {
      throw const FormatException("Invalid type. Expected int or String");
    }
  }
}
