import 'package:flutter/services.dart';
import 'package:flutter_qrcode/qrcode_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  QRcodeController controller = QRcodeController();

  TestWidgetsFlutterBinding.ensureInitialized();

  Future<dynamic> handelCall(MethodCall methodCall) async {
    Map<String, String> map = {};
    if (methodCall.method == "result") {
      print(methodCall.arguments);
    }
    return Future.value(map);
  }

  tearDown(() {
    controller.setMethodCallHandler(handelCall);
  });

  test('getPlatformVersion', () async {
    expect(await QRcodeController.generateQRCode('42'), '11');
  });
}
