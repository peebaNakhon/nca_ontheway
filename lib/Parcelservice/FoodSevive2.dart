import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:async';

import 'package:nca_ontheway/class/Commom.dart';
import 'package:nca_ontheway/class/api_calling.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodService2 extends StatefulWidget {
  final String pageName;
  final String par_qtimedt;
  final String par_qdate;
  final String par_busline;
  final String par_buslinetype;
  final String par_qdttime;
  final String par_action;
  final par_busdata;

  const FoodService2({
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
  _FoodService2State createState() => _FoodService2State();
}

class _FoodService2State extends State<FoodService2> {
  late String _employee_name = "";
  late String _employee_type = "";
  late String _employee_code = "";
  late String _employee_id = "";
  late String _employee_status = "";
  late String _employee_typeName = "";

  List<Map<String, String>> items = [
    {"id": "1", "name": "ข้าวกล่อง", "image": "take-away.png"},
    {"id": "2", "name": "แซนวิช By พี่ตู๋", "image": "sandwich3ofkind.png"}
  ];

  String selectedItemId = '';
  String selectedItemName = '';

  int receiveValue = 0;
  int returnValue = 0;

  Timer? _timer;

  late String _warningText = "";

  void _incrementReceiveValue() {
    if (!EasyLoading.isShow) {
      setState(() {
        receiveValue++;
      });
    }
  }

  void _decrementReceiveValue() {
    if (!EasyLoading.isShow) {
      if (receiveValue > returnValue) {
        setState(() {
          receiveValue--;
        });
      } else {
        EasyLoading.showInfo("ไม่สามารถรับน้อยกว่าจำนวนที่คืนได้", dismissOnTap: false, duration: const Duration(milliseconds: 1500));
      }
    }
  }

  void _incrementReturnValue() {
    if (!EasyLoading.isShow) {
      if (returnValue < receiveValue) {
        setState(() {
          returnValue++;
        });
      } else {
        EasyLoading.showInfo("ไม่สามารถคืนเกินจำนวนที่รับมาได้", dismissOnTap: false, duration: const Duration(milliseconds: 1500));
      }
    }
  }

  void _decrementReturnValue() {
    if (!EasyLoading.isShow) {
      if (returnValue > 0) {
        setState(() {
          returnValue--;
        });
      }
    }
  }

  void _startTimer(bool increment, bool isReceive) {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(milliseconds: 69), (timer) {
      if (EasyLoading.isShow) return;
      if (isReceive) {
        if (increment) {
          _incrementReceiveValue();
        } else {
          _decrementReceiveValue();
        }
      } else {
        if (increment) {
          _incrementReturnValue();
        } else {
          _decrementReturnValue();
        }
      }
    });
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _selectItem(String id, String itemName) {
    log("user picked : $id");
    setState(() {
      selectedItemId = id;
      selectedItemName = itemName;
    });
  }

  Future<void> _loadUserData() async {
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
    });
  }

  Future<void> _loadFoodLogData() async {
    EasyLoading.show();

    final result = await ApiCalling().checkIsSaveFoodLog(widget.par_busdata["queuedt_id"]);

    print(result);

    final resCode = result["resCode"];
    if (resCode == "2") {
      setState(() {
        selectedItemId = result["foodtype"];
        selectedItemName = result["foodname"];
        receiveValue = int.parse(result["receive"]);
        returnValue = int.parse(result["return"]);
      });
    } else {
      setState(() {
        selectedItemId = Commom().checkQTimeFood(widget.par_busdata["queue_time"]);
        _warningText = "เที่ยวเวลานี้ยังไม่ได้บันทึกการรับข้าวกล่อง";
      });
    }

    EasyLoading.dismiss();
  }

  @override
  void initState() {
    super.initState();

    _loadUserData();
    _loadFoodLogData();
  }

  @override
  void dispose() {
    super.dispose();
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 300,
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                children: items.map((item) {
                  return _buildSelectionButton(item['id']!, item['name']!, item['image']!);
                }).toList(),
              ),
            ),
            Text(_warningText, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            Text(
              'จำนวนรับ${selectedItemId.isNotEmpty ? items.firstWhere((item) => item['id'] == selectedItemId)['name'] : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            CounterWidget(
              count: receiveValue,
              onIncrement: _incrementReceiveValue,
              onDecrement: _decrementReceiveValue,
              onLongPressStart: (increment) => _startTimer(increment, true),
              onLongPressEnd: _stopTimer,
            ),
            const SizedBox(height: 40),
            Text(
              'จำนวนคืน${selectedItemId.isNotEmpty ? items.firstWhere((item) => item['id'] == selectedItemId)['name'] : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            CounterWidget(
              count: returnValue,
              onIncrement: _incrementReturnValue,
              onDecrement: _decrementReturnValue,
              onLongPressStart: (increment) => _startTimer(increment, false),
              onLongPressEnd: _stopTimer,
            ),
            const SizedBox(height: 25),
            const Text(
              "กดค้างที่ปุ่ม + - เพื่อปรับจำนวนอย่างรวดเร็ว",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                  onPressed: () {
                    saveData();
                  },
                  child: const Text(
                    'บันทึก',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }

  void saveData() async {
    log("ID : $selectedItemId | received : $receiveValue | returned : $returnValue");
    // EasyLoading.show();
    var saveFoodLog = ApiCalling().saveFoodLog(
        widget.par_busdata["queuedt_id"],
        widget.par_busdata["queue_busline"],
        widget.par_busdata["queue_buslinetype"],
        Commom().getYearFormString(widget.par_busdata["queue_send"]),
        widget.par_busdata["queue_time"],
        widget.par_busdata["queue_routename"],
        selectedItemId,
        selectedItemName,
        receiveValue.toString(),
        returnValue.toString(),
        _employee_id,
        _employee_name);
    dynamic result = await saveFoodLog;

    if (result["resCode"] == "1") {
      EasyLoading.showSuccess("บันทึกสำเร็จ");
      setState(() {
        _warningText = "";
      });
    } else {
      EasyLoading.showError("ไม่สามารถบันทึกได้\r\nโปรดลองอีกครั้ง");
    }
  }

  Widget _buildSelectionButton(String id, String name, String image) {
    bool isSelected = selectedItemId == id;
    return GestureDetector(
      onTap: () => _selectItem(id, name),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(3, 3), // changes position of shadow
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  "assets/$image",
                  fit: BoxFit.contain, // This ensures the image fits within its container.
                  width: double.infinity, // Ensure image takes full width of its container.
                  height: double.infinity, // Ensure image takes full height of its container.
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CounterWidget extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<bool> onLongPressStart;
  final VoidCallback onLongPressEnd;

  CounterWidget({
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: onDecrement,
          onLongPressStart: (_) => onLongPressStart(false),
          onLongPressEnd: (_) => onLongPressEnd(),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), backgroundColor: Colors.red.shade400),
            onPressed: onDecrement,
            child: const Icon(
              Icons.remove,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          width: 50,
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: onIncrement,
          onLongPressStart: (_) => onLongPressStart(true),
          onLongPressEnd: (_) => onLongPressEnd(),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), backgroundColor: Colors.green),
            onPressed: onIncrement,
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
