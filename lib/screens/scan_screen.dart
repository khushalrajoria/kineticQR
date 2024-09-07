import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';


class ScanScreen extends StatefulWidget {
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedData;
  bool isURL = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (mounted) {
        controller.pauseCamera();
        setState(() {
          scannedData = scanData.code;
          isURL = _isURL(scannedData);
        });
      }
    });
  }

  bool _isURL(String? data) {
    if (data == null) return false;
    final uri = Uri.tryParse(data);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  void _openURL() async {
    if (scannedData != null && await canLaunch(scannedData!)) {
      await launch(scannedData!);
    } else {
      Fluttertoast.showToast(msg: "Cannot open the URL.");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _scanAgain() {
    setState(() {
      scannedData = null;
    });
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
      ),
      body: scannedData == null
          ? QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Theme.of(context).primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            )
          : _buildResult(),
    );
  }

  Widget _buildResult() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scanned Data:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            SelectableText(
              scannedData ?? '',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (isURL)
              ElevatedButton(
                onPressed: _openURL,
                child: Text('Open in Browser'),
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scanAgain,
              child: Text('Scan Again'),
            ),
          ],
        ),
      ),
    );
  }
}
