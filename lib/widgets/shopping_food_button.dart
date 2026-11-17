import 'package:flutter/material.dart';

import '../screens/shopping_list_screen.dart';
import '../services/progress_store.dart';

class ShoppingFoodButton extends StatefulWidget {
  const ShoppingFoodButton({
    super.key,
    required this.name,
    this.grams,
    this.compact = false,
    this.onAdded,
  });
  final String name;
  final double? grams;
  final bool compact;
  final VoidCallback? onAdded;

  @override
  State<ShoppingFoodButton> createState() => _ShoppingFoodButtonState();
}

class _ShoppingFoodButtonState extends State<ShoppingFoodButton> {
  bool _busy = false;
  bool _added = false;

  @override
  void didUpdateWidget(covariant ShoppingFoodButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name || oldWidget.grams != widget.grams) {
      _added = false;
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    final de = Localizations.localeOf(context).languageCode == 'de';
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ProgressStore.addShoppingItem(widget.name, grams: widget.grams);
      if (!mounted) return;
      setState(() => _added = true);
      widget.onAdded?.call();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            de
                ? '${widget.name} steht auf dem Zettel.'
                : '${widget.name} added to your list.',
          ),
          action: SnackBarAction(
            label: de ? 'Öffnen' : 'Open',
            onPressed: () {
              if (!navigator.mounted) return;
              navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => const ShoppingListScreen(),
                ),
              );
            },
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              de
                  ? 'Hinzufügen fehlgeschlagen. Bitte erneut versuchen.'
                  : 'Could not add the item. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    return OutlinedButton.icon(
      onPressed: _busy ? null : _add,
      style: widget.compact
          ? OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 11),
            )
          : null,
      icon: Icon(
        _added ? Icons.check_rounded : Icons.playlist_add_rounded,
        size: 17,
      ),
      label: Text(
        _added
            ? (de ? 'Auf dem Zettel' : 'On your list')
            : widget.compact
            ? (de ? 'Zettel' : 'List')
            : (de ? 'Auf den Einkaufszettel' : 'Add to shopping list'),
      ),
    );
  }
}
