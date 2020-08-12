import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class RoundedQRPainter extends CustomPainter {
  final String data;
  final int typeNumber;
  final int errorCorrectLevel;
  final Color moduleColor;
  final double moduleRadius;
  final Color backgroundColor;

  ui.Image image;
  int deletePixelCount = 0;

  QrCode _qrCode;

  RoundedQRPainter({
    @required this.data,
    @required this.typeNumber,
    @required this.errorCorrectLevel,
    @required this.moduleColor,
    @required this.moduleRadius,
    @required this.backgroundColor,
    this.image,
  }) {
    _qrCode = QrCode(typeNumber, errorCorrectLevel)
      ..addData(data)
      ..make();
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (image != null) {
      if (typeNumber <= 2) {
        deletePixelCount = typeNumber + 7;
      } else if (typeNumber <= 4) {
        deletePixelCount = typeNumber + 8;
      } else {
        deletePixelCount = typeNumber + 9;
      }

      var imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      var src = Alignment.center.inscribe(
        imageSize,
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );

      var dst = Alignment.center.inscribe(
        Size(
          size.height / 4,
          size.height / 4,
        ),
        Rect.fromLTWH(
          size.width / 3,
          size.height / 3,
          size.height / 3,
          size.height / 3,
        ),
      );

      canvas.drawImageRect(
        image,
        src,
        dst,
        Paint(),
      );
    }

    moduleRadius > 0.0
        ? _paintRound(canvas, size)
        : _paintDefault(canvas, size);
  }

  void _paintRound(
    Canvas canvas,
    Size size,
  ) {
    var _paint = Paint()
      ..style = PaintingStyle.fill
      ..color = moduleColor
      ..isAntiAlias = true;

    var _paintBackground = Paint()
      ..style = PaintingStyle.fill
      ..color = backgroundColor
      ..isAntiAlias = true;

    var matrix = List<List>(_qrCode.moduleCount + 2);

    for (var i = 0; i < _qrCode.moduleCount + 2; i++) {
      matrix[i] = List(_qrCode.moduleCount + 2);
    }

    for (var x = 0; x < _qrCode.moduleCount + 2; x++) {
      for (var y = 0; y < _qrCode.moduleCount + 2; y++) {
        matrix[x][y] = false;
      }
    }

    for (var x = 0; x < _qrCode.moduleCount; x++) {
      for (var y = 0; y < _qrCode.moduleCount; y++) {
        if (image != null &&
            x >= deletePixelCount &&
            y >= deletePixelCount &&
            x < _qrCode.moduleCount - deletePixelCount &&
            y < _qrCode.moduleCount - deletePixelCount) {
          matrix[y + 1][x + 1] = false;
          continue;
        }

        if (_qrCode.isDark(y, x)) {
          matrix[y + 1][x + 1] = true;
        } else {
          matrix[y + 1][x + 1] = false;
        }
      }
    }

    var pixelSize = size.width / _qrCode.moduleCount;

    for (var x = 0; x < _qrCode.moduleCount; x++) {
      for (var y = 0; y < _qrCode.moduleCount; y++) {
        if (matrix[y + 1][x + 1]) {
          final squareRect = Rect.fromLTWH(
            x * pixelSize,
            y * pixelSize,
            pixelSize,
            pixelSize,
          );

          _setShape(
            x + 1,
            y + 1,
            squareRect,
            _paint,
            matrix,
            canvas,
            _qrCode.moduleCount,
          );
        } else {
          _setShapeInner(
            x + 1,
            y + 1,
            _paintBackground,
            matrix,
            canvas,
            pixelSize,
          );
        }
      }
    }
  }

  void _drawCurve(
    Offset p1,
    Offset p2,
    Offset p3,
    Canvas canvas,
  ) {
    var path = Path();

    path.moveTo(
      p1.dx,
      p1.dy,
    );
    path.quadraticBezierTo(
      p2.dx,
      p2.dy,
      p3.dx,
      p3.dy,
    );
    path.lineTo(
      p2.dx,
      p2.dy,
    );
    path.lineTo(
      p1.dx,
      p1.dy,
    );
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = moduleColor,
    );
  }

  // rounding the inner corners (with the background color)
  void _setShapeInner(
    int x,
    int y,
    Paint paint,
    List matrix,
    Canvas canvas,
    double pixelSize,
  ) {
    final widthY = pixelSize * (y - 1);
    final heightX = pixelSize * (x - 1);

    // bottom right check
    if (matrix[y + 1][x] && matrix[y][x + 1] && matrix[y + 1][x + 1]) {
      final p1 = Offset(
        heightX + pixelSize - (0.25 * pixelSize),
        widthY + pixelSize,
      );
      final p2 = Offset(
        heightX + pixelSize,
        widthY + pixelSize,
      );
      final p3 = Offset(
        heightX + pixelSize,
        widthY + pixelSize - (0.25 * pixelSize),
      );

      _drawCurve(
        p1,
        p2,
        p3,
        canvas,
      );
    }

    // top left check
    if (matrix[y - 1][x] && matrix[y][x - 1] && matrix[y - 1][x - 1]) {
      final p1 = Offset(
        heightX,
        widthY + (0.25 * pixelSize),
      );
      final p2 = Offset(
        heightX,
        widthY,
      );
      final p3 = Offset(
        heightX + (0.25 * pixelSize),
        widthY,
      );

      _drawCurve(
        p1,
        p2,
        p3,
        canvas,
      );
    }

    // bottom left check
    if (matrix[y + 1][x] && matrix[y][x - 1] && matrix[y + 1][x - 1]) {
      final p1 = Offset(
        heightX,
        widthY + pixelSize - (0.25 * pixelSize),
      );
      final p2 = Offset(
        heightX,
        widthY + pixelSize,
      );
      final p3 = Offset(
        heightX + (0.25 * pixelSize),
        widthY + pixelSize,
      );

      _drawCurve(
        p1,
        p2,
        p3,
        canvas,
      );
    }

    // top right check
    if (matrix[y - 1][x] && matrix[y][x + 1] && matrix[y - 1][x + 1]) {
      final p1 = Offset(
        heightX + pixelSize - (0.25 * pixelSize),
        widthY,
      );
      final p2 = Offset(
        heightX + pixelSize,
        widthY,
      );
      final p3 = Offset(
        heightX + pixelSize,
        widthY + (0.25 * pixelSize),
      );

      _drawCurve(
        p1,
        p2,
        p3,
        canvas,
      );
    }
  }

  // round the corners and paint it
  void _setShape(
    int x,
    int y,
    Rect squareRect,
    Paint paint,
    List matrix,
    Canvas canvas,
    int n,
  ) {
    var bottomRight = false;
    var bottomLeft = false;
    var topRight = false;
    var topLeft = false;

    // if it is dot (arount an empty place)
    if (!matrix[y + 1][x] &&
        !matrix[y][x + 1] &&
        !matrix[y - 1][x] &&
        !matrix[y][x - 1]) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          squareRect,
          bottomRight: Radius.circular(moduleRadius / 2),
          bottomLeft: Radius.circular(moduleRadius / 2),
          topLeft: Radius.circular(moduleRadius / 2),
          topRight: Radius.circular(moduleRadius / 2),
        ),
        paint,
      );

      return;
    }

    // bottom right check
    if (!matrix[y + 1][x] && !matrix[y][x + 1]) {
      bottomRight = true;
    }

    // top left check
    if (!matrix[y - 1][x] && !matrix[y][x - 1]) {
      topLeft = true;
    }

    // bottom left check
    if (!matrix[y + 1][x] && !matrix[y][x - 1]) {
      bottomLeft = true;
    }

    // top right check
    if (!matrix[y - 1][x] && !matrix[y][x + 1]) {
      topRight = true;
    }

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        squareRect,
        bottomRight: bottomRight ? Radius.circular(moduleRadius) : Radius.zero,
        bottomLeft: bottomLeft ? Radius.circular(moduleRadius) : Radius.zero,
        topLeft: topLeft ? Radius.circular(moduleRadius) : Radius.zero,
        topRight: topRight ? Radius.circular(moduleRadius) : Radius.zero,
      ),
      paint,
    );

    // if it is dot (arount an empty place)
    if (!bottomLeft && !bottomRight && !topLeft && !topRight) {
      canvas.drawRect(
        squareRect,
        paint,
      );
    }
  }

  void _paintDefault(
    Canvas canvas,
    Size size,
  ) {
    var _paint = Paint()
      ..style = PaintingStyle.fill
      ..color = moduleColor
      ..isAntiAlias = true;

    // size of point
    final pixelSize = size.width / _qrCode.moduleCount;

    for (var x = 0; x < _qrCode.moduleCount; x++) {
      for (var y = 0; y < _qrCode.moduleCount; y++) {
        if (image != null &&
            x >= deletePixelCount &&
            y >= deletePixelCount &&
            x < _qrCode.moduleCount - deletePixelCount &&
            y < _qrCode.moduleCount - deletePixelCount) {
          continue;
        }

        if (_qrCode.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * pixelSize,
              y * pixelSize,
              pixelSize,
              pixelSize,
            ),
            _paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
