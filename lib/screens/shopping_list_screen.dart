import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shopping_list.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_segmented_tabs.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late ShoppingList _draft;
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  final _listScroll = ScrollController();
  bool _busy = false;
  bool get _de => Localizations.localeOf(context).languageCode == 'de';
  String _tr(String de, String en) => _de ? de : en;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.index == 1) FocusScope.of(context).unfocus();
    setState(() {});
  }

  ShoppingItem _blank() => ShoppingItem(id: newShoppingId('row'), text: '');

  void _loadDraft() {
    _draft = ProgressStore.shoppingDraft;
    if (_draft.items.isEmpty || _draft.items.last.text.isNotEmpty) {
      _draft = _draft.copyWith(items: [..._draft.items, _blank()]);
    }
  }

  Future<void> _persist() => ProgressStore.updateShoppingDraft(_draft);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                'Speichern fehlgeschlagen. Bitte erneut versuchen.',
                'Could not save. Please try again.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeItem(ShoppingItem item) {
    setState(
      () => _draft = _draft.copyWith(
        items: [
          for (final current in _draft.items)
            current.id == item.id ? item : current,
        ],
      ),
    );
    // Hive updates its in-memory state synchronously, including on route exit.
    unawaited(
      _persist().catchError((Object _) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tr(
                  'Der Zettel konnte nicht gespeichert werden.',
                  'The list could not be saved.',
                ),
              ),
            ),
          );
        }
      }),
    );
  }

  void _nextItem(int index) {
    final items = _draft.items.toList();
    if (index == items.length - 1 || items[index + 1].text.isNotEmpty) {
      items.insert(index + 1, _blank());
      setState(() => _draft = _draft.copyWith(items: items));
      unawaited(_persist());
    }
    final nextId = items[index + 1].id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focus = _focusNodes[nextId];
      if (focus != null) {
        focus.requestFocus();
      } else if (_listScroll.hasClients) {
        _listScroll.jumpTo(_listScroll.position.maxScrollExtent);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNodes[nextId]?.requestFocus();
        });
      }
    });
  }

  Future<void> _save() => _run(() async {
    FocusScope.of(context).unfocus();
    await _persist();
    await ProgressStore.saveShoppingDraft();
    if (!mounted) return;
    _draft = ProgressStore.shoppingDraft;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        content: Text(
          _tr('In „Meine Einkäufe“ gespeichert.', 'Saved in My purchases.'),
        ),
      ),
    );
  });

  Future<void> _clear() => _run(() async {
    final previous = _draft;
    await ProgressStore.clearShoppingDraft();
    if (!mounted) return;
    setState(_loadDraft);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        content: Text(_tr('Neuer, leerer Zettel.', 'New, empty list.')),
        action: SnackBarAction(
          label: _tr('Rückgängig', 'Undo'),
          onPressed: () {
            unawaited(
              _run(() async {
                // Preserve anything written since clearing before restoring the list.
                await _persist();
                await ProgressStore.saveShoppingDraft();
                await ProgressStore.updateShoppingDraft(previous);
                if (mounted) setState(_loadDraft);
              }),
            );
          },
        ),
      ),
    );
  });

  Future<void> _rename(ShoppingList list) async {
    var name = list.name;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Einkauf umbenennen', 'Rename purchase')),
        content: TextFormField(
          initialValue: name,
          autofocus: true,
          onChanged: (value) => name = value,
          onFieldSubmitted: (value) => Navigator.pop(ctx, value),
          decoration: InputDecoration(labelText: _tr('Name', 'Name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Abbrechen', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, name),
            child: Text(_tr('Speichern', 'Save')),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty || !mounted) return;
    await _run(() async {
      await ProgressStore.renameShoppingList(list.id, result);
      if (mounted) setState(_loadDraft);
    });
  }

  Future<void> _delete(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Einkauf löschen?', 'Delete purchase?')),
        content: Text(list.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr('Abbrechen', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_tr('Löschen', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await ProgressStore.deleteShoppingList(list.id);
      if (mounted) setState(_loadDraft);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _listScroll.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focus in _focusNodes.values) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      leadingWidth: 44,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: AppSegmentedTabs(
          controller: _tabs,
          accent: AppColors.nutrition,
          labels: [
            _tr('Zettel', 'List'),
            _tr('Meine Einkäufe', 'My purchases'),
          ],
        ),
      ),
    ),
    body: TabBarView(controller: _tabs, children: [_editor(), _history()]),
  );

  Widget _editor() => Column(
    children: [
      Expanded(
        child: ListView.builder(
          controller: _listScroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: _draft.items.length,
          itemBuilder: (context, index) {
            final item = _draft.items[index];
            final controller = _controllers.putIfAbsent(
              item.id,
              () => TextEditingController(text: item.text),
            );
            final focus = _focusNodes.putIfAbsent(item.id, FocusNode.new);
            if (controller.text != item.text) controller.text = item.text;
            return Container(
              key: ValueKey(item.id),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.stroke.withValues(alpha: .7),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: item.checked,
                    onChanged: item.text.trim().isEmpty
                        ? null
                        : (value) => _changeItem(item.copyWith(checked: value)),
                  ),
                  Expanded(
                    child: TextField(
                      key: ValueKey('shopping-item-$index'),
                      controller: controller,
                      focusNode: focus,
                      autofocus: index == 0 && _draft.isEmpty,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        fontSize: 17,
                        color: item.checked
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: item.checked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      decoration: InputDecoration(
                        hintText: index == 0
                            ? _tr('Erstes Item', 'First item')
                            : _tr('Einfach losschreiben …', 'Start writing …'),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      onChanged: (text) =>
                          _changeItem(item.copyWith(text: text)),
                      onSubmitted: (_) => _nextItem(index),
                    ),
                  ),
                  if (item.text.isNotEmpty)
                    IconButton(
                      tooltip: _tr('Eintrag entfernen', 'Remove item'),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        final items = _draft.items
                            .where((row) => row.id != item.id)
                            .toList();
                        if (items.isEmpty) items.add(_blank());
                        setState(() => _draft = _draft.copyWith(items: items));
                        unawaited(_persist());
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: _busy
                    ? null
                    : () => _nextItem(_draft.items.length - 1),
                tooltip: _tr('Neuer Eintrag', 'New item'),
                icon: const Icon(Icons.add),
              ),
              const Spacer(),
              IconButton(
                onPressed: _busy || _draft.isEmpty ? null : _clear,
                tooltip: _tr('Zettel löschen', 'Clear list'),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy || _draft.isEmpty ? null : _save,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(_tr('Speichern', 'Save')),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _history() {
    final history = ProgressStore.shoppingHistory;
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _tr(
              'Deine gespeicherten Einkaufszettel erscheinen hier.',
              'Your saved shopping lists will appear here.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      buildDefaultDragHandles: false,
      itemCount: history.length,
      onReorderItem: (oldIndex, newIndex) => unawaited(
        _run(() => ProgressStore.reorderShoppingLists(oldIndex, newIndex)),
      ),
      itemBuilder: (context, index) {
        final list = history[index];
        final items = list.items.where((item) => item.text.trim().isNotEmpty);
        return Card(
          key: ValueKey(list.id),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          color: AppColors.card,
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 4, right: 8),
            leading: ReorderableDragStartListener(
              index: index,
              child: Tooltip(
                message: _tr('Reihenfolge ändern', 'Change order'),
                child: SizedBox(
                  width: 40,
                  height: 48,
                  child: Icon(Icons.drag_indicator, color: AppColors.textMuted),
                ),
              ),
            ),
            title: Text(list.name),
            subtitle: Text(
              '${DateFormat.yMd(_de ? 'de' : 'en').format(list.updatedAt)}'
              ' · ${items.where((item) => item.checked).length}/${items.length}',
            ),
            onTap: _busy
                ? null
                : () => _run(() async {
                    await _persist();
                    await ProgressStore.openShoppingList(list.id);
                    if (!mounted) return;
                    setState(_loadDraft);
                    _tabs.animateTo(0);
                  }),
            trailing: PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: (value) =>
                  value == 'rename' ? _rename(list) : _delete(list),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Text(_tr('Umbenennen', 'Rename')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(_tr('Löschen', 'Delete')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
