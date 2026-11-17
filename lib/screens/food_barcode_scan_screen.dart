import '../widgets/app_back_button.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_colors.dart';

/// Scans EAN/GTIN barcodes on mobile; manual entry on desktop.
class FoodBarcodeScanScreen extends StatefulWidget {
  const FoodBarcodeScanScreen({super.key});

  @override
  State<FoodBarcodeScanScreen> createState() => _FoodBarcodeScanScreenState();
}

class _FoodBarcodeScanScreenState extends State<FoodBarcodeScanScreen> {
  final TextEditingController _manualCtrl = TextEditingController();
  final MobileScannerController? _scannerController =
      Platform.isAndroid || Platform.isIOS
      ? MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        )
      : null;
  bool _handled = false;

  @override
  void dispose() {
    _manualCtrl.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _finish(String barcode) {
    if (_handled || barcode.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(barcode.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasCamera = _scannerController != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.food_barcodeScanTitle),
      ),
      body: Column(
        children: [
          if (hasCamera)
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      for (final barcode in capture.barcodes) {
                        final value = barcode.rawValue;
                        if (value != null && value.isNotEmpty) {
                          _finish(value);
                          break;
                        }
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Text(
                        l10n.food_barcodeScanHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Roboto',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              flex: 2,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 56,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.food_barcodeDesktopHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.food_barcodeManualLabel,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _manualCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Roboto',
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.food_barcodeManualHint,
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.stroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.stroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.nutrition),
                      ),
                    ),
                    onSubmitted: _finish,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _finish(_manualCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.actionBackground,
                      foregroundColor: AppColors.onAction,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n.food_barcodeLookupBtn,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
