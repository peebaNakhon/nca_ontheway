// ignore_for_file: dead_code

import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiCalling {
  final apiEndpoint = 'https://www.nakhonchaiair.com/service/Service.php';
  // final menuSettingApi = 'http://192.168.100.240/rest/menuSetting.json';
  // final checkUpdateApi = 'http://192.168.100.240/rest/ncaotwv2.json';
  final menuSettingApi = 'http://61.91.248.21/nca_project/ncaotwv2/menuSetting.json';
  final checkUpdateApi = 'http://61.91.248.21/nca_project/ncaotwv2/ncaotwv2.json';
  final foodStatApi = 'http://192.168.100.240/nca_central_app/otwapi_food.php';

  //In House Parcel Save Received (GET TO BUS)
  Future<bool> saveReceived(id, busnumber, busline, buslinetype, quedate, quetime, empid) async {
    EasyLoading.show(status: 'รอซักครู่...');
    // print("id : $id");
    // print("busnumber : $busnumber");
    // print("busline : $busline");
    // print("buslinetype : $buslinetype");
    // print("quedate : $quedate");
    // print("quetime : $quetime");
    // print("empid : $empid");
    try {
      final response = await http.post(Uri.parse('https://www.nakhonchaiair.com/service/Service.php'),
          body: {'method': "saveReceived", 'id_data': id, 'busnumber': busnumber, 'busline': busline, 'buslinetype': buslinetype, 'quedate': quedate, 'quetime': quetime, 'empid': empid});

      final responseData = json.decode(response.body);
      // print(responseData);
      if (responseData[0]['success'] == 0) {
        EasyLoading.showError("พบข้อผิดพลาดขณะบันทึก\nโปรดลองอีกครั้ง", dismissOnTap: true, duration: const Duration(seconds: 3));
      }
      if (responseData[0]['success'] == 1) {
        EasyLoading.showSuccess('บันทึกสำเร็จ', dismissOnTap: true, duration: const Duration(seconds: 3));
      }
      return true;
    } catch (error) {
      // Handle network or other errors
      // print('An error occurred: $error');
      return false;
    }
  }

  //In House Parcel Save Send (Throw away parcels lol)
  Future<bool> saveSend(id, busnumber, busline, buslinetype, quedate, quetime, empid) async {
    EasyLoading.show(status: 'รอซักครู่...');
    // print("id : $id");
    // print("busnumber : $busnumber");
    // print("busline : $busline");
    // print("buslinetype : $buslinetype");
    // print("quedate : $quedate");
    // print("quetime : $quetime");
    // print("empid : $empid");
    try {
      final response = await http.post(Uri.parse('https://www.nakhonchaiair.com/service/Service.php'),
          body: {'method': "saveSend", 'id_data': id, 'busnumber': busnumber, 'busline': busline, 'buslinetype': buslinetype, 'quedate': quedate, 'quetime': quetime, 'empid': empid});

      final responseData = json.decode(response.body);
      // print(responseData);
      if (responseData[0]['success'] == 0) {
        EasyLoading.showError("พบข้อผิดพลาดขณะบันทึก\nโปรดลองอีกครั้ง", dismissOnTap: true, duration: const Duration(seconds: 3));
      }
      if (responseData[0]['success'] == 1) {
        EasyLoading.showSuccess('บันทึกสำเร็จ', dismissOnTap: true, duration: const Duration(seconds: 3));
      }
      return true;
    } catch (error) {
      // Handle network or other errors
      // print('An error occurred: $error');
      return false;
    }
  }

  Future<bool> ncaUpdsvitemRecieve(parSvitemqdt, parAmountrecieve) async {
    EasyLoading.show(status: 'รอซักครู่...');
    // print('parSvitemqdt : ${parSvitemqdt}');
    // print('parAmountrecieve : ${parAmountrecieve}');
    EasyLoading.dismiss();
    return true;
    try {
      final response = await http.post(Uri.parse('https://www.nakhonchaiair.com/service/Service.php'), body: {
        'method': "ncaUpdsvitemRecieve",
        'par_svitemqdt': parSvitemqdt,
        'par_amountrecieve': parAmountrecieve,
      });
      final responseData = json.decode(response.body);
      if (responseData[0]['is_update'] == 0) {
        return false;
      } else {
        return true;
      }
    } catch (error) {
      // Handle network or other errors
      // print('An error occurred: $error');
      return false;
    }
  }

  Future<bool> ncaUpdsvitemReturn(parSvitemqdt, parAmountreturn, pcRemark) async {
    EasyLoading.show(status: 'รอซักครู่...');
    // print('parSvitemqdt : ${parSvitemqdt}');
    // print('parAmountreturn : ${parAmountreturn}');
    // print('pcRemark : ${pcRemark}');
    EasyLoading.dismiss();
    return true;
    try {
      final response = await http.post(Uri.parse('https://www.nakhonchaiair.com/service/Service.php'),
          body: {'method': "ncaUpdsvitemReturn", 'par_svitemqdt': parSvitemqdt, 'par_amountreturn': parAmountreturn, 'pc_remark': pcRemark});
      final responseData = json.decode(response.body);
      if (responseData[0]['is_update'] == 0) {
        return false;
      } else {
        return true;
      }
    } catch (error) {
      // Handle network or other errors
      // print('An error occurred: $error');
      return false;
    }
  }

  Future<bool> ncaChkRefno(queuedt_id, refscan, empcode, updown_lat, updown_long, type_bussend) async {
    EasyLoading.show(status: 'รอซักครู่...');
    // print("Input RefNo : " + refscan);
    // print("Type ฺussend : " + type_bussend);
    try {
      final response = await http.post(
        Uri.parse('https://www.nakhonchaiair.com/service/Service.php'),
        body: {'method': 'ncaChkRefno', 'queuedt_id': queuedt_id, 'refscan': refscan, 'empcode': empcode, 'updown_lat': updown_lat, 'updown_long': updown_long, 'type_bussend': type_bussend},
      );

      final responseData = json.decode(response.body);
      // print(responseData);
      inspect(responseData);

      if (responseData[0]["scc_chkstatus"] == 0) {
        EasyLoading.showError("ไม่พบหมายเลขพัสดุนี้", duration: const Duration(seconds: 3));
        return false;
      } else if (responseData[0]["scc_chkstatus"] == 6) {
        EasyLoading.showSuccess("บันทึกสำเร็จ", duration: const Duration(seconds: 3));
        return true;
      } else {
        EasyLoading.showSuccess("บันทึกสำเร็จ", duration: const Duration(seconds: 3));
        return true;
      }
    } catch (error) {
      // Handle network or other errors
      EasyLoading.showError("พบข้อผิดพลาด\nโปรดลองใหม่อีกครั้ง", duration: const Duration(seconds: 3), dismissOnTap: true);
      // print('An error occurred: $error');
      return false;
    }
  }

  Future<bool> ncaGetTotalParcelUp(queuedt_id, pointid, pccount, empcd) async {
    EasyLoading.show(status: "รอซักครู่...");
    // print("----------ncaGetTotalParcelUp----------");
    // print("queuedt_id : ${queuedt_id}");
    // print("pointid : ${pointid}");
    // print("pccount : ${pccount}");
    // print("empcd : ${empcd}");

    try {
      final response = await http.post(
        Uri.parse('https://www.nakhonchaiair.com/service/Service.php'),
        body: {
          'method': 'ncaGetTotalParcelUp',
          'queuedt_id': queuedt_id,
          'pointid': pointid,
          'pccount': pccount,
          'empcd': empcd,
        },
      );

      final responseData = json.decode(response.body);

      // print(responseData);
      if (responseData[0]["result_st"] == 1) {
        EasyLoading.showSuccess("บันทึกสำเร็จ", duration: const Duration(seconds: 3));
        return true;
      } else if (responseData[0]["result_st"] == 2) {
        EasyLoading.showError("พัสดุเกิน จำนวน ${responseData[0]["result_pc"]} ชิ้น", duration: const Duration(seconds: 3));
        return false;
      } else if (responseData[0]["result_st"] == 3) {
        EasyLoading.showError("พัสดุขาด จำนวน ${responseData[0]["result_pc"]} ชิ้น", duration: const Duration(seconds: 3));
        return false;
      } else {
        EasyLoading.showError("พบข้อผิดพลาด");
      }
    } catch (error) {
      // Handle network or other errors
      EasyLoading.showError("พบข้อผิดพลาด\nโปรดลองใหม่อีกครั้ง", duration: const Duration(seconds: 2), dismissOnTap: false);
      // print('An error occurred: $error');
      return false;
    }
    return true;
  }

  Future<bool> ncaGetTotalParcelDown(queuedt_id, pointid, pccount, empcd) async {
    EasyLoading.show(status: "รอซักครู่...");
    // print("----------ncaGetTotalParcelUp----------");
    // print("queuedt_id : ${queuedt_id}");
    // print("pointid : ${pointid}");
    // print("pccount : ${pccount}");
    // print("empcd : ${empcd}");

    try {
      final response = await http.post(
        Uri.parse('https://www.nakhonchaiair.com/service/Service.php'),
        body: {
          'method': 'ncaGetTotalParcelDown',
          'queuedt_id': queuedt_id,
          'pointid': pointid,
          'pccount': pccount,
          'empcd': empcd,
        },
      );

      final responseData = json.decode(response.body);

      if (responseData[0]["result_st"] == 1) {
        EasyLoading.showSuccess("บันทึกสำเร็จ", duration: const Duration(seconds: 3));
        return true;
      } else if (responseData[0]["result_st"] == 2) {
        EasyLoading.showError("พัสดุเกิน จำนวน ${responseData[0]["result_pc"]} ชิ้น", duration: const Duration(seconds: 3));
        return false;
      } else if (responseData[0]["result_st"] == 3) {
        EasyLoading.showError("พัสดุขาด จำนวน ${responseData[0]["result_pc"]} ชิ้น", duration: const Duration(seconds: 3));
        return false;
      } else {
        EasyLoading.showError("พบข้อผิดพลาด");
      }
    } catch (error) {
      // Handle network or other errors
      EasyLoading.showError("พบข้อผิดพลาด\nโปรดลองใหม่อีกครั้ง", duration: const Duration(seconds: 2), dismissOnTap: false);
      // print('An error occurred: $error');
      return false;
    }
    return true;
  }

  // Future<void> _getTypeAccident() async {
  //   const String apiUrl = 'https://www.nakhonchaiair.com/service/Service.php';
  //   try {
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       body: {
  //         'method': 'Typeaccident',
  //       },
  //     );

  //     final responseData = json.decode(response.body);
  //   } catch (error) {
  //     // Handle network or other errors
  //     print('An error occurred: $error');
  //   }
  // }

  Future<List?> ncaGetGps(kn_latitude, kn_longitude, qtimedt) async {
    const String apiUrl = 'https://www.nakhonchaiair.com/service/Service.php';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'method': 'getLatLongpointbr', 'kn_latitude': kn_latitude, 'kn_longitude': kn_longitude, 'qtimedt': qtimedt},
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (error) {
      // Handle network or other errors
      // print('An error occurred: $error');
      return null;
    }
  }

  Future<List?> ncaSavegps(qtimedt, emp_id, kn_latitude, kn_longitude, kn_distance) async {
    const String apiUrl = 'https://www.nakhonchaiair.com/service/Service.php';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'method': 'saveLogPointbr', 'qtimedt': qtimedt, 'emp_id': emp_id, 'kn_latitude': kn_latitude, 'kn_longitude': kn_longitude, 'kn_distance': kn_distance},
      );

      final responseData = json.decode(response.body);
      return responseData;
    } catch (error) {
      // Handle network or other errors
      // print('An error occurred: $error');
      return null;
    }
  }

  Future<dynamic> checkIsSaveFoodLog(queuedt) async {
    String apiUrl = foodStatApi;
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'method': 'checkIsSaveFoodLog',
          'APIKEY': 'U2VjcmV0RGVlcEJsdWU=',
          'queuedt': queuedt,
        },
      );
      final responseData = json.decode(response.body);
      return responseData;
    } catch (error) {
      // Handle network or other errors
      print('An error occurred: $error');
      return null;
    }
  }

  Future<dynamic> saveFoodLog(queuedt, busline, buslinetype, queuedate, queuetime, routename, foodtype, foodname, foodReceive, foodReturn, userId, username) async {
    String apiUrl = foodStatApi;
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'method': 'saveFoodLog',
          'APIKEY': 'U2VjcmV0RGVlcEJsdWU=',
          'queuedt': queuedt,
          'busline': busline,
          'buslinetype': buslinetype,
          'queuetime': queuetime,
          'queuedate': queuedate,
          'routename': routename,
          'foodtype': foodtype,
          'foodname': foodname,
          'receive': foodReceive,
          'return': foodReturn,
          'userId': userId,
          'username': username
        },
      );
      final responseData = json.decode(response.body);
      return responseData;
    } catch (error) {
      // Handle network or other errors
      print('An error occurred: $error');
      return null;
    }
  }

  Future<List?> getMenuSetting() async {
    try {
      final response = await http.get(Uri.parse(menuSettingApi)).timeout(const Duration(seconds: 5));
      final responseData = json.decode(response.body);
      return responseData;
    } catch (error) {
      String jsonData = await rootBundle.loadString('assets/menuSetting.json');
      List<dynamic> data = json.decode(jsonData);
      return data;
    }
  }

  Future<Map> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(checkUpdateApi)).timeout(const Duration(seconds: 5));
      // final responseData = json.decode(response.body);
      String source = const Utf8Decoder().convert(response.bodyBytes);
      Map instance = json.decode(source);
      return instance;
    } catch (error) {
      log("Failed to check for update");
      print(error);
      const Map data = {"enable": false};
      return data;
    }
  }
}
