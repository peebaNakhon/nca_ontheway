import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Commom {
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

  dynamic updateDialog(BuildContext context, String currentVersion, UpdateData) {
    late String infomationText;
    late String updateContentText;
    late bool notForceUpdate = true;
    late String updateUrl = UpdateData["update_link"];
    if (UpdateData["current_version"] != currentVersion) {
      if (UpdateData["not_update_rules"]["enable"] == true) {
        String useUntil = UpdateData["not_update_rules"]["use_until"];
        DateTime finalDatetime = DateTime.parse(useUntil);

        DateTime currentDatetime = DateTime.now();

        String datetimeText = DateFormat("HH:mm:ss dd MMMM yyyy").format(finalDatetime);

        if (currentDatetime.isAfter(finalDatetime)) {
          infomationText = "มีการอัปเดตที่จำเป็น กรุณาอัปเดตแอปพลิเคชันเพื่อใช้งาน";
          notForceUpdate = false;
        } else {
          infomationText = "มีการอัปเดตที่จำเป็น คุณยังสามารถใช้งานเวอร์ชั่นปัจจุบันได้จนถึง $datetimeText เพื่อการใช้งานที่ต่อเนื่องโปรดอัปเดตก่อนเวลาดังกล่าว";
        }
      } else {
        infomationText = "มีการอัปเดตแอปพลิเคชัน โปรดอัปเดตเพื่อความต่อเนื่องในการใช้งาน";
      }
      updateContentText = UpdateData["update_content"];
    } else {
      Commom().showSnackBarNotificationSuccess(context, "คุณกำลังใช้แอปพลิเคชันเวอร์ชั่นล่าสุด ($currentVersion)", 3);
      return;
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text(
              'มีการอัปเดตแอปพลิเคชัน',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              // mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Divider(),
                Text(infomationText),
                Text("รายละเอียดการอัปเดต เวอร์ชั่น ${UpdateData['current_version']} :"),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(updateContentText),
                )
              ],
            ),
            actions: <Widget>[
              Visibility(
                visible: notForceUpdate,
                child: TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: Text(
                    'ภายหลัง',
                    style: TextStyle(color: Colors.redAccent.shade700),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(
                  'อัปเดต',
                  style: TextStyle(color: Colors.blueAccent.shade700),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _launchUrl(updateUrl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  String checkQTimeFood(String input) {
    try {
      // Parse the input time
      final time = DateFormat('HH:mm').parse(input);

      // Extract the hour
      final hour = time.hour;

      // Determine the output based on the hour
      if (hour >= 6 && hour <= 20) {
        return "1";
      } else {
        return "2";
      }
    } catch (e) {
      // Handle any parsing errors
      return "Invalid time format";
    }
  }

  Future<void> showSnackBarNotificationError(BuildContext context, String message, int seconds) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: seconds),
        backgroundColor: Colors.pinkAccent.shade400,
      ),
    );
  }

  Future<void> showSnackBarNotificationSuccess(BuildContext context, String message, int seconds) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: seconds),
        backgroundColor: Colors.green.shade400,
      ),
    );
  }

  List<dynamic> filterItemsByCategory(List<dynamic> items, String svitemid, bool isIncluded) {
    if (isIncluded) {
      return items.where((item) => item['svitemcat'] == svitemid).toList();
    } else {
      return items.where((item) => item['svitemcat'] != svitemid).toList();
    }
  }
}
