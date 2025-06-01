import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';

class QrCodeService {
  /// Generates a QR code widget from the given text
  /// 
  /// [data] - The text to encode in the QR code (e.g., game code)
  /// [size] - The size of the QR code widget (default: 200.0)
  /// [backgroundColor] - Background color of the QR code (default: white)
  /// [foregroundColor] - Color of the QR code pattern (default: black)
  static Widget generateQrCode({
    required String data,
    double size = 200.0,
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
    String? embeddedImagePath,
    double? embeddedImageSize,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: const EdgeInsets.all(8.0),
      embeddedImage: embeddedImagePath != null ? AssetImage(embeddedImagePath) : null,
      embeddedImageStyle: embeddedImageSize != null 
          ? QrEmbeddedImageStyle(
              size: Size(embeddedImageSize, embeddedImageSize),
            )
          : null,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: false,
    );
  }

  /// Generates a QR code widget specifically for game codes
  /// Includes styling optimized for game room sharing
  static Widget generateGameCodeQr({
    required String gameCode,
    double size = 250.0,
  }) {
    print("🔍 Generating QR code for game code: $gameCode with size: $size");
    try {
      final qrWidget = Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan to Join Game',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            generateQrCode(
              data: gameCode,
              size: size,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                gameCode,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),
      );
      print("✅ QR widget generated successfully for game code: $gameCode");
      return qrWidget;
    } catch (e, stackTrace) {
      print("❌ Error generating QR widget: $e");
      print("❌ Stack trace: $stackTrace");
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text("Error generating QR code: $e"),
      );
    }
  }

  /// Shows a dialog with a QR code for the given data
  static void showQrCodeDialog({
    required BuildContext context,
    required String data,
    String title = 'QR Code',
    String? subtitle,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null) ...[
                  Text(subtitle),
                  const SizedBox(height: 16),
                ],
                generateQrCode(data: data),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    data,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog specifically for game code sharing
  static void showGameCodeDialog({
    required BuildContext context,
    required String gameCode,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share Game Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scan to Join Game',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 200,
                        height: 200,
                        child: QrImageView(
                          data: gameCode,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(8.0),
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          gapless: false,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          gameCode,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Validates if the given string is a valid format for QR code generation
  static bool isValidQrData(String data) {
    // Basic validation - QR codes can handle up to 4,296 alphanumeric characters
    if (data.isEmpty || data.length > 4296) {
      return false;
    }
    return true;
  }

  /// Creates a shareable QR code widget with additional information
  static Widget createShareableQrCode({
    required String data,
    required String title,
    String? description,
    double size = 200.0,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            generateQrCode(data: data, size: size),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                data,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a QR code scanner dialog
  static void showQrScannerDialog({
    required BuildContext context,
    required Function(String) onQrCodeScanned,
    String title = 'Scan QR Code',
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 300,
            height: 300,
            child: QrScannerWidget(
              onQrCodeScanned: (scannedCode) {
                Navigator.of(context).pop();
                onQrCodeScanned(scannedCode);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Opens a full-screen QR code scanner
  static void openQrScanner({
    required BuildContext context,
    required Function(String) onQrCodeScanned,
  }) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QrScannerScreen(
            onQrCodeScanned: onQrCodeScanned,
          ),
          settings: const RouteSettings(name: '/qr-scanner'),
        ),
      );
    } catch (e) {
      print("Error opening QR scanner: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening QR scanner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Widget for QR code scanning functionality
class QrScannerWidget extends StatefulWidget {
  final Function(String) onQrCodeScanned;

  const QrScannerWidget({
    super.key,
    required this.onQrCodeScanned,
  });

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  late MobileScannerController controller;
  bool hasScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: controller,
      onDetect: (capture) {
        if (!hasScanned && capture.barcodes.isNotEmpty) {
          final String? code = capture.barcodes.first.rawValue;
          if (code != null) {
            hasScanned = true;
            controller.stop();
            widget.onQrCodeScanned(code);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Full-screen QR code scanner
class QrScannerScreen extends StatefulWidget {
  final Function(String) onQrCodeScanned;

  const QrScannerScreen({
    super.key,
    required this.onQrCodeScanned,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late MobileScannerController controller;
  bool hasScanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Game Code'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // Explicitly disable FAB to prevent Hero conflicts
      floatingActionButton: null,
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (!hasScanned && capture.barcodes.isNotEmpty) {
                  final String? code = capture.barcodes.first.rawValue;
                  if (code != null) {
                    hasScanned = true;
                    controller.stop();
                    Navigator.of(context).pop();
                    widget.onQrCodeScanned(code);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Point your camera at the QR code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The game code will be automatically detected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Custom overlay shape for QR scanner (not used in mobile_scanner 5.2.3)
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength > borderWidthSize / 2 ? borderWidthSize / 2 : borderLength;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutSize / 2 + borderOffset,
      rect.top + height / 2 - mCutOutSize / 2 + borderOffset,
      mCutOutSize - borderOffset * 2,
      mCutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)), boxPaint)
      ..restore();

    // Draw corner borders
    final path = Path()
      // Top left
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset + mBorderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset + borderRadius)
      ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset,
          cutOutRect.left - borderOffset + borderRadius, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.left - borderOffset + mBorderLength, cutOutRect.top - borderOffset)
      // Top right
      ..moveTo(cutOutRect.right + borderOffset - mBorderLength, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.right + borderOffset - borderRadius, cutOutRect.top - borderOffset)
      ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset,
          cutOutRect.right + borderOffset, cutOutRect.top - borderOffset + borderRadius)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset + mBorderLength)
      // Bottom right
      ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset - mBorderLength)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset - borderRadius)
      ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset,
          cutOutRect.right + borderOffset - borderRadius, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.right + borderOffset - mBorderLength, cutOutRect.bottom + borderOffset)
      // Bottom left
      ..moveTo(cutOutRect.left - borderOffset + mBorderLength, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.left - borderOffset + borderRadius, cutOutRect.bottom + borderOffset)
      ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset,
          cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset - borderRadius)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset - mBorderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
} 