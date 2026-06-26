import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nca_ontheway/landingPage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:webview_flutter_android/webview_flutter_android.dart' as webview_flutter_android;
import 'package:path_provider/path_provider.dart';

class WebViewSellPage extends StatefulWidget {
  final String url;
  final String tabName;
  const WebViewSellPage({Key? key, required this.url, required this.tabName}) : super(key: key);
  @override
  State<WebViewSellPage> createState() => _WebViewSellPage();
}

class _WebViewSellPage extends State<WebViewSellPage> with WidgetsBindingObserver {
  late WebViewController webViewcontroller;
  late String currentUrl;
  int isCameraOpen = 0;
  // late String tabName = tabName;

  @override
  void initState() {
    super.initState();
    EasyLoading.show(status: "รอซักครู่...");
    log('webView_initState');
    WidgetsBinding.instance.addObserver(this);

    // final uriWebView = Uri.encodeComponent(widget.url);
    webViewcontroller = WebViewController()
      //..clearCache()
      ..setBackgroundColor(const Color.fromRGBO(34, 35, 99, 1))
      ..enableZoom(true)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          // EasyLoading.show(status: 'รอซักครู่...');
          currentUrl = url;
        },
        onProgress: (int progress) {
          //log(progress.toString());
          final repro = progress / 100;
          log('progress : $repro');
          // EasyLoading.showProgress(repro, status: '$progress%');
        },
        onWebResourceError: (WebResourceError error) async {
          log(error.toString());
          EasyLoading.showError("พบปัญหาในการเชื่อมต่อ\nกำลังลองอีกครั้งใน 3 วินาที");
          await Future.delayed(const Duration(seconds: 3));
          webViewcontroller.reload();
        },
        onPageFinished: (String url) async {
          //await Future.delayed(const Duration(seconds: 3));
          log(url);
          currentUrl = url;
          EasyLoading.dismiss();
        },
      ))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('flutterCh', onMessageReceived: (JavaScriptMessage message) {
        if (message.message.contains("returnHtmlData:")) {
          saveHtmlData(message.message.replaceAll("returnHtmlData:", ""));
        } else if (message.message.contains("backToMainPage")) {
          Navigator.pop(context);
          Navigator.pop(context);
        }
        log('MessageReceived : $message');
      });
    webViewcontroller
        .loadRequest(
      Uri.parse(widget.url),
    )
        .then((value) async {
      webViewcontroller.enableZoom(false);
    });
    //FlutterNativeSplash.remove();
    addFileSelectionListener();
  }

  void addFileSelectionListener() async {
    if (Platform.isAndroid) {
      final controller = (webViewcontroller.platform as webview_flutter_android.AndroidWebViewController);
      await controller.setOnShowFileSelector(_androidFilePicker);
    }
  }

  Future<List<String>> _androidFilePicker(webview_flutter_android.FileSelectorParams params) async {
    isCameraOpen = 1;
    log("Called ImagePicker");
    log(params.acceptTypes.toString());
    if (params.acceptTypes.toString() == "[image/png, image/gif, image/jpeg]") {
      final picker = image_picker.ImagePicker();
      final photo = await picker.pickImage(source: image_picker.ImageSource.gallery);
      if (photo == null) {
        return [];
      }

      final imageData = await photo.readAsBytes();
      final decodedImage = image.decodeImage(imageData)!;
      final scaledImage = image.copyResize(decodedImage, height: 1080);
      final png = image.encodePng(scaledImage);

      final filePath = (await getTemporaryDirectory()).uri.resolve(
            './image_${DateTime.now().microsecondsSinceEpoch}.png',
          );
      final file = await File.fromUri(filePath).create(recursive: true);
      await file.writeAsBytes(png, flush: true);

      return [file.uri.toString()];
    }
    return [];
  }

  void saveHtmlData(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('htmlData', value);
  }

  @override
  void dispose() {
    EasyLoading.dismiss();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    log(state.toString());
    if (state == AppLifecycleState.resumed && isCameraOpen != 1) {
      //EasyLoading.show(status: "รอซักครู่...");
      log('webViewReloaded');
      log('isCameraOpen : $isCameraOpen');
      await webViewcontroller.runJavaScript('window.flutterCh.postMessage("returnHtmlData:"+document.getElementsByTagName("head").length);'); // get DOM
      await webViewcontroller.runJavaScript('console.log(document.getElementsByTagName("head").length);'); //console.log obj length
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? htmlData = prefs.getString('htmlData');
      var htmlDataWet = htmlData.toString().trim();
      log('status: $htmlDataWet');
      //check if DOM is exist (l = 1) that mean app not killed by OS
      if (htmlDataWet == "0") {
        log("webView is Null // App getKilled by OS");
        webViewcontroller.reload();
      }
      isCameraOpen = 0;
      log('isCameraOpenAfter : $isCameraOpen');
    }

    if (state == AppLifecycleState.resumed) {}
  } 

  Future<bool> _onWillPop() async {
    EasyLoading.dismiss();
    if (!currentUrl.contains("v_dashboard")) {
      webViewcontroller.goBack();
      return false;
    } else {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('แจ้งเตือน'),
              content: const Text('ต้องการกลับไปยังเมนูหลักหรือไม่?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), //<-- SEE HERE
                  child: const Text('ไม่'),
                ),
                TextButton(
                  //onPressed: () => {webViewcontroller.loadRequest(Uri.parse(indexUrl)), Navigator.of(context).pop(false)}, // <-- SEE HERE
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }, //<-- SEE HERE
                  child: const Text('ใช่'),
                ),
              ],
            ),
          )) ??
          false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color.fromRGBO(34, 35, 99, 1),
          // appBar: AppBar(
          //   title: Text(widget.tabName),
          //   backgroundColor: Color.fromRGBO(34, 35, 99, 1),
          //   leading: IconButton(
          //     icon: const Icon(Icons.arrow_back),
          //     onPressed: () {
          //       // Show logout confirmation dialog when back arrow is pressed
          //       // _showLogoutConfirmationDialog(context).then(
          //       //   (logoutConfirmed) {
          //       //     if (logoutConfirmed) {
          //       //       // Navigate back to the login page and remove NFCReaderPage from the stack
          //       //       // Navigator.pushAndRemoveUntil(
          //       //       //   context,
          //       //       //   CupertinoPageRoute(
          //       //       //       builder: (context) => const LandingPage()),
          //       //       //   (route) => false,
          //       //       // );
          //       //       Navigator.pop(context);
          //       //     }
          //       //   },
          //       // );
          //       Navigator.pop(context);
          //     },
          //   ),
          // ),
          restorationId: "webView",
          body: SafeArea(
            child: WebViewWidget(controller: webViewcontroller),
          ),
        ),
      ),
    );
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
}
