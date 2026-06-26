import 'dart:developer';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:nca_ontheway/class/Commom.dart';
import 'package:nca_ontheway/class/api_calling.dart';
import 'package:nca_ontheway/landingPage.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_player/video_player.dart';
// import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'NCA ON THE WAY',
        theme: ThemeData(useMaterial3: true, primaryColor: const Color.fromRGBO(53, 59, 64, 1), scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255), fontFamily: 'Prompt'),
        home: const LoginPage(),
        builder: EasyLoading.init());
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  
  // final updater = ShorebirdUpdater();
  // Patch? _currentPatch;
  // bool _updateAvailable = false;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool isLoading = false;
  String isNfcAvailable = '';
  Color _textColor = const Color.fromRGBO(168, 50, 50, 1);
  String _appVersion = "N/A";
  DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map deviceInfomation = {};

  late String MenuType = "";

  late dynamic MenuSettig = {};

  // late VideoPlayerController _controller;

  // late List<ConnectivityResult> connectivityResult;

  @override
  void initState() {
    super.initState();


    _getSystemInformation();
    _checkAppVersion();
    _checkNFCAvailable();
    _checkGPSAvailable();
    _loadMenuSettings();
    _loadSavedCredentials();
    EasyLoading.instance
      ..userInteractions = false
      ..displayDuration = const Duration(seconds: 2)
      ..maskType = EasyLoadingMaskType.black
      ..indicatorType = EasyLoadingIndicatorType.ring
      ..toastPosition = EasyLoadingToastPosition.bottom;

    // _controller = VideoPlayerController.asset('assets/ncaontheway.mp4',
    //     videoPlayerOptions: VideoPlayerOptions(
    //       mixWithOthers: true,
    //     ))
    //   ..initialize().then((_) {
    //     _controller.setVolume(0.0);
    //     _controller.play();
    //     _controller.setLooping(true);
    //   });

    FlutterNativeSplash.remove();


    //     updater.readCurrentPatch().then((patch) {
    //   setState(() => _currentPatch = patch);
    // });

    // // Check if an update is available to show in the UI.
    // updater.checkForUpdate().then((status) {
    //   setState(() => _updateAvailable = status == UpdateStatus.outdated);
    // });
    
  }

  void _checkAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // String appName = packageInfo.appName;
    // String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;
    setState(() {
      _appVersion = version;
    });
    // _checkForUpdates();
  }

  void _checkGPSAvailable() async {
    bool servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      log("GPS service is enabled");
    } else {
      log("GPS service is disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log('Location permissions are denied');
        EasyLoading.showError("ไม่พบสิทธิ์การใช้งาน GPS", dismissOnTap: false);
        await Future.delayed(const Duration(seconds: 3));
        SystemNavigator.pop();
      } else if (permission == LocationPermission.deniedForever) {
        log("'Location permissions are permanently denied");
        EasyLoading.showError("ไม่พบสิทธิ์การใช้งาน GPS\nกรุณาให้สิทธิ์เพื่อใช้งาน", dismissOnTap: false);
        await Future.delayed(const Duration(seconds: 5));
        SystemNavigator.pop();
      } else {
        log("GPS Location service is granted");
      }
    } else {
      log("GPS Location permission granted.");
    }
  }

  void _getSystemInformation() async {
    final deviceInfo = await deviceInfoPlugin.deviceInfo;
    // inspect(deviceInfo.data);
    // print(deviceInfo.data);
    // final allInfo = deviceInfo.data;
    // print(deviceInfo.runtimeType);\
    inspect(deviceInfo);
    setState(() {
      deviceInfomation = deviceInfo.data;
    });
    // inspect(deviceInfomation);
    //print(deviceInfomation);
  }

  _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      usernameController.text = prefs.getString('username') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', usernameController.text);
    prefs.setString('password', passwordController.text);
    prefs.setBool('rememberMe', rememberMe);
  }

  _removeCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    prefs.remove('password');
    prefs.remove('rememberMe');
  }

  _loadMenuSettings() async {
    log("_loadMenuSettings");
    var menuDataResult = await ApiCalling().getMenuSetting();
    inspect(menuDataResult);
    setState(() {
      MenuSettig = menuDataResult;
    });
  }

  _saveUserInformation(data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('employee_name', data["emp_fname"] + " " + data["emp_lname"]);
    prefs.setString('employee_type', data["emp_type"]);
    prefs.setString('employee_code', data["emp_code"]);
    prefs.setString('employee_id', data["emp_id"]);
    prefs.setString('employee_status', data["emp_status"]);
    prefs.setString('employee_pic', data["emp_pic"]);
    prefs.setString('rawUserData', data.toString());

    if (data["emp_type"] == "1") {
      prefs.setString('employee_typeName', data["emp_position"]);
      setState(() {
        MenuType = "showDriver";
      });
    } else if (data["emp_type"] == "2") {
      prefs.setString('employee_typeName', data["emp_position"]);
      setState(() {
        MenuType = "showCoach";
      });
    } else {
      prefs.setString('employee_typeName', data["emp_position"]);
      setState(() {
        MenuType = "etc";
      });
    }
  }

  void _checkNFCAvailable() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      isNfcAvailable = isAvailable ? "อุปกรณ์นี้รองรับ NFC" : "อุปกรณ์นี้ไม่รองรับ NFC";
      if (isAvailable) {
        _textColor = const Color.fromARGB(255, 32, 133, 56);
      }
    });
  }

  void _checkForUpdates() async {
    ConnectivityResult connectivityResult = await (Connectivity().checkConnectivity());
    var isConectToInternet = false;
    if (connectivityResult == ConnectivityResult.mobile) {
      // Mobile network available.
      log("ConnectivityResult.mobile");
      isConectToInternet = true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      log("ConnectivityResult.wifi");
      isConectToInternet = true;
      // Wi-fi is available.
      // Note for Android:
      // When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
    } else if (connectivityResult == ConnectivityResult.ethernet) {
      log("ConnectivityResult.ethernet");
      isConectToInternet = true;
    }

    // if (!isConectToInternet) {
    if (!isConectToInternet) {
      await Commom().showSnackBarNotificationError(context, 'ไม่พบการเชื่อมต่ออินเตอร์เน็ต\r\nกรุณาเชื่อมต่ออินเตอร์เน็ต\r\nและเปิดแอปพลิเคชั่นใหม่อีกครั้ง', 3);
      return;
    } else {
      await Commom().showSnackBarNotificationSuccess(context, 'กำลังตรวจสอบการอัปเดตแอปพลิเคชั่น...', 10);
    }
    final versionData = await ApiCalling().checkForUpdate();
    log("_checkForUpdates");
    inspect(versionData);
    _validateUpdates(versionData);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _validateUpdates(versionData) {
    log("_validateUpdates");
    log("appVersion: $_appVersion");
    inspect(versionData);
    log("_validateUpdates");
    Commom().updateDialog(context, _appVersion, versionData);
  }

  void _showErrorDialog(String message) {
    EasyLoading.dismiss();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('แจ้งเตือน'),
          content: Text(message),
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
  }

  void _login() async {
    setState(() {
      isLoading = true;
    });

    final String username = usernameController.text;
    final String password = passwordController.text;

    if (username.isEmpty) {
      _showErrorDialog('กรุณากรอกรหัสพนักงาน');
      setState(() {
        isLoading = false;
      });

      return;
    }

    const String apiUrl = 'https://www.nakhonchaiair.com/service/Service.php';
    EasyLoading.show(status: 'รอซักครู่...');
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'method': 'ncalogin', 'paruser': username, 'parpassword': password},
      );

      inspect(response);

      // print(json.decode(response.body));
      final convertedData = json.decode(response.body);

      final Map<String, dynamic> data = convertedData;
      // Assuming your API returns a 'resCode' in the JSON response
      if (data.containsKey('emp_fname') && data["emp_type"] != null) {
        // String resCode = data['resCode'];

        // print(data);

        await _saveUserInformation(data);
        _onLoginSuccess();
        EasyLoading.dismiss();

        // if (resCode == "1") {
        //   _saveUserInformation(data);
        //   _onLoginSuccess();
        // } else if (resCode == "2") {
        //   // Login failed
        //   _showErrorDialog('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
        // } else {
        //   // API error
        //   _showErrorDialog(
        //       'API error. Please try again later. Error code: $resCode');
        // }
      } else {
        EasyLoading.dismiss();
        // Handle missing 'resCode' in the response
        _showErrorDialog('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
        // _showErrorDialog('Invalid API response.');
      }
    } catch (error) {
      // Handle network or other errors
      EasyLoading.dismiss();
      log("ERROR");
      log('An error occurred: $error');
      _showErrorDialog('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ โปรดตรวจสอบการเชื่อมต่ออินเตอร์เน็ตและลองใหม่อีกครั้ง');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onLoginSuccess() {
    if (rememberMe) {
      _saveCredentials();
    } else {
      _removeCredentials();
    }
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => LandingPage(
          menuType: MenuType,
          menuSeting: MenuSettig,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video Background
        // if (_controller.value.isInitialized)
        //   SizedBox.expand(
        //     child: FittedBox(
        //       fit: BoxFit.cover,
        //       child: SizedBox(
        //         width: _controller.value.size.width,
        //         height: _controller.value.size.height,
        //         child: VideoPlayer(_controller),
        //       ),
        //     ),
        //   ),
        // Overlay content
        SafeArea(
          child: Scaffold(
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
            body: SingleChildScrollView(
                child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 30, 30, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Image(
                      image: AssetImage('assets/welcomeImage-01.png'),
                      height: 300,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ON THE WAY',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'รหัสพนักงาน'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Visibility(
                      visible: false,
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text("จำรหัสพนักงาน"),
                      value: rememberMe,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'เข้าสู่ระบบ',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        "v$_appVersion",
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Build : 08052025R1",
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.normal, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // const Center(
                    //   child: Text(
                    //     "Please connect to NCA_Staff or NCA_VIP WiFi\nTo Login and use this app",
                    //     style: TextStyle(fontSize: 12, color: Colors.red),
                    //     textAlign: TextAlign.center,
                    //   ),
                    // ),
                  ],
                ),
              ),
            )),
          ),
        ),
      ],
    );
  }
}
