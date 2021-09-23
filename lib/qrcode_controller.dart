import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRcodeController {
  static const MethodChannel _channel = MethodChannel('MethodChannel.qrcode');

  ///_textureId
  int _textureId = -1;

  void setMethodCallHandler(
      Future<dynamic> Function(MethodCall call)? handler) {
    _channel.setMethodCallHandler(handler);
  }

  Future<int> initialize() async {
    _textureId = await _channel.invokeMethod('init');
    return _textureId;
  }

  Future<void> pauseScan() async {
    assert(_textureId >= 0, "must be initialized first");
    await _channel.invokeMethod('pauseScan');
  }

  Future<void> resumeScan() async {
    assert(_textureId >= 0, "must be initialized first");
    await _channel.invokeMethod('resumeScan');
  }

  Future<void> dispose() async {
    _textureId = -1;
    await _channel.invokeMethod('dispose');
  }

  Future<void> openFlashlight() async {
    await _channel.invokeMethod('openFlashlight');
  }

  Future<void> closeFlashlight() async {
    await _channel.invokeMethod('closeFlashlight');
  }

  Widget buildPreview() {
    return _textureId < 0 ? Container() : Texture(textureId: _textureId);
  }

  static Future<Image> generateQRCode(String data,
      {double size = 100, Uint8List? icon}) async {
    try {
      Uint8List value = await _channel.invokeMethod('generateQRCode',
          <String, dynamic>{'data': data, 'size': size, 'icon': icon});
      return Image.memory(
        value,
        width: size,
      );
    } on PlatformException catch (e) {
      throw 'Unable to generateQRCode $data: ${e.message}';
    }
  }
}
