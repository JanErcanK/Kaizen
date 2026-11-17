import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/open_food_facts_service.dart';
import 'food_barcode_scan_screen.dart';

typedef FoodBarcodeLookup =
    Future<ScannedFoodProduct?> Function(String barcode);

/// Shared camera/manual-entry and lookup flow for Food and Chat.
Future<ScannedFoodProduct?> scanFoodProduct(
  BuildContext context, {
  FoodBarcodeLookup? lookup,
}) async {
  FocusScope.of(context).unfocus();
  final barcode = await Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const FoodBarcodeScanScreen()),
  );
  if (!context.mounted || barcode == null || barcode.trim().isEmpty) {
    return null;
  }
  return showDialog<ScannedFoodProduct>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProductLookupDialog(
      barcode: barcode,
      lookup: lookup ?? OpenFoodFactsService.lookupBarcode,
    ),
  );
}

class _ProductLookupDialog extends StatefulWidget {
  const _ProductLookupDialog({required this.barcode, required this.lookup});
  final String barcode;
  final FoodBarcodeLookup lookup;

  @override
  State<_ProductLookupDialog> createState() => _ProductLookupDialogState();
}

class _ProductLookupDialogState extends State<_ProductLookupDialog> {
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final product = await widget.lookup(widget.barcode);
      // A cancelled request must never close a later route or open a result.
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (product != null) {
        Navigator.of(context).pop(product);
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    return AlertDialog(
      title: Text(context.l10n.food_barcodeScanTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ],
          Text(
            _loading
                ? context.l10n.food_barcodeLookingUp
                : _failed
                ? (de
                      ? 'Verbindung fehlgeschlagen. Prüfe deine Internetverbindung und versuche es erneut.'
                      : 'Could not connect. Check your internet connection and try again.')
                : context.l10n.food_barcodeNotFound,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(de ? 'Abbrechen' : 'Cancel'),
        ),
        if (!_loading && _failed)
          FilledButton(
            onPressed: _load,
            child: Text(de ? 'Erneut versuchen' : 'Try again'),
          ),
      ],
    );
  }
}
