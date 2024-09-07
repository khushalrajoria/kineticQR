import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class GenerateScreen extends StatefulWidget {
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final GlobalKey qrKey = GlobalKey();
  String selectedType = 'URL';
  final TextEditingController inputController = TextEditingController();
  String? qrData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ['URL', 'Text', 'Contact', 'Wi-Fi']
                  .map((type) => DropdownMenuItem(
                        child: Text(type),
                        value: type,
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedType = val!;
                  inputController.clear();
                  qrData = null;
                });
              },
              decoration: const InputDecoration(labelText: 'Select Data Type'),
            ),
            const SizedBox(height: 10),
            _buildInputFields(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateQR,
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 20),
           if (qrData != null)
  RepaintBoundary(
    key: qrKey,
    child: CustomPaint(
      size: Size.square(200.0),
      painter: QrPainter(
        data: qrData!,
        version: QrVersions.auto,
        gapless: false,
      ),
    ),
  ),

            const SizedBox(height: 20),
            if (qrData != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveQR,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _shareQR,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    switch (selectedType) {
      case 'URL':
        return TextFormField(
          controller: inputController,
          decoration: const InputDecoration(labelText: 'Enter URL'),
          keyboardType: TextInputType.url,
        );
      case 'Text':
        return TextFormField(
          controller: inputController,
          decoration: const InputDecoration(labelText: 'Enter Text'),
        );
      case 'Contact':
        return TextFormField(
          controller: inputController,
          decoration: const InputDecoration(labelText: 'Enter Contact Info'),
        );
      case 'Wi-Fi':
        return Column(
          children: [
            TextFormField(
              controller: inputController,
              decoration: const InputDecoration(labelText: 'Enter Wi-Fi SSID'),
            ),
            // Add more fields for password, encryption if needed
          ],
        );
      default:
        return Container();
    }
  }

  void _generateQR() {
    String data = inputController.text.trim();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter data')),
      );
      return;
    }

    // Depending on type, format data accordingly
    switch (selectedType) {
      case 'URL':
        // Validate URL
        if (!_isValidURL(data)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid URL')),
          );
          return;
        }
        break;
      case 'Wi-Fi':
        // Here you would format the Wi-Fi QR code string
        data = 'WIFI:S:$data;T:WPA;P:password;;'; // Example
        break;
      case 'Contact':
        // Format as vCard
        data = _formatVCard(data);
        break;
      // Add other cases if needed
    }

    setState(() {
      qrData = data;
    });
  }

  bool _isValidURL(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  String _formatVCard(String contactInfo) {
    // Simple vCard formatting; in real scenario, parse contact info properly
    return '''
BEGIN:VCARD
VERSION:3.0
FN:$contactInfo
END:VCARD
''';
  }

  Future<void> _saveQR() async {
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR Code saved to $path')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save QR Code')),
      );
    }
  }

  Future<void> _shareQR() async {
  try {
    RenderRepaintBoundary boundary =
        qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(pngBytes);

    // Fix: Wrap file path in XFile
    await Share.shareXFiles([XFile(path)], text: 'Here is my QR Code!');
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to share QR Code')),
    );
  }
}

}
