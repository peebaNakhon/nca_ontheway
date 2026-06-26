# เอกสารประกอบ NCA ON THE WAY APP VERSION 2

## Framework และเทคโนโลยีหลัก
- Flutter Framework (SDK >=3.2.3)
- Dart Programming Language
- Shorebird.dev สำหรับการอัพเดทแอพพลิเคชัน

## Dependencies หลัก
- **UI และ Navigation**
  - cupertino_icons: ^1.0.2
  - salomon_bottom_bar: ^3.3.2
  - flutter_easyloading: ^3.0.5
  - loading_animation_widget: ^1.2.0+4

- **การจัดการข้อมูล**
  - shared_preferences: ^2.2.2
  - http: ^1.1.0
  - intl: ^0.19.0

- **ฟีเจอร์พิเศษ**
  - nfc_manager: ^3.3.0
  - barcode_scan2: ^4.5.1
  - qr_flutter: ^4.1.0
  - google_maps_flutter: ^2.5.0
  - geolocator: ^10.1.0

- **การจัดการสื่อ**
  - image_picker: ^1.0.4
  - cached_network_image: ^3.3.1
  - video_player: ^2.9.2

## โครงสร้างไฟล์สำคัญ

### ไฟล์หลัก
- **main.dart**: ไฟล์หลักของแอพพลิเคชัน ประกอบด้วยการกำหนดค่าเริ่มต้นและการจัดการเส้นทางหลัก
- **landingPage.dart**: หน้าหลักของแอพพลิเคชัน
- **nfcReader.dart**: จัดการการอ่านข้อมูล NFC
- **webView.dart** และ **webViewSell.dart**: จัดการการแสดงผลเว็บเพจภายในแอพ

### โฟลเดอร์สำคัญ
- **class/**: เก็บคลาสที่ใช้ในแอพพลิเคชัน
- **Parcelservice/**: จัดการบริการพัสดุ
- **InHouseParcels/**: จัดการพัสดุภายใน
- **iService/**: บริการภายในแอพ
- **transportation/**: จัดการการขนส่ง

## ไฟล์หลักในโฟลเดอร์ lib/class

### api_calling.dart
ไฟล์นี้เป็นคลาสหลักสำหรับการเรียกใช้ API ทั้งหมดของแอพพลิเคชัน

**จุดเด่น:**
- จัดการการเชื่อมต่อกับ API หลักที่ `https://www.nakhonchaiair.com/service/Service.php`
- มีการจัดการ API สำหรับการตั้งค่าเมนูและการอัพเดทแอพ
- ฟังก์ชันสำคัญ:
  - `saveReceived()`: บันทึกข้อมูลการรับพัสดุ
  - `ncaChkRefno()`: ตรวจสอบรหัสอ้างอิงพัสดุ
  - `ncaGetTotalParcelDown()`: ดึงข้อมูลจำนวนพัสดุทั้งหมด
  - `ncaGetGps()`: ดึงข้อมูลตำแหน่ง GPS
  - `checkForUpdate()`: ตรวจสอบการอัพเดทแอพ

### Common.dart
คลาสที่เก็บฟังก์ชันทั่วไปที่ใช้ร่วมกันในแอพพลิเคชัน

**ฟังก์ชันสำคัญ:**
- `getYearFormString()`: แปลงวันที่จากรูปแบบข้อความเป็นปี
- `thaiDateToGregorian()`: แปลงวันที่แบบไทยเป็นแบบสากล
- `showSnackBarNotificationError()`: แสดงข้อความแจ้งเตือนข้อผิดพลาด
- `showSnackBarNotificationSuccess()`: แสดงข้อความแจ้งเตือนความสำเร็จ
- `filterItemsByCategory()`: กรองรายการตามหมวดหมู่

### modal.dart
คลาสสำหรับจัดการ Modal Dialog ต่างๆ

**ฟังก์ชันสำคัญ:**
- `showNotSaveDialog()`: แสดง Dialog แจ้งเตือนเมื่อยังไม่ได้บันทึกข้อมูล

## เมนูที่ใช้ WebView

### WebView ทั่วไป (WebViewPage)
ใช้สำหรับแสดงหน้าเว็บทั่วไปในแอพพลิเคชัน

**เมนูที่ใช้:**
- **จุดจอดรถ (Passing Point)**
  - URL: `http://203.151.125.244/ncaprj/nca_project/appchecklog/view/mpoint1.php`
  - Parameters: 
    - method=ncaGetPoint
    - plan=[queue_plan]
    - qdttime=[queue_time]
    - qttimeid=[queuedt_id]
    - userid=[employee_id]
    - code=[employee_code]
    - plat=and

- **คูปองส่วนลด (Coupons)**
  - URL: `http://203.151.125.244/ncaprj/nca_project/appchecklog/view/v_gifcet.php`
  - Parameters:
    - qtime=[queuedt_id]
    - dspname=[employee_name]
    - dspid=[employee_id]

- **ผังที่นั่ง (Seat Maps)**
  - URL: `http://203.151.125.244/ncaprj/nca_project/nca_project/mpointhtml/products1.php`
  - Parameters:
    - user=[employee_code]
    - qtime=[queuedt_id]
    - plan=[queue_plan]

- **ตรวจสภาพรถ (Vehicle inspection)**
  - URL: `http://203.151.125.244/ncaprj/nca_project/nca_project/mpointhtml/carebus.php`
  - Parameters:
    - user=[employee_code]
    - qtimedt=[queuedt_id]

- **การแจ้งซ่อม (Repairs)**
  - URL: `http://61.91.248.18/mms/ncaprj_formms/nca_project/nca_project/mpointhtml/mainternance.php`
  - Parameters:
    - kn_user=[employee_id]
    - empst=[employee_status]
    - qtimedt=[queuedt_id]

- **อบรม วันหยุด (Meeting, Leave)**
  - URL: `http://61.91.248.20/ncaprj/nca_project/ncacalendarleva/view/example-page.php`
  - Parameters:
    - code=[employee_code]
    - emp=[employee_id]

### WebView สำหรับจำหน่ายสินค้า (WebViewSellPage)
ใช้สำหรับระบบจำหน่ายสินค้าบนรถ

**เมนูที่ใช้:**
- **จำหน่ายสินค้า (Sell Items)**
  - URL: `http://61.91.248.21/ncasellonbus/view/link_ncaotwsellitem.php`
  - Parameters (กรณีไม่ได้เลือกเที่ยวรถ):
    - nca_mpid=[employee_id]
    - nca_avatar=[employee_pic]
    - nca_code=[employee_code]
    - nca_fname=[employee_name]
    - nca_type=[employee_type]
  
  - Parameters (กรณีเลือกเที่ยวรถแล้ว):
    - queue_busline=[queue_busline]
    - queue_buslinetype=[queue_buslinetype]
    - queue_busnumber=[queue_busnumber]
    - queue_date=[extractedDate]
    - queue_plan=[queue_plan]
    - queue_routeid=[route_id]
    - queue_routename=[queue_routename]
    - queue_time=[queue_time]
    - queuedt_id=[queuedt_id]
    - nca_mpid=[employee_id]
    - nca_avatar=[employee_pic]
    - nca_code=[employee_code]
    - nca_fname=[employee_name]
    - nca_type=[employee_type]

### คุณสมบัติพิเศษของ WebView
- รองรับการ Pull-to-Refresh
- รองรับการอัพโหลดรูปภาพ
- มีการจัดการ Session และ Cache
- รองรับการทำงานแบบ Offline
- มีการจัดการ Error และ Loading state
- รองรับการทำงานกับ JavaScript
- มีการจัดการ Navigation (ปุ่มย้อนกลับ)

### การจัดการ WebView
- ใช้ `webview_flutter` package
- มีการจัดการ Lifecycle ของ WebView
- รองรับการทำงานกับ Camera และ Gallery
- มีการจัดการ Permission
- รองรับการทำงานกับ JavaScript Channel
- มีการจัดการ Cache และ Session

## API Endpoints

### API หลัก
- Base URL: `https://www.nakhonchaiair.com/service/Service.php`
- Menu Setting API: `http://61.91.248.21/nca_project/ncaotwv2/menuSetting.json`
- Check Update API: `http://61.91.248.21/nca_project/ncaotwv2/ncaotwv2.json`

### Methods หลัก
- `saveReceived`: POST - บันทึกการรับพัสดุ
- `ncaChkRefno`: POST - ตรวจสอบรหัสอ้างอิง
- `ncaGetTotalParcelDown`: POST - ดึงข้อมูลจำนวนพัสดุ
- `getLatLongpointbr`: POST - ดึงข้อมูลตำแหน่ง
- `saveLogPointbr`: POST - บันทึกตำแหน่ง

## การพัฒนา (Development)

### การติดตั้ง
```bash
flutter pub get
```

### การรันในโหมดพัฒนา
```bash
flutter run
```

### การ Build แอพพลิเคชัน

#### Android
```bash
flutter build apk
```

#### iOS
```bash
flutter build ios
```

## Shorebird.dev

### การทำงาน
Shorebird.dev เป็นเครื่องมือสำหรับการอัพเดทแอพพลิเคชัน Flutter โดยไม่ต้องอัพโหลดเวอร์ชันใหม่ไปยัง App Store หรือ Play Store

### การใช้งาน
- แอพจะอัพเดทอัตโนมัติเมื่อเปิดใช้งาน (auto_update: true)
- app_id: 1400deef-45f8-4d6e-bd0e-942ca2da8855

### การอัพเดทด้วย Shorebird
1. สร้าง patch:
```bash
shorebird patch
```

2. อัพโหลด patch:
```bash
shorebird upload
```

## การจัดการข้อมูล
- ใช้ SharedPreferences สำหรับเก็บข้อมูลในเครื่อง
- ใช้ HTTP package สำหรับการเรียกใช้ API
- มีการจัดการ Error และ Loading state
- รองรับการทำงานแบบ Offline

## การจัดการ UI
- ใช้ Material Design
- มีการแสดง Loading state ด้วย EasyLoading
- มีการจัดการ Dialog และ Snackbar
- รองรับการแสดงผลบนหน้าจอขนาดต่างๆ

## การจัดการตำแหน่ง
- ใช้ Geolocator สำหรับการดึงตำแหน่ง GPS
- บันทึกตำแหน่งพร้อมกับข้อมูลพัสดุ
- รองรับการอัพเดทตำแหน่งแบบ Real-time

## การจัดการการอัพเดท
- ใช้ Shorebird.dev สำหรับการอัพเดทแอพ
- มีการตรวจสอบเวอร์ชันอัตโนมัติ
- รองรับการอัพเดทแบบ Hot Update
