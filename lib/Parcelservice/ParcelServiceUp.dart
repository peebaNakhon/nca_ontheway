import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:nca_ontheway/class/modal.dart';
import 'package:nca_ontheway/class/Commom.dart';

class ParcelServiceUp extends StatefulWidget {
  final String pageName;
  final String par_qtimedt;
  final String par_qdate;
  final String par_busline;
  final String par_buslinetype;
  final String par_qdttime;
  final String par_action;
  final String mode;
  final par_busdata;
  final Color pageMainColor;

  const ParcelServiceUp({
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
  _ParcelServiceUpPageState createState() => _ParcelServiceUpPageState();
}

class _ParcelServiceUpPageState extends State<ParcelServiceUp> {
  late List itemList = []; // Initialize with empty list
  late String _methodPull;
  late String _methodPush;
  late Color _itemTotalColor;

  late bool _isSave = true;

  @override
  void initState() {
    super.initState();
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
    fetchData(); // Fetch data when the page is loadeds
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
      late List responseData = json.decode(response.body);

      for (var item in responseData) {
        item["oldvalue"] = item["svitemqdt_amount"];
        item["par_amountrecieve"] = item["svitemqdt_amount"];
      }

      if (widget.mode == "ServiceItems") {
        responseData = Commom().filterItemsByCategory(responseData, "25", false);
      } else if (widget.mode == "SellItems") {
        responseData = Commom().filterItemsByCategory(responseData, "25", true);
      }

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
      var amountRecieve = "0";

      if (itemList[i]["svitemqdt_receipt"] != "" && itemList[i]["svitemqdt_receipt"] != null) {
        amountRecieve = itemList[i]["svitemqdt_receipt"];
      } else {
        amountRecieve = itemList[i]["svitemqdt_amount"];
      }

      try {
        final response = await http.post(
          Uri.parse('https://www.nakhonchaiair.com/service/Service.php'),
          body: {'method': _methodPush, 'par_svitemqdt': itemList[i]["svitemqdt"], 'par_amountrecieve': amountRecieve},
        );
        final responseData = json.decode(response.body);
        // final List responseData = [
        //   {"is_update": 1}
        // ];
        inspect(responseData);
        print(responseData);
        if (responseData[0]['is_update'] == 0) {
          EasyLoading.showError("พบข้อผิดพลาดขณะบันทึก\nโปรดลองอีกครั้ง", dismissOnTap: true, duration: const Duration(seconds: 3));
          break;
        } else {
          rowCount++;
        }
        if (rowCount == itemList.length) {
          EasyLoading.showSuccess("บันทึกสำเร็จ", duration: const Duration(milliseconds: 2000));
          setState(() {
            _isSave = true;
          });
          await Future.delayed(const Duration(seconds: 2));
          fetchData();
        }
      } catch (error) {
        // Handle network or other errors
        print('An error occurred: $error');
        EasyLoading.dismiss();
      }
      // await Future.delayed(const Duration(milliseconds: 200));
    }
    // fetchData();
  }

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
                    child: const Center(child: Text("ไม่มีของที่ต้องรับ")),
                  ),
                )
              : ListView.builder(
                  itemCount: itemList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      color: index % 2 == 0 ? Colors.grey[200] : Colors.white,
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                width: 25,
                                alignment: Alignment.center,
                                color: Colors.grey.shade300,
                                child: itemList[index]['svitemqdt_receipt'] == null ? const Icon(Icons.close, color: Colors.red) : const Icon(Icons.check, color: Colors.green),
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
                              color: (itemList[index]['svitemqdt_receipt'] != null) ? Colors.green.shade100 : Colors.red.shade100,
                              child: Text(
                                (itemList[index]['svitemqdt_receipt'] != null) ? itemList[index]['svitemqdt_receipt'].toString() : itemList[index]['svitemqdt_amount'].toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          var currentAmount = itemList[index]['svitemqdt_receipt'] != null ? int.parse(itemList[index]['svitemqdt_receipt']) : int.parse(itemList[index]['svitemqdt_amount']);

                          TextEditingController controller = TextEditingController(text: currentAmount.toString());

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              int newAmount = currentAmount;
                              return AlertDialog(
                                title: Text(itemList[index]['svitem_name']),
                                content: TextField(
                                  keyboardType: TextInputType.number,
                                  controller: controller,
                                  decoration: const InputDecoration(labelText: 'จำนวน'),
                                  onChanged: (value) {
                                    newAmount = int.tryParse(value) ?? currentAmount;
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
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('อัปเดต', style: TextStyle(color: Colors.white)),
                                    onPressed: () {
                                      setState(() {
                                        if (itemList[index]['svitemqdt_receipt'] != null) {
                                          itemList[index]['svitemqdt_receipt'] = newAmount.toString();
                                          itemList[index]['svitemqdt_amount'] = newAmount.toString();
                                        } else {
                                          itemList[index]['svitemqdt_amount'] = newAmount.toString();
                                        }
                                        _isSave = false;
                                      });

                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
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
                                  'อัปเดต',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  // print("บันทึก");
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  saveAll();
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

  void saveData() async {}
}
