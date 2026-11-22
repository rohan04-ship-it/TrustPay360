import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool scanned = false;

  String message = 'Position the customer QR inside the frame';

  void detectQr(BarcodeCapture capture) {
    if (scanned || !mounted) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value == null) continue;

      if (!value.startsWith('TRUSTPAY360:')) {
        setState(() {
          message = 'Invalid QR. Scan a TrustPay 360 QR.';
        });
        continue;
      }

      final customerId = value.substring('TRUSTPAY360:'.length).trim();

      if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(customerId)) {
        setState(() {
          message = 'Invalid Customer ID';
        });
        continue;
      }

      scanned = true;

      Navigator.pop(context, customerId);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1330),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1330),
        foregroundColor: Colors.white,
        title: const Text('Scan Customer QR'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(onDetect: detectQr),
                IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF59F0B5),
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
