// nfcReader.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nca_ontheway/landingPage.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'webView.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NFCReaderPage extends StatefulWidget {
  const NFCReaderPage({super.key});

  @override
  State<NFCReaderPage> createState() => _NFCReaderPageState();
}

class _NFCReaderPageState extends State<NFCReaderPage> {
  final String _displayText = 'ขยับอุปกรณ์ของคุณให้อยู่ใกล้ NFC Tag';
  String _waringText = '';
  final String _TagData = "";
  Color _textColor = const Color.fromRGBO(168, 50, 50, 1);
  late String _stf = "";
  late String _staffId = "";
  late String _userdspms = "";
  late String _busNumber = "";
  late String _busPosition = "";
  late String _lat = "";
  late String _long = "";
  late bool isUsed = false;

  late String _employee_name = "";
  late String _employee_type = "";
  late String _employee_code = "";
  late String _employee_id = "";
  late String _employee_status = "";

  ValueNotifier<dynamic> result = ValueNotifier(null);

  Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  LatLng _userPosition = LatLng(0, 0);

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(13.736717, 100.523186),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    // _showNFCAvailable();
    _loadUserData();
    _initNFC();
  }

  Future<void> _initNFC() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (isAvailable) {
      try {
        NfcManager.instance.startSession(
          onDiscovered: (NfcTag tag) async {
            if (isUsed) {
              return;
            }
            setState(() {
              isUsed = true;
            });
            EasyLoading.show(status: 'กำลังอ่าน NFC');
            // Read tag data here
            setState(() {
              result.value = tag.data;
            });
            // print(tag);
            inspect(tag);
            Map tagData = tag.data;
            Map tagNdef = tagData['ndef'];
            Map cachedMessage = tagNdef['cachedMessage'];
            Map records = cachedMessage['records'][0];
            Uint8List payload = records['payload'];
            String payloadAsString = String.fromCharCodes(payload);

            // var nfcTagPayload = tag.data["ndef"]["cachedMessage"]["records"][0]["payload"];
            // String stringPayloadDecode = String.fromCharCodes(nfcTagPayload);

            Map<String, String> parameters = _extractUrlParameters(payloadAsString);

            // print('Extracted parameters: $parameters');

            _sendDataToApi(parameters);
          },
        );
        setState(() {
          _waringText = "พร้อม";
          _textColor = Colors.green;
        });
        // EasyLoading.showSuccess('NFC is Available');
      } catch (e) {
        EasyLoading.showError('Error initializing NFC : $e');
        // print('Error initializing NFC: $e');
      }
    } else {
      // Handle the case when NFC is not available
      setState(() {
        _waringText = "อุปกรณ์นี้ไม่รองรับ NFC";
      });
    }
  }

  Map<String, String> _extractUrlParameters(String url) {
    Uri uri = Uri.parse(url.replaceAll('+', '%2B'));

    // Extract parameters from the URI
    Map<String, String> parameters = {};
    uri.queryParameters.forEach((key, value) {
      // Replace '+' with '%2B' to preserve it
      String decodedValue = Uri.decodeComponent(value);
      parameters[key] = decodedValue;
    });

    return parameters;
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
    });
  }

  void _sendDataToApi(nfcData) async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    // print(position.latitude);
    // print(position.longitude);

    String long = position.longitude.toString();
    String lat = position.latitude.toString();
    _goToUserPosition(lat, long);
    // API ENDPOINT
    const String apiUrl = 'http://192.1.1.240/ncaqc/ncaqc_api.php';
    var url = Uri.parse(apiUrl);
    var response = await http.post(
      url,
      body: {
        'APIKEY': 'U2VjcmV0RGVlcEJsdWU=',
        'method': 'checkQC',
        'par_busnumber': nfcData["par_busnumber"],
        'par_busposition': nfcData["par_busposition"],
        'par_user': _employee_code,
        'par_userId': _employee_id,
        'par_username': _employee_name,
        'latitude': lat,
        'longitude': long
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      log("OK!");
      // print(data);
      setState(() {
        _busNumber = data["par_busnumber"];
        _busPosition = data["par_busposition"];
        _lat = lat;
        _long = long;
        _userPosition = LatLng(double.parse(lat), double.parse(long));
      });
      showQCInfomation(data["par_busnumber"], data["par_busposition"], lat, long);
    } else {
      EasyLoading.showError('ERROR, something error happened. Status code: ${response.statusCode}');
    }
  }

  void _sendDataToApiFake() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    // print(position.latitude);
    // print(position.longitude);

    String long = position.longitude.toString();
    String lat = position.latitude.toString();

    _goToUserPosition(lat, long);
    // API ENDPOINT
    const String apiUrl = 'http://192.1.1.240/ncaqc/ncaqc_api.php';
    var url = Uri.parse(apiUrl);
    var response = await http.post(
      url,
      body: {
        'APIKEY': 'U2VjcmV0RGVlcEJsdWU=',
        'method': 'checkQC',
        'par_busnumber': '587-102-BS+',
        'par_busposition': '1',
        'par_user': _stf,
        'par_userId': _staffId,
        'par_username': _userdspms,
        'latitude': lat,
        'longitude': long
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      log("OK!");
      // print(data);
      setState(() {
        _busNumber = data["par_busnumber"];
        _busPosition = data["par_busposition"];
        _lat = lat;
        _long = long;
        _userPosition = LatLng(double.parse(lat), double.parse(long));
      });
      showQCInfomation(data["par_busnumber"], data["par_busposition"], lat, long);
    } else {
      EasyLoading.showError('ERROR, something error happened. Status code: ${response.statusCode}');
    }
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('แจ้งเตือน'),
              content: const Text('ย้อนกลับหรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User doesn't want to logout
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

  Future<void> openWebView() async {
    // String url = "http://192.1.1.240/ncaqc/form.php?action=qc&par_busnumber=$_busNumber&par_busPosition=$_busPosition";
    String url =
        "https://ee.kobotoolbox.org/single/pOg6TZ7S?d[_busnumber]=$_busNumber&d[_busposition]=$_busPosition&d[_lat]=$_lat&d[_long]=$_long&return_url=http://192.1.1.240/ncaqc/missionComplete.php";
    log(url);
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => WebViewPage(url: url, tabName: "QC TAB")),
    );
  }

  Future<void> _goToUserPosition(String lat, String long) async {
    CameraPosition userPosition = CameraPosition(bearing: 0, target: LatLng(double.parse(lat), double.parse(long)), tilt: 0, zoom: 17);
    GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(userPosition));
  }

  Future<void> showQCInfomation(String busNumber, String busPosition, String lat, String long) async {
    EasyLoading.dismiss();
    showModalBottomSheet(
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      context: context,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Text(
                      "แจ้งเตือน",
                      style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 150,
                      color: Colors.green,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(2),
                    child: Text(
                      "บันทึกสำเร็จ",
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text("เบอร์รถ : $busNumber"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text("ตำแหน่ง : $busPosition"),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.all(20),
                  //   child: Text("Lat : $lat Long : $long"),
                  // ),
                  Column(
                    children: [
                      const Padding(padding: EdgeInsets.all(5)),
                      SizedBox(
                        height: 275, // Set a finite height for the GoogleMap
                        child: GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: _kGooglePlex,
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                            },
                            markers: <Marker>{
                              Marker(
                                markerId: const MarkerId('userPosition'),
                                position: _userPosition,
                                infoWindow: InfoWindow(
                                  title: 'ตำแหน่งของคุณ',
                                  snippet: 'Lat: ${_userPosition.latitude}, Lng: ${_userPosition.longitude}',
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            }),
                      ),
                      const Padding(padding: EdgeInsets.all(5)),
                      SizedBox(
                        width: 300,
                        child: TextButton(
                          onPressed: () {
                            openWebView();
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green, shadowColor: const Color.fromRGBO(184, 255, 184, 0.498)),
                          child: const Text("OK"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      log("user swipe down or click on the back button");
      _controller = Completer();
      setState(() {
        isUsed = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // bool logoutConfirmed = await _showLogoutConfirmationDialog(context);
        bool logoutConfirmed = true;
        // print(logoutConfirmed);
        if (logoutConfirmed) {
          Navigator.of(context).pop(true);
        }
        return Future.value(logoutConfirmed);
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('NCA QC'),
            leading: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.of(context).pop(true);
                // Show logout confirmation dialog when back arrow is pressed
                // _showLogoutConfirmationDialog(context).then(
                //   (logoutConfirmed) {
                //     if (logoutConfirmed) {
                //       // Navigate back to the login page and remove NFCReaderPage from the stack
                //       Navigator.pushAndRemoveUntil(
                //         context,
                //         CupertinoPageRoute(
                //             builder: (context) => const LandingPage()),
                //         (route) => false,
                //       );
                //     }
                //   },
                // );
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image.network(
                //   'http://192.1.1.240/ncaqc/img/nfcmove.gif',
                //   width: 250,
                // ),
                const Image(
                  image: AssetImage('assets/nfcmove.gif'),
                  height: 250,
                ),
                const SizedBox(height: 0),
                // const Text(
                //   'NFC Tags Reader',
                //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                // ),
                const SizedBox(height: 10),
                Text(
                  _displayText,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  _waringText,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor),
                ),
                const SizedBox(height: 10),
                const Text(
                  "*ตำแหน่งการอ่าน NFC อาจแตกต่างกันตามแต่ละอุปกรณ์",
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // SizedBox(
                //   height: 20,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       EasyLoading.show(status: 'รอซักครู่...');
                //       _sendDataToApiFake();
                //     },
                //     child: const Text('NFC Simulator'),
                //   ),
                // ),
                const SizedBox(height: 50),
                const Divider(),
                const SizedBox(height: 5),
                const Icon(Icons.account_circle),
                const Text("ข้อมูลผู้ใช้งาน", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("รหัสพนักงาน : $_employee_code"),
                Text("ชื่อ : $_employee_name")
              ],
            ),
          ),
        ),
      ),
    );
  }
}
