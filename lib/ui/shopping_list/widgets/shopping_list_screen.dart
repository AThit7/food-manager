import 'package:flutter/material.dart';
import 'package:food_manager/ui/shopping_list/view_models/shopping_list_viewmodel.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({
    super.key,
    required this.viewModel,
  });

  final ShoppingListViewmodel viewModel;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<String> _selected = {};
  DateTime until = DateUtils.dateOnly(DateTime.now());
  bool groupByTag = false;

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  String _fmtDatePretty(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final wd = weekdays[(d.weekday - DateTime.monday) % 7];
    return '$wd, ${d.day} ${months[d.month-1]}';
  }

  Future<void> _showPreferencesSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (context) {
        DateTime tempUntil = until;
        bool tempGroupByTag = groupByTag;

        return StatefulBuilder(
          builder: (context, setStateLocal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Shopping date'),
                    subtitle: Text(_fmtDate(tempUntil)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempUntil,
                        firstDate: DateTime.now().subtract(Duration(days: 3)),
                        lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                      );
                      if (picked != null) {
                        setStateLocal(() => tempUntil = DateUtils.dateOnly(picked));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<bool>(
                    title: const Text("Group by date"),
                    value: false,
                    groupValue: tempGroupByTag,
                    onChanged: (v) => setStateLocal(() => tempGroupByTag = v!),
                  ),
                  RadioListTile<bool>(
                    title: const Text("Group by tag"),
                    value: true,
                    groupValue: tempGroupByTag,
                    onChanged: (v) => setStateLocal(() => tempGroupByTag = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            until = tempUntil;
                            groupByTag = tempGroupByTag;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Apply"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.getShoppingList();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping list"),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              onPressed: () => setState(_selected.clear),
              icon: const Icon(Icons.clear),
              tooltip: "Clear",
            ),
          ListenableBuilder(
            listenable:viewModel,
            builder: (context, child) {
              if (viewModel.entries != null && viewModel.entries!.isNotEmpty) {
                return IconButton(
                  onPressed: _selected.length == viewModel.entries!.length ? null : () =>
                      setState(() {
                        _selected.clear();
                        _selected.addAll(viewModel.entries!.map((e) => e.pantryItem.uuid));
                      }),
                  icon: const Icon(Icons.select_all),
                  tooltip: "Select all",
                );
              }
              return const SizedBox();
            },
          ),
          IconButton(
            tooltip: "Preferences",
            icon: const Icon(Icons.settings),
            onPressed: () => _showPreferencesSheet(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          if (viewModel.isLoading) {
            return const Center(child: Text('Generating shopping list'));
          } else if (viewModel.errorMessage != null) {
            return const Center(child: Text('Something went wrong.'));
          } else if (viewModel.entries != null) {
            final grouped = viewModel.getGroupedEntries(until, groupByTag: groupByTag);

            if (grouped.isEmpty) return const Center(child: Text('No items to buy.'));
            return ListView.builder(
              itemCount: grouped.length,
              itemBuilder: (context, i) {
                final group = grouped[i];
                final remaining = group.entries.where((e) => !_selected.contains(e.pantryItem.uuid)).length;
                final header = "${groupByTag ? group.tag : _fmtDatePretty(group.date!)} ($remaining)";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey("group_${groupByTag ? group.tag : group.date}"),
                      title: Text(header),
                      expansionAnimationStyle: AnimationStyle.noAnimation,
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: remaining == 0 ? null : () {
                                setState(() {
                                  for (final e in group.entries) {
                                    final id = e.pantryItem.uuid;
                                    if (!e.pantryItem.isBought) _selected.add(id);
                                  }
                                });
                              },
                              icon: const Icon(Icons.select_all),
                              label: const Text("Select"),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => setState(() {
                                for (final e in group.entries) {
                                  _selected.remove(e.pantryItem.uuid);
                                }
                              }),
                              icon: const Icon(Icons.clear),
                              label: const Text("Clear"),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        Column(
                          children: [
                            for (final e in group.entries) ...[
                              Builder(builder: (_) {
                                final id = e.pantryItem.uuid;
                                final disabled = e.pantryItem.isBought;
                                final checked = _selected.contains(id);
                    
                                return CheckboxListTile.adaptive(
                                  key: ValueKey(id),
                                  value: checked,
                                  onChanged: disabled ? null : (v) => setState(() {
                                    v == true ? _selected.add(id) : _selected.remove(id);
                                  }),
                                  title: Text(e.name),
                                  secondary: Text('${e.quantity.toString()} ${e.unit}'),
                                  controlAffinity: ListTileControlAffinity.leading,
                                );
                              }),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text("Unexpected error."));
          }
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _selected.isEmpty || viewModel.entries == null ? null : () async {
            final selectedEntries = viewModel.entries!.where((e) => _selected.contains(e.pantryItem.uuid))
                .toList(growable: false);

            await viewModel.buyItems(selectedEntries);

            if (viewModel.errorMessage != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.errorMessage!)),
              );
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Items added to the pantry")),
                );
              }
              setState(_selected.clear);
            }
          },
          icon: const Icon(Icons.shopping_cart_checkout),
          label: Text(
            _selected.isEmpty ? "Add" : "Add (${_selected.length})",
          ),
        ),
      ),
    );
  }
}