import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'qrcode_controller.dart';

class QRCode extends StatefulWidget {
  final Function(String) resultCallback;
  final QRcodeController controller;
  const QRCode(
      {Key? key, required this.controller, required this.resultCallback})
      : super(key: key);

  @override
  _QRCodeState createState() => _QRCodeState();
}

class _QRCodeState extends State<QRCode> {
  bool hasLoadTexture = false;
  @override
  void initState() {
    super.initState();
    widget.controller.setMethodCallHandler(handelCall);
    _init();
  }

  @override
  dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  Future<dynamic> handelCall(MethodCall methodCall) async {
    Map<String, String> map = {};
    if (methodCall.method == "result") {
      widget.resultCallback(methodCall.arguments);
    }
    return Future.value(map);
  }

  void _init() async {
    await widget.controller.initialize();
    setState(() {
      hasLoadTexture = true;
    });
  }

  Widget getTextureBody(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: widget.controller.buildPreview(),
        ),
        Positioned(
          child: _ScanFrame(lineColor: Color(0xff5857bc)),
        ),
        Positioned(
          child: Text(
            "将二维码放入框内,即可自动扫描",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          left: 30,
          right: 30,
          bottom: 220,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body = hasLoadTexture ? getTextureBody(context) : Text('初始化中...');
    return Container(
      child: body,
    );
  }
}

class _ScanFrame extends StatefulWidget {
  final Color lineColor;
  const _ScanFrame({Key? key, this.lineColor = Colors.blue}) : super(key: key);

  @override
  _ScanFrameState createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame> with TickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _controller;

  //起始之间的线性插值器 从 0.05 到 0.95 百分比。
  final Tween<double> _rotationTween = Tween(begin: 0.05, end: 0.95);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this, //实现 TickerProviderStateMixin
      duration: Duration(seconds: 3),
    );

    _animation = _rotationTween.animate(_controller)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.repeat();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    // 释放动画资源
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanFramePainter(
          lineMoveValue: _animation.value, lineColor: widget.lineColor),
      child: Container(),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  // 百分比值，0 ~ 1，然后计算Y坐标
  final double lineMoveValue;
  final Color lineColor;
  _ScanFramePainter({required this.lineMoveValue, required this.lineColor});

  //默认定义扫描框为 260边长的正方形
  final Size frameSize = Size.square(260.0);

  @override
  void paint(Canvas canvas, Size size) {
    // 按扫描框居中来计算，全屏尺寸与扫描框尺寸的差集 除以 2 就是扫描框的位置
    Offset diff =
        Offset(size.width - frameSize.width, (size.height - frameSize.height));
    double leftTopX = diff.dx / 2;
    double leftTopY = diff.dy / 2;
    //根据左上角的坐标和扫描框的大小可得知扫描框矩形
    var rect =
        Rect.fromLTWH(leftTopX, leftTopY, frameSize.width, frameSize.height);
    // 4个点的坐标
    Offset leftTop = rect.topLeft;
    Offset leftBottom = rect.bottomLeft;
    Offset rightTop = rect.topRight;
    Offset rightBottom = rect.bottomRight;
    final double cornerLength = 16.0;

    //画笔
    Paint paint = Paint()
      ..color = Color(0x40FFFFFF)
      ..style = PaintingStyle.fill;
    //左侧矩形
    canvas.drawRect(Rect.fromLTRB(0, 0, leftTopX, size.height), paint);
    //右侧矩形
    canvas.drawRect(
      Rect.fromLTRB(rightTop.dx, 0, size.width, size.height),
      paint,
    );
    //中上矩形
    canvas.drawRect(Rect.fromLTRB(leftTopX, 0, rightTop.dx, leftTopY), paint);
    //中下矩形
    canvas.drawRect(
      Rect.fromLTRB(leftBottom.dx, leftBottom.dy, rightBottom.dx, size.height),
      paint,
    );

    // 重新设置画笔
    paint
      ..color = lineColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square // 解决因为线宽导致交界处不是直角的问题
      ..style = PaintingStyle.stroke;

    // 横向线条的坐标偏移
    Offset horizontalOffset = Offset(cornerLength, 0);
    // 纵向线条的坐标偏移
    Offset verticalOffset = Offset(0, cornerLength);
    // 左上角
    canvas.drawLine(leftTop, leftTop + horizontalOffset, paint);
    canvas.drawLine(leftTop, leftTop + verticalOffset, paint);
    // 左下角
    canvas.drawLine(leftBottom, leftBottom + horizontalOffset, paint);
    canvas.drawLine(leftBottom, leftBottom - verticalOffset, paint);
    // 右上角
    canvas.drawLine(rightTop, rightTop - horizontalOffset, paint);
    canvas.drawLine(rightTop, rightTop + verticalOffset, paint);
    // 右下角
    canvas.drawLine(rightBottom, rightBottom - horizontalOffset, paint);
    canvas.drawLine(rightBottom, rightBottom - verticalOffset, paint);

    //修改画笔线条宽度
    paint.strokeWidth = 2;
    // 扫描线的移动值
    var lineY = leftTopY + frameSize.height * lineMoveValue;
    // 10 为线条与方框之间的间距，绘制扫描线
    canvas.drawLine(
      Offset(leftTopX + 10.0, lineY),
      Offset(rightTop.dx - 10.0, lineY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
