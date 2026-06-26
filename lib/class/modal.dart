import 'package:flutter/material.dart';

class modal {
  Future<bool> showNotSaveDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('แจ้งเตือน'),
              content: const Text(
                  'คุณยังไม่ได้บันทึกข้อมูล ต้องการออกจากหน้านี้หรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // User doesn't want to logout
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
}
