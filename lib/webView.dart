import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'package:nca_ontheway/pull_to_refresh.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String tabName;
  const WebViewPage({Key? key, required this.url, required this.tabName}) : super(key: key);
  @override
  State<WebViewPage> createState() => _WebViewPage();
}

class _WebViewPage extends State<WebViewPage> with WidgetsBindingObserver {
  late WebViewController webViewcontroller;
  int isCameraOpen = 0;
  // late String tabName = tabName;

  late DragGesturePullToRefresh dragGesturePullToRefresh; // Here

  @override
  void initState() {
    super.initState();
    EasyLoading.show(status: "รอซักครู่...");
    log('webView_initState');

    dragGesturePullToRefresh = DragGesturePullToRefresh();

    // final uriWebView = Uri.encodeComponent(widget.url);
    webViewcontroller = WebViewController()
      //..clearCache()
      ..setBackgroundColor(const Color.fromRGBO(255, 255, 255, 1))
      ..enableZoom(true)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          EasyLoading.show(status: "รอซักครู่...");
          dragGesturePullToRefresh.started();
        },
        onProgress: (int progress) {},
        onWebResourceError: (WebResourceError error) async {
          dragGesturePullToRefresh.finished();
        },
        onPageFinished: (String url) async {
          EasyLoading.dismiss();
          dragGesturePullToRefresh.finished();
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

    dragGesturePullToRefresh // Here
        .setController(webViewcontroller)
        .setDragHeightEnd(600)
        .setDragStartYDiff(10)
        .setWaitToRestart(3000);

    WidgetsBinding.instance.addObserver(this);
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
    Navigator.pop(context);
    return true;
    // Navigator.pop(context);
    // return (await showDialog(
    //       context: context,
    //       builder: (context) => AlertDialog(
    //         title: const Text('แจ้งเตือน'),
    //         content: const Text('ย้อนกลับ?'),
    //         actions: <Widget>[
    //           TextButton(
    //             onPressed: () =>
    //                 Navigator.of(context).pop(false), //<-- SEE HERE
    //             child: const Text('ไม่'),
    //           ),
    //           TextButton(
    //             //onPressed: () => {webViewcontroller.loadRequest(Uri.parse(indexUrl)), Navigator.of(context).pop(false)}, // <-- SEE HERE
    //             onPressed: () {
    //               Navigator.pop(context);
    //               Navigator.pop(context);
    //             }, //<-- SEE HERE
    //             child: const Text('ใช่'),
    //           ),
    //         ],
    //       ),
    //     )) ??
    //     false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.tabName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          restorationId: "webView",
          body: SafeArea(
            child: RefreshIndicator(
              triggerMode: RefreshIndicatorTriggerMode.onEdge,
              onRefresh: dragGesturePullToRefresh.refresh, // Here
              child: Builder(
                builder: (context) {
                  // IMPORTANT: Use the RefreshIndicator context!
                  dragGesturePullToRefresh.setContext(context); // Here
                  return WebViewWidget(
                    controller: webViewcontroller,
                    // Add it to the WebViewWidget
                    gestureRecognizers: {Factory(() => dragGesturePullToRefresh)}, // Here
                  );
                },
              ),
            ),
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
