import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/errors.dart';
import '../core/l10n.dart';

/// Reads the invite code from a scanned QR payload: either the 6 digits or
/// an invite link such as `homeslot://app/join?code=123456`.
String? inviteCodeFrom(String raw) {
  final text = raw.trim();
  if (RegExp(r'^\d{6}$').hasMatch(text)) return text;
  final code = Uri.tryParse(text)?.queryParameters['code'];
  if (code != null && RegExp(r'^\d{6}$').hasMatch(code)) return code;
  return null;
}

/// Scans an invite QR code (`homeslot://app/join?code=123456` or 6 digits)
/// and returns the code.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final code = inviteCodeFrom(raw);
      if (code != null) {
        _done = true;
        context.pop(code);
        return;
      }
      showMessage(context, context.s.invalidQr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.s.scanTitle)),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              context.s.scanHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
