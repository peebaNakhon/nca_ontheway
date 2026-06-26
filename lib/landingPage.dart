import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:nca_ontheway/Parcels.dart';
import 'package:nca_ontheway/Parcelservice/FoodSevive2.dart';
import 'package:nca_ontheway/Parcelservice/ParcelServiceDown.dart';
import 'package:nca_ontheway/Parcelservice/ParcelServiceUp.dart';
import 'package:nca_ontheway/Parcelservice/FoodService.dart';
import 'package:nca_ontheway/QRCodePage.dart';
import 'package:nca_ontheway/main.dart';
import 'package:nca_ontheway/nfcReader.dart';
import 'package:nca_ontheway/transportation/Checkpoint.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'webView.dart';
import 'webViewSell.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'OilUseReport.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class LandingPage extends StatefulWidget {
  final dynamic menuType;
  final List menuSeting;

  const LandingPage({super.key, this.menuType, required this.menuSeting});

  // static final title = 'salomon_bottom_bar';

  @override
  State<LandingPage> createState() => _LandingPage();
}

class _LandingPage extends State<LandingPage> with RouteAware, WidgetsBindingObserver {
  var _currentIndex = 3;

  bool isLoading = false;

  late String _employee_name = "";
  late String _employee_type = "";
  late String _employee_code = "";
  late String _employee_id = "";
  late String _employee_status = "";
  late String _employee_typeName = "";
  late String _employee_pic = "https://cdn-icons-png.flaticon.com/512/219/219983.png";

  late List userQ = [];

  late Map<String, dynamic> _userBusQ = {};
  late String _busCodeText = "เลือกเที่ยวรถ";
  late String _busTime = "";
  late String _busDate = "";
  late String _exitPath = "";

  String _appVersion = "N/A";

  late String _typeAccident = "";

  final TextStyle queInfoTextStyle = const TextStyle(fontFamily: 'Prompt', color: Colors.black, fontSize: 17.0);

  late bool isBottomSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _showNFCAvailable();
    _checkAppVersion();
    _loadUserData();
    _readAccprevent();
  }

  void _setSystemUIOverlayStyle() async {
    await Future.delayed(const Duration(milliseconds: 100));
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Color.fromARGB(255, 34, 35, 99),
        systemNavigationBarColor: Color.fromARGB(255, 34, 35, 99),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    _setSystemUIOverlayStyle();
  }

  @override
  void didPopNext() {
    // Called when this page is shown again after a "push back"
    _setSystemUIOverlayStyle();
  }

  @override
  void dispose() {
    EasyLoading.dismiss();
    routeObserver.unsubscribe(this);
    super.dispose();
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
  }

  Future<void> _loadUserData() async {
    // EasyLoading.show(status: 'รอซักครู่...');
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
      _employee_pic = prefs.getString("employee_pic")!;
    });

    log("employee_id : $_employee_id");
    log("employee_type : $_employee_type");
    log("employee_pic : $_employee_pic");
    log("employee_code : $_employee_code");

    // print(prefs.getString("rawUserData"));

    // await _getQueue();
    if (_userBusQ.isEmpty) {
      log("empty!");
      // ignore: use_build_context_synchronously
      // selectBus(context);
      setState(() {
        _busCodeText = "ไม่ได้เลือกเที่ยวรถ";
      });
    }
    EasyLoading.dismiss();
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('แจ้งเตือน'),
              content: const Text('ต้องการออกจากระบบหรือไม่?'),
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

  Future<void> _showExitPathInfomationDialog(BuildContext context, String exitPath) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('โปรดทราบ'),
          content: Text("รถเที่ยวนี้ออกจากอู่ กท. ให้ใช้ทางออก\r\n$exitPath"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('รับทราบ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> openWebView(String url, String tabName) async {
    log(url);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => WebViewPage(url: url, tabName: tabName),
      ),
    );
  }

  Future<void> openWebViewSellItem(String url, String tabName) async {
    log(url);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => WebViewSellPage(url: url, tabName: tabName),
      ),
    );
  }

  void movePage(int pageInt) {
    log(pageInt.toString());
    setState(() {
      _currentIndex = pageInt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool logoutConfirmed = await _showLogoutConfirmationDialog(context);
        // print(logoutConfirmed);
        if (logoutConfirmed) {
          // ignore: use_build_context_synchronously
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
        return Future.value(logoutConfirmed);
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey.shade200,
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 34, 35, 99),
            surfaceTintColor: Colors.transparent,
            title: Text(
              _busCodeText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18.5, color: Colors.white),
            ),
            centerTitle: true,
            bottom: PreferredSize(
                preferredSize: Size.zero,
                child: Text(
                  "$_busDate $_busTime",
                  style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14.5, color: Colors.white),
                )),
            automaticallyImplyLeading: false,
            // actions: [
            //   IconButton(onPressed: () {}, icon: const Icon(Icons.list_rounded))
            // ],
            // leading: IconButton(
            //   icon: const Icon(Icons.logout),
            //   onPressed: () {
            //     // Show logout confirmation dialog when back arrow is pressed
            //     _showLogoutConfirmationDialog(context).then((logoutConfirmed) {
            //       if (logoutConfirmed) {
            //         // Navigate back to the login page and remove NFCReaderPage from the stack
            //         Navigator.pushAndRemoveUntil(
            //           context,
            //           CupertinoPageRoute(builder: (context) => const LoginPage()),
            //           (route) => false,
            //         );
            //       }
            //     });
            //   },
            // ),
          ),
          body: _buildMenu(),
          bottomNavigationBar: SalomonBottomBar(
            backgroundColor: Color.fromARGB(255, 34, 35, 99),
            margin: const EdgeInsets.all(5),
            itemPadding: const EdgeInsets.all(10),
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() {
                _currentIndex = i;
                // print(_currentIndex);
              });
            },
            items: [
              /// Home
              SalomonBottomBarItem(
                icon: Tab(
                  height: 24,
                  icon: Image.asset(
                    "assets/bmenu/b11.png",
                  ),
                ),
                title: const Text(
                  "หน้าแรก",
                  style: TextStyle(fontFamily: 'Prompt'),
                ),
                selectedColor: Colors.white,
              ),

              /// Service Production
              SalomonBottomBarItem(
                icon: Tab(
                  height: 24,
                  icon: Image.asset(
                    "assets/bmenu/b22.png",
                  ),
                ),
                title: const Text(
                  "ของบริการ",
                  style: TextStyle(fontFamily: 'Prompt'),
                ),
                selectedColor: Colors.white,
              ),

              /// Parcel
              SalomonBottomBarItem(
                icon: Tab(
                  height: 24,
                  icon: Image.asset(
                    "assets/bmenu/b3.png",
                  ),
                ),
                title: const Text(
                  "พัสดุ",
                  style: TextStyle(fontFamily: 'Prompt'),
                ),
                selectedColor: Colors.white,
              ),
              SalomonBottomBarItem(
                icon: Tab(
                  height: 24,
                  icon: Image.asset(
                    "assets/bmenu/b6.png",
                  ),
                ),
                title: const Text(
                  "ผู้ใช้งาน",
                  style: TextStyle(fontFamily: 'Prompt'),
                ),
                selectedColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildMenu() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeMenu();
      case 1:
        if (_userBusQ.isEmpty) {
          EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
          setState(() {
            _currentIndex = 3;
          });
          return _buildUserPage();
        }
        return _buildServiceParcelMenu();
      case 2:
        if (_userBusQ.isEmpty) {
          EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
          setState(() {
            _currentIndex = 3;
          });
          return _buildUserPage();
        }
        // return _buildParcelMenu();
        return _buildAllParcelsInOnePage();
      // case 3:
      //   if (_userBusQ.isEmpty) {
      //     EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน",
      //         duration: const Duration(milliseconds: 1500), dismissOnTap: true);
      //     setState(() {
      //       _currentIndex = 3;
      //     });
      //     return _buildUserPage();
      //   }
      //   return _buildInHouseParcelMenu();
      // case 3:
      //   // Navigate to scanPage
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     Navigator.push(
      //       context,
      //       CupertinoPageRoute(builder: (context) => const NFCReaderPage()),
      //     );
      //   });
      //   return Container(); // Return an empty container temporarily as we navigate
      case 3:
        return _buildUserPage();
      default:
        return Container();
    }
  }

  Widget _buildHomeMenu() {
    return ListView(
      children: [
        if (_exitPath != "")
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
            child: SizedBox(
              height: 45,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: Colors.redAccent.shade700,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Centers the content horizontally
                    children: [
                      const Icon(Icons.warning, color: Colors.white), // Add the icon you want
                      const SizedBox(width: 8), // Add some spacing between the icon and text
                      Text(
                        _exitPath,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 5),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
          primary: false,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: [
            if (widget.menuSeting[0][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu1.png',
                name: 'จุดจอดรถ',
                description: 'Passing Point',
                isShow: true,
                imageHeight: 0.175,
                color: Colors.white,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    openWebView(
                        "http://203.151.125.244/ncaprj/nca_project/appchecklog/view/mpoint1.php?method=ncaGetPoint&plan=${_userBusQ["queue_plan"]}&qdttime=${_userBusQ["queue_time"]}&qttimeid=${_userBusQ["queuedt_id"]}&userid=$_employee_id&code=$_employee_code&plat=and",
                        "จุดจอดรถ");
                  }
                },
              ),
            if (widget.menuSeting[1][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu2.png',
                name: 'คูปองส่วนลด',
                description: 'Coupons',
                isShow: true,
                imageHeight: 0.175,
                color: Colors.white,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    openWebView("http://203.151.125.244/ncaprj/nca_project/appchecklog/view/v_gifcet.php?qtime=${_userBusQ["queuedt_id"]}&dspname=$_employee_name&dspid=$_employee_id", "คูปองส่วนลด");
                  }
                },
              ),
            if (widget.menuSeting[2][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu3.png',
                name: 'ผังที่นั่ง',
                description: 'Seat Maps',
                isShow: true,
                color: Colors.white,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                imageHeight: 0.175,
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    openWebView("http://203.151.125.244/ncaprj/nca_project/nca_project/mpointhtml/products1.php?user=$_employee_code&qtime=${_userBusQ["queuedt_id"]}&plan=${_userBusQ["queue_plan"]}",
                        "รายละเอียดผังที่นั่ง");
                  }
                },
              ),
            if (widget.menuSeting[3][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu4.png',
                name: 'ตรวจสภาพรถ',
                description: 'Vehicle inspection',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    openWebView("http://203.151.125.244/ncaprj/nca_project/nca_project/mpointhtml/carebus.php?user=$_employee_code&qtimedt=${_userBusQ["queuedt_id"]}", "ตรวจสภาพรถ");
                  }
                },
              ),
            if (widget.menuSeting[4][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu5.png',
                name: 'การแจ้งซ่อม',
                description: 'Repairs',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    openWebView(
                        "http://61.91.248.18/mms/ncaprj_formms/nca_project/nca_project/mpointhtml/mainternance.php?kn_user=$_employee_id&empst=$_employee_status&qtimedt=${_userBusQ["queuedt_id"]}",
                        "การแจ้งซ่อม");
                  }
                },
              ),
            if (widget.menuSeting[5][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu6.png',
                name: 'อบรม วันหยุด',
                description: 'Meeting, Leave',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  openWebView("http://61.91.248.20/ncaprj/nca_project/ncacalendarleva/view/example-page.php?code=$_employee_code&emp=$_employee_id", "ตารางอบรม/วันหยุด");
                },
              ),
            if (widget.menuSeting[6][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu7.png',
                name: 'รายการที่ต้องทำ',
                description: 'To-do List',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    openWebView("http://203.151.125.244/ncaprj/nca_project/nca_project/mpointhtml/needlist.php?planid=${_userBusQ["queue_plan"]}&qtimedt=${_userBusQ["queuedt_id"]}", "รายการที่ต้องทำ");
                  }
                },
              ),
            if (widget.menuSeting[7][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu8.png',
                name: 'ประวัติแจ้งซ่อม',
                description: 'To-do List',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    openWebView("http://61.91.248.18/mms/report/project/frm_rpt_prj_forapp.php?busno=${Uri.encodeComponent(_userBusQ["queue_busnumber"])}", "ประวัติรายการแจ้งซ่อม");
                  }
                },
              ),
            if (widget.menuSeting[8][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu9.png',
                name: 'ค่าสถานี ทางด่วน',
                description: 'Station',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    openWebView("http://203.151.125.244/ncaprj/nca_project/appchecklog/view/vstationx.php?qtimedtx=${_userBusQ["queuedt_id"]}", "ค่าสถานนี ค่าทางด่วน");
                  }
                },
              ),
            if (widget.menuSeting[9][widget.menuType] && false)
              // ignore: dead_code
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu10.png',
                name: 'ลงชื่อจุดเปลี่ยนพ่วง',
                description: 'Checkpoint',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  // print('ลงชื่อจุดเปลี่ยนพ่วง');
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (context) => Checkpoint(par_busdata: _userBusQ)),
                    );
                  }
                },
              ),
            if (widget.menuSeting[10][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu11.png',
                name: 'คู่มือป้องกันอุบัติเหตุ',
                description: 'Accident',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  openWebView("http://203.151.125.244/ncaprj/nca_project/appchecklog/view/otw_accmanual.php", "คู่มือป้องกันอุบัติเหตุ");
                },
              ),
            if (false)
              // ignore: dead_code
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu14.png',
                name: 'QR Code',
                description: 'Bus\'s QR Code',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (context) => QRCodePage(par_busdata: _userBusQ)),
                    );
                  }
                },
              ),
            // if (widget.menuSeting[12][widget.menuType])
            if (false == widget.menuSeting[13][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/welcomeImage.png',
                name: 'ประวัติการเข้าคิว',
                description: 'Shift History',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  EasyLoading.showInfo("Not Available yet.");
                },
              ),
            // if (widget.menuSeting[13][widget.menuType])
            if (false == widget.menuSeting[13][widget.menuType])
              // ignore: dead_code
              createCardWithBool(
                imagePath: 'assets/bmenu/b5.png',
                name: 'NFC',
                description: 'NCA\'s QC',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const NFCReaderPage()),
                      );
                    });
                  }
                },
              ),
            if (true)
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu15.png',
                name: 'จำหน่ายสินค้า',
                description: 'Sell Items',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  //Todo : change url to production
                  if (_userBusQ.isEmpty) {
                    late String url =
                        "http://61.91.248.21/ncasellonbus/view/link_ncaotwsellitem.php?nca_mpid=$_employee_id&nca_avatar=$_employee_pic&nca_code=$_employee_code&nca_fname=$_employee_name&nca_type=$_employee_type";
                    openWebViewSellItem(url, "จำหน่ายสินค้าบนรถ");
                  } else {
                    RegExp dateRegex = RegExp(r'\b\d{2}/\d{2}/\d{2}\b');
                    String extractedDate = dateRegex.stringMatch(_userBusQ["queue_send"]) ?? '';
                    late String url =
                        "http://61.91.248.21/ncasellonbus/view/link_ncaotwsellitem.php?queue_busline=${_userBusQ["queue_busline"]}&queue_buslinetype=${_userBusQ["queue_buslinetype"]}&queue_busnumber=${Uri.encodeComponent(_userBusQ["queue_busnumber"])}&queue_date=$extractedDate&queue_plan=${_userBusQ["queue_plan"]}&queue_routeid=${_userBusQ["route_id"]}&queue_routename=${_userBusQ["queue_routename"]}&queue_time=${_userBusQ["queue_time"]}&queuedt_id=${_userBusQ["queuedt_id"]}&nca_mpid=$_employee_id&nca_avatar=$_employee_pic&nca_code=$_employee_code&nca_fname=$_employee_name&nca_type=$_employee_type";
                    openWebViewSellItem(url, "จำหน่ายสินค้าบนรถ");
                  }
                },
              ),
            if (true)
              // ignore: dead_code
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu16.png',
                name: 'การใช้น้ำมัน',
                description: 'Oil Use',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  }
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => OilUseReport(
                        data_oiluse: _userBusQ["is_oildft"],
                        data_busnumber: _userBusQ["queue_busnumber"],
                      ),
                    ),
                  );
                },
              ),
            if (widget.menuSeting[14][widget.menuType])
              createCardWithBool(
                imagePath: 'assets/homeIcon/menu13.png',
                name: 'อื่นๆ',
                description: 'Other',
                isShow: true,
                color: Colors.white,
                imageHeight: 0.175,
                textColor: Colors.black,
                cardBorder: BorderSide(color: Colors.blueAccent.shade400, width: 0.5),
                onTap: () {
                  if (_userBusQ.isEmpty) {
                    EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1500), dismissOnTap: true);
                    return;
                  } else {
                    RegExp dateRegex = RegExp(r'\b\d{2}/\d{2}/\d{2}\b');
                    String extractedDate = dateRegex.stringMatch(_userBusQ["queue_send"]) ?? '';
                    late String url =
                        "http://61.91.248.21/nca_project/nca_bos/qassesstopicemp/index.php?queue_busline=${_userBusQ["queue_busline"]}&queue_buslinetype=${_userBusQ["queue_buslinetype"]}&queue_busnumber=${Uri.encodeComponent(_userBusQ["queue_busnumber"])}&queue_date=$extractedDate&queue_plan=${_userBusQ["queue_plan"]}&queue_routeid=${_userBusQ["route_id"]}&queue_routename=${_userBusQ["queue_routename"]}&queue_time=${_userBusQ["queue_time"]}&queuedt_id=${_userBusQ["queuedt_id"]}&nca_mpid=$_employee_id&nca_avatar=$_employee_pic&nca_code=$_employee_code&nca_fname=$_employee_name&nca_type=$_employee_type";
                    openWebView(url, "อื่นๆ");
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceParcelMenu() {
    return ListView(
      children: [
        const Padding(
          padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
          child: Text(
            "ของบริการ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          padding: const EdgeInsets.all(5),
          primary: true,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: [
            createCardWithBool(
              name: 'รับของบริการบนรถ',
              description: 'Recieve Service Items',
              color: Colors.deepPurple.shade400,
              imagePath: 'assets/food_up.png',
              imageHeight: 0.3,
              isShow: true,
              textColor: Colors.white,
              cardBorder: BorderSide(color: Colors.deepPurple.shade400, width: 0),
              onTap: () {
                openServicePage('SPRecieve', 'รับของบริการบนรถ', 'ServiceItems');
              },
            ),
            createCardWithBool(
              name: 'คืนของบริการบนรถ',
              description: 'Return Service Items',
              color: Colors.deepPurple.shade400,
              imagePath: 'assets/food_down.png',
              imageHeight: 0.3,
              isShow: true,
              textColor: Colors.white,
              cardBorder: BorderSide(color: Colors.deepPurple.shade400, width: 0),
              onTap: () {
                openServicePage('SPReturn', 'คืนของบริการบนรถ', 'ServiceItems');
              },
            ),
          ],
        ),
        // const Divider(
        //   color: Colors.black,
        // ),
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Text(
            "สินค้าจำหน่าย",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          padding: const EdgeInsets.all(5),
          primary: true,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: [
            createCardWithBool(
              name: 'รับสินค้าจำหน่าย',
              description: 'Recieve Sell Items',
              color: Colors.indigo.shade600,
              imagePath: 'assets/sellitem_up.png',
              imageHeight: 0.3,
              isShow: true,
              textColor: Colors.white,
              cardBorder: BorderSide(color: Colors.indigo.shade600, width: 0),
              onTap: () {
                openServicePage('SPRecieve', 'รับสินค้าจำหน่าย', 'SellItems');
              },
            ),
            createCardWithBool(
              name: 'คืนสินค้าจำหน่าย',
              description: 'Return Sell Items',
              color: Colors.indigo.shade600,
              imagePath: 'assets/sellitem_down.png',
              imageHeight: 0.3,
              isShow: true,
              textColor: Colors.white,
              cardBorder: BorderSide(color: Colors.indigo.shade600, width: 0),
              onTap: () {
                openServicePage('SPReturn', 'คืนสินค้าจำหน่าย', 'SellItems');
              },
            ),
          ],
        ),
        if (_employee_code == "2-0081")
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1.0),
                ),
                color: Colors.red.shade500,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("หลังจากรับสินค้าจำหน่าย โปรดตรวจสอบรายการสินค้าในเมนูจำหน่ายสินค้าบนรถก่อนออกคิว หากรายการสินค้าไม่แสดง โปรดติดต่อเจ้าหน้าที่สต๊อกทันที",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                    ],
                  ),
                ),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              color: Colors.deepOrange.shade50,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text("ความหมายสัญลักษณ์ในหน้ารับของคืนของ", style: TextStyle(fontWeight: FontWeight.bold))],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                        Text(
                          ' = รับของแล้ว / คืนของแล้ว',
                          style: TextStyle(color: Colors.green),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                        Text(
                          ' = ยังไม่ครับของ / ยังไม่คืนของ',
                          style: TextStyle(color: Colors.red),
                        )
                      ],
                    ),
                    RichText.new(
                      text: TextSpan(style: TextStyle(color: Colors.black, fontFamily: 'Prompt', fontSize: 12), children: <TextSpan>[
                        TextSpan(text: 'ในช่องจำนวนของหากพื้นหลังเป็น'),
                        TextSpan(text: ' สีแดงคือยอดตั้งต้นไม่ได้และยังไม่ได้บันทึก', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade400)),
                        TextSpan(text: ' หากเป็น'),
                        TextSpan(text: 'สีเขียวคือยอดที่ผู้ใช้บันทึก', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade400)),
                      ]),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        if (false)
          // ignore: dead_code
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: createCardWithBool(
              name: 'บันทึกการรับและคืนข้าวกล่อง',
              description: '',
              color: Colors.deepPurple.shade400,
              imagePath: 'assets/take-away.png',
              imageHeight: 0.3,
              isShow: true,
              textColor: Colors.white,
              cardBorder: BorderSide(color: Colors.deepPurple.shade400, width: 0),
              onTap: () {
                openServicePage('FoodService2', 'รับและคืนข้าวกล่อง', 'ServiceItems');
              },
            ),
          )
      ],
    );
  }

  Widget _buildParcelMenu() {
    return ListView(
      children: [
        _buildListItem(
          title: 'สแกนพัสดุขึ้นรถ\nLoad Parcel Up',
          imageUrl: 'assets/parcel_up.png',
          color: Colors.red.shade400,
          onTap: () {
            // print('สแกนพัสดุขึ้นรถ');
            openParcelPage("parcelUp", "สแกนพัสดุขึ้นรถ");
          },
        ),
        const SizedBox(height: 5),
        _buildListItem(
          title: 'สแกนพัสดุลงรถ\nUnload Parcel',
          imageUrl: 'assets/parcel_down.png',
          color: Colors.red.shade400,
          onTap: () {
            // print('สแกนพัสดุลงรถ');
            openParcelPage("parcelDown", "สแกนพัสดุลงรถ");
          },
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildAllParcelsInOnePage() {
    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 3, 3),
              child: Text(
                "พัสดุ NCA Express",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              padding: const EdgeInsets.all(5),
              primary: true,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: [
                createCardWithBool(
                  name: 'สแกนพัสดุขึ้นรถ',
                  description: 'Load Parcel Up',
                  color: Colors.red.shade400,
                  imagePath: 'assets/n-parcels-up.png',
                  imageHeight: 0.3,
                  isShow: true,
                  textColor: Colors.white,
                  cardBorder: BorderSide(color: Colors.red.shade400, width: 0),
                  onTap: () {
                    openParcelPage("parcelUp", "สแกนพัสดุขึ้นรถ");
                  },
                ),
                createCardWithBool(
                  name: 'สแกนพัสดุลงรถ',
                  description: 'Unload Parcel',
                  color: Colors.red.shade400,
                  imagePath: 'assets/n-parcels-down.png',
                  imageHeight: 0.3,
                  isShow: true,
                  textColor: Colors.white,
                  cardBorder: BorderSide(color: Colors.red.shade400, width: 0),
                  onTap: () {
                    openParcelPage("parcelDown", "สแกนพัสดุลงรถ");
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 15, 3, 3),
              child: Text(
                "พัสดุภายใน",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              padding: const EdgeInsets.all(5),
              primary: true,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: [
                createCardWithBool(
                  name: 'นำของส่งภายในขึ้นรถ',
                  description: 'Load In-House Parcel',
                  color: Colors.teal.shade400,
                  imagePath: 'assets/inhouse_up.png',
                  imageHeight: 0.3,
                  isShow: true,
                  textColor: Colors.white,
                  cardBorder: BorderSide(color: Colors.teal.shade400, width: 0),
                  onTap: () {
                    openParcelPage("getParcelUP", "นำของส่งภายในขึ้นรถ");
                  },
                ),
                createCardWithBool(
                  name: 'นำของส่งภายในลงรถ',
                  description: 'Unload In-House Parcel',
                  color: Colors.teal.shade400,
                  imagePath: 'assets/inhouse_down.png',
                  imageHeight: 0.3,
                  isShow: true,
                  textColor: Colors.white,
                  cardBorder: BorderSide(color: Colors.teal.shade400, width: 0),
                  onTap: () {
                    openParcelPage("getParcelDown", "นำของส่งภายในลงรถ");
                  },
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildInHouseParcelMenu() {
    return ListView(
      children: [
        _buildListItem(
          title: 'นำของส่งภายในขึ้นรถ\nLoad In-House Parcel',
          imageUrl: 'assets/n-parcels-up.png',
          color: Colors.teal.shade400,
          onTap: () {
            // print('นำของส่งภายในขึ้นรถ');
            openParcelPage("getParcelUP", "นำของส่งภายในขึ้นรถ");
          },
        ),
        const SizedBox(height: 5),
        _buildListItem(
          title: 'นำของส่งภายในลงรถ\nUnload In-House Parcel',
          imageUrl: 'assets/n-parcels-down.png',
          color: Colors.teal.shade400,
          onTap: () {
            // print('นำของส่งภายในลงรถ');
            openParcelPage("getParcelDown", "นำของส่งภายในลงรถ");
          },
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildListItem({
    required String title,
    required String imageUrl,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.asset(imageUrl, width: 50, height: 50, fit: BoxFit.contain),
        ),
        tileColor: color,
        onTap: onTap,
      ),
    );
  }

  Widget _buildUserPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: _employee_pic,
                  placeholder: (context, url) => const CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // const Icon(Icons.account_circle),
            const Text(
              "ข้อมูลผู้ใช้งาน",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "รหัสพนักงาน : $_employee_code",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "ชื่อ : $_employee_name",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "ตำแหน่ง : $_employee_typeName",
              style: const TextStyle(fontSize: 18),
            ),
            const Divider(),
            const SizedBox(height: 5), // Add space between the Divider and buttons
            SizedBox(
              width: double.infinity, // Make buttons expand to full width
              child: ElevatedButton(
                onPressed: () async {
                  // Add functionality for the first button
                  await _getQueue();
                  selectBus(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700),
                child: const Text(
                  'เลือกเที่ยวรถ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 69),
            SizedBox(
              width: double.infinity, // Make buttons expand to full width
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700),
                onPressed: () async {
                  final bool = await _showLogoutConfirmationDialog(context);
                  if (bool) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      CupertinoPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                // onLongPress: () {
                //   Navigator.pushAndRemoveUntil(
                //     context,
                //     CupertinoPageRoute(builder: (context) => const LoginPage()),
                //     (route) => false,
                //   );
                // },
                child: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ), // Add space below the buttons
            const Divider(),
            const Text("NCA ON THE WAY", style: TextStyle(fontSize: 14.0)),
            // const Text("IT Department : 2023-2024"),
            Text('v$_appVersion', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _readAccprevent() async {
    try {
      String jsonData = await rootBundle.loadString('assets/accprevent.json');
      List<dynamic> data = json.decode(jsonData);

      if (data.isNotEmpty) {
        final randomIndex = DateTime.now().millisecondsSinceEpoch % data.length;
        setState(() {
          _typeAccident = data[randomIndex]['accprevent_name'];
        });
      }
    } catch (e) {
      // print('Error: $e');
    }
  }

  Future<void> _setExitPath(String busRoute) async {
    final Map routeAndExit = separateStringFromBuslineName(busRoute);
    final String buslineName = routeAndExit['output1'];
    final String exitPath = routeAndExit['output2'];

    setState(() {
      _busCodeText = buslineName;
      _exitPath = exitPath;
    });

    if (exitPath.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      _showExitPathInfomationDialog(context, exitPath);
    }
  }

  Map<String, String> separateStringFromBuslineName(String input) {
    final regex = RegExp(r'^(.*?)\s*\((.+)\)$');
    final match = regex.firstMatch(input);

    if (match != null) {
      String part1 = match.group(1) ?? '';
      String part2 = match.group(2) ?? '';
      return {'output1': part1, 'output2': part2};
    } else {
      // If no match, return the original string as output1 and an empty string for output2
      return {'output1': input, 'output2': ''};
    }
  }

  Future<void> _getQueue() async {
    setState(() {
      isLoading = true;
    });

    // Replace this URL with your actual API endpoint
    const String apiUrl = 'https://www.nakhonchaiair.com/service/Service.php';
    EasyLoading.show(status: 'กำลังโหลดข้อมูลคิวของคุณ...');
    log(_employee_id);
    log(_employee_type);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'method': 'ncachkQueue', 'emp_id': _employee_id, 'emp_type': _employee_type},
      );

      inspect({'method': 'ncachkQueue', 'emp_id': _employee_id, 'emp_type': _employee_type});

      final responseData = json.decode(response.body);
      print(responseData);

      if (responseData == null) {
      } else {
        setState(() {
          userQ = responseData;
        });
      }

      // print(userQ);
    } catch (error) {
      // Handle network or other errors
      log("ERROR");
      // print('An error occurred: $error');
      _showErrorDialog('พบข้อผิดพลาด โปรดตรวจสอบการเชื่อมต่ออินเตอร์ของคุณแล้วลองใหม่อีกครั้ง');
    } finally {
      setState(() {
        isLoading = false;
      });
      EasyLoading.dismiss();
    }
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

  void goToMainMenuAfterSelect() {
    setState(() {
      _currentIndex = 1;
    });
  }

  Map<String, bool> expansionStates = {};

  Widget buildListTileFromJson(Map<String, dynamic> data, int index) {
    double c_width = MediaQuery.of(context).size.width * 0.8;
    List<dynamic> isOildft = ((data['is_oildft'] ?? []) as List);
    Color? tileColor = index % 2 == 0 ? Colors.grey.shade300 : Colors.white; // Example alternating colors
    bool isExpanded = expansionStates['$index'] ?? false;
    return GestureDetector(
      onTap: () {},
      child: InkWell(
        onTap: () {
          _setExitPath(data['queue_routename']);

          data["queue_routename"] = separateStringFromBuslineName(data["queue_routename"])["output1"];

          setState(() {
            // _busCodeText = "${data['queue_routename']}";
            _userBusQ = data;
            _busTime = data['queue_time'];
            _busDate = getYearFormString(data['queue_send']);
          });

          Navigator.pop(context);
          inspect(_userBusQ);
          movePage(0);
        },
        child: Container(
          padding: EdgeInsets.zero,
          width: c_width,
          color: tileColor, // Assigning different colors to each tile
          child: ExpansionTile(
            // leading: const Icon(Icons.bus_alert_sharp),
            iconColor: Colors.lightBlue,
            textColor: Colors.blueAccent,
            backgroundColor: const Color.fromARGB(255, 240, 253, 255),
            title: GestureDetector(
              onTap: () {
                _setExitPath(data['queue_routename']);

                data["queue_routename"] = separateStringFromBuslineName(data["queue_routename"])["output1"];

                setState(() {
                  // _busCodeText = "${data['queue_routename']}";
                  _userBusQ = data;
                  _busTime = data['queue_time'];
                  _busDate = getYearFormString(data['queue_send']);
                });

                Navigator.pop(context);
                inspect(_userBusQ);
                movePage(0);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เที่ยวเวลา: ${data['queue_time']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    'เส้นทาง: ${data['queue_routename']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    'วันที่ออก: ${getYearFormString(data["queue_send"])}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            initiallyExpanded: isExpanded,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), // Adjust the left padding as needed
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "เส้นทาง: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['queue_routename'],
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "เบอร์รถ: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['queue_busnumber'],
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "ชนิดจอ: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: "${checkNullReturn(data['queue_tvtypegen'])} ${checkNullReturn(data['queue_tvtypedetail'])}",
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "ชานชาลา: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: checkNullReturn(data['is_station']),
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "รหัสเที่ยว: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: checkNullReturn(data['is_qcode']),
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "พขร: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['queue_driver'],
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "พ่วง 1: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['queue_driver1'],
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "พ่วง 2: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['queue_driver2'],
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "โค้ช: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: data['queue_coach'],
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "เวลาเข้างาน: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: "${data['get_sworkdate']} ${data['get_sworktime']}",
                              )
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: queInfoTextStyle,
                            children: <TextSpan>[
                              const TextSpan(
                                text: "เวลาเลิกงาน: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: "${data['get_eworkdate']} ${data['get_eworktime']}",
                              )
                            ],
                          ),
                        ),
                        if (isOildft != null && isOildft.isNotEmpty) ...[
                          const Text(
                            "การใช้น้ำมัน: ",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: isOildft.map<Widget>((is_oildft) {
                              return Padding(
                                padding: const EdgeInsets.all(0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text("วันที่: ${is_oildft["queue"]}", textAlign: TextAlign.center),
                                        ),
                                        Expanded(
                                          child: Text("เส้นทาง: ${is_oildft["busway"]}", textAlign: TextAlign.center),
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text("เติม: ${is_oildft["private"]}", textAlign: TextAlign.center),
                                        ),
                                        Expanded(
                                          child: Text("ใช้: ${is_oildft["use"]}", textAlign: TextAlign.center),
                                        ),
                                        if (double.parse(is_oildft["private"]) - double.parse(is_oildft["use"]) >= 0)
                                          Expanded(
                                            child: Text("เหลือ: ${(double.parse(is_oildft["private"]) - double.parse(is_oildft["use"])).abs().toStringAsFixed(2)}",
                                                textAlign: TextAlign.center, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                          ),
                                        if (double.parse(is_oildft["private"]) - double.parse(is_oildft["use"]) < 0)
                                          Expanded(
                                            child: Text("เกิน: ${((double.parse(is_oildft["private"]) - double.parse(is_oildft["use"]))).abs().toStringAsFixed(2)}",
                                                textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Colors.black,
                                      thickness: 0.3,
                                      indent: 20,
                                      endIndent: 30,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade200,
                            ),
                            onPressed: () {
                              openWebView(data["url_condition"], "เอกสารแนบรถ");
                            },
                            child: const Text(
                              'เอกสารแนบรถ',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? checkNullReturn(value) {
    if (value == null) {
      return "-";
    } else {
      return value;
    }
  }

  Widget buildListViewFromJson() {
    late DateTime dtNow = DateTime.now();
    if (userQ.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
              padding: EdgeInsets.only(right: 5, bottom: 5),
              child: AutoSizeText(
                "อัปเดตข้อมูลคิวล่าสุดเมื่อ: ${DateFormat('HH:mm dd/MM/yyyy').format(dtNow)}",
                maxFontSize: 14,
                minFontSize: 8,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
              )),
          Expanded(
            child: ListView.builder(
              itemCount: userQ.length,
              itemBuilder: (context, index) {
                return buildListTileFromJson(userQ[index], index);
              },
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.network(
            //   'https://static.wikia.nocookie.net/gensin-impact/images/0/03/Icon_Emoji_Paimon%27s_Paintings_26_Navia_1.png/revision/latest?cb=20230824043600',
            //   height: 200,
            // ),
            Image.asset('assets/driverLike-01.png', height: 200),
            const ListTile(
              title: Text(
                'ตอนนี้ยังไม่มีคิว',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30),
              ),
              subtitle: Text(
                'ไว้กลับมาดูใหม่นะ!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('รับทราบ!'),
            ),
          ],
        ),
      );
    }
  }

  void selectBus(BuildContext context) async {
    setState(() {
      isBottomSheetOpen = true;
    });
    await showModalBottomSheet<void>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      showDragHandle: true,
      enableDrag: true,
      isScrollControlled: true,
      // backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      backgroundColor: Colors.white,
      context: context,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return buildListViewFromJson();
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        isBottomSheetOpen = false;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      //if you need it then you have to take it
    } else if (state == AppLifecycleState.resumed) {
      //some driver open queue page but they leave the app for so long but app not killed by OS and keep running in background so
      // we need to check if the bottom sheet is open or not and if it is open then we need to close it and refresh the queue
      // and select bus again
      if (isBottomSheetOpen) {
        setState(() {
          isBottomSheetOpen = false;
        });
        Navigator.pop(context);
        await _getQueue();
        selectBus(context);
      }
    }
  }

  void openServicePage(String action, String pageName, String mode) {
    if (_userBusQ.isEmpty) {
      EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1000), dismissOnTap: true);
      return;
    }

    if (action == "SPRecieve" && mode == "ServiceItems") {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ParcelServiceUp(
            pageName: pageName,
            par_qtimedt: _userBusQ["queuedt_id"],
            par_qdate: thaiDateToGregorian(getYearFormString(_userBusQ["queue_send"])),
            // par_busline: _userBusQ["queue_busline"],
            par_busline: _userBusQ["queue_busline"],
            par_buslinetype: _userBusQ["queue_buslinetype"],
            par_qdttime: _userBusQ["queue_time"].replaceAll(':', '').trim(),
            par_action: action,
            par_busdata: _userBusQ,
            mode: "ServiceItems",
            pageMainColor: Colors.purple.shade500,
          ),
        ),
      );
    } else if (action == "SPReturn" && mode == "ServiceItems") {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ParcelServiceDown(
            pageName: pageName,
            par_qtimedt: _userBusQ["queuedt_id"],
            par_qdate: thaiDateToGregorian(getYearFormString(_userBusQ["queue_send"])),
            par_busline: _userBusQ["queue_busline"],
            par_buslinetype: _userBusQ["queue_buslinetype"],
            par_qdttime: _userBusQ["queue_time"].replaceAll(':', '').trim(),
            par_action: action,
            par_busdata: _userBusQ,
            mode: "ServiceItems",
            pageMainColor: Colors.purple.shade400,
          ),
        ),
      );
    } else if (action == "SPRecieve" && mode == "SellItems") {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ParcelServiceUp(
            pageName: pageName,
            par_qtimedt: _userBusQ["queuedt_id"],
            par_qdate: thaiDateToGregorian(getYearFormString(_userBusQ["queue_send"])),
            // par_busline: _userBusQ["queue_busline"],
            par_busline: _userBusQ["queue_busline"],
            par_buslinetype: _userBusQ["queue_buslinetype"],
            par_qdttime: _userBusQ["queue_time"].replaceAll(':', '').trim(),
            par_action: action,
            par_busdata: _userBusQ,
            mode: "SellItems",
            pageMainColor: Colors.indigo.shade600,
          ),
        ),
      );
    } else if (action == "SPReturn" && mode == "SellItems") {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ParcelServiceDown(
            pageName: pageName,
            par_qtimedt: _userBusQ["queuedt_id"],
            par_qdate: thaiDateToGregorian(getYearFormString(_userBusQ["queue_send"])),
            par_busline: _userBusQ["queue_busline"],
            par_buslinetype: _userBusQ["queue_buslinetype"],
            par_qdttime: _userBusQ["queue_time"].replaceAll(':', '').trim(),
            par_action: action,
            par_busdata: _userBusQ,
            mode: "SellItems",
            pageMainColor: Colors.indigo.shade600,
          ),
        ),
      );
    } else if (action == "FoodService") {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => FoodService(
            pageName: pageName,
            par_qtimedt: _userBusQ["queuedt_id"],
            par_qdate: thaiDateToGregorian(getYearFormString(_userBusQ["queue_send"])),
            par_busline: _userBusQ["queue_busline"],
            par_buslinetype: _userBusQ["queue_buslinetype"],
            par_qdttime: _userBusQ["queue_time"].replaceAll(':', '').trim(),
            par_action: action,
            par_busdata: _userBusQ,
          ),
        ),
      );
    } else if (action == "FoodService2") {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => FoodService2(
            pageName: pageName,
            par_qtimedt: _userBusQ["queuedt_id"],
            par_qdate: thaiDateToGregorian(getYearFormString(_userBusQ["queue_send"])),
            par_busline: _userBusQ["queue_busline"],
            par_buslinetype: _userBusQ["queue_buslinetype"],
            par_qdttime: _userBusQ["queue_time"].replaceAll(':', '').trim(),
            par_action: action,
            par_busdata: _userBusQ,
          ),
        ),
      );
    }
  }

  void openParcelPage(String action, String pageName) {
    if (_userBusQ.isEmpty) {
      EasyLoading.showInfo("กรุณาเลือกเที่ยวรถก่อน", duration: const Duration(milliseconds: 1000), dismissOnTap: true);
      return;
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => Parcels(pageName: pageName, par_qtimedt: _userBusQ["queuedt_id"], par_busdata: _userBusQ, action: action),
      ),
    );
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

  String getYearFormString(String value) {
    RegExp dateRegex = RegExp(r'\b\d{2}/\d{2}/\d{2}\b');
    String extractedDate = dateRegex.stringMatch(value) ?? '';
    // print("extractedDate : ${extractedDate}");
    return extractedDate;
  }

  Widget createCardWithBool(
      {required Function onTap,
      required String imagePath,
      required String name,
      required String description,
      required bool isShow,
      required Color color,
      required double imageHeight,
      required Color textColor,
      required BorderSide cardBorder}) {
    if (isShow) {
      return createCard(onTap: onTap, imagePath: imagePath, name: name, description: description, color: color, imageHight: imageHeight, textColor: textColor, cardBorder: cardBorder);
    } else {
      return Container();
    }
  }

  Widget createCard({
    required Function onTap,
    required String imagePath,
    required String name,
    required String description,
    required Color color,
    required double imageHight,
    required Color textColor,
    required BorderSide cardBorder,
  }) {
    return GestureDetector(
      onTap: onTap as void Function(),
      child: Card(
        surfaceTintColor: Colors.white,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: cardBorder,
        ),
        elevation: 4.0,
        child: Ink(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: imageHight * MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w100,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                // const SizedBox(height: 2.0),
                Text(
                  description,
                  style: TextStyle(fontSize: 10.0, color: textColor),
                ),
                const SizedBox(height: 2.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
