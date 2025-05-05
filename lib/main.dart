import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingItem {
  String name;
  bool isCompleted;
  bool isScheduled;
  bool isToday;
  DateTime? scheduledDate;

  ShoppingItem({
    required this.name,
    this.isCompleted = false,
    this.isScheduled = false,
    this.isToday = false,
    this.scheduledDate,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopping List',
      theme: ThemeData.dark(),
      home: const ShoppingListPage(),
    );
  }
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final Map<String, List<ShoppingItem>> categoryMap = {};

  // Getter methods to organize the data
  List<ShoppingItem> get allItems =>
      categoryMap.entries
          .where((e) => e.key != 'Completed')
          .expand((e) => e.value)
          .toList();

  List<ShoppingItem> get todayItems =>
      allItems
          .where(
            (i) =>
                (i.isToday ||
                    (i.scheduledDate != null &&
                        isSameDate(i.scheduledDate!, DateTime.now()))) &&
                !i.isCompleted,
          )
          .toList();

  List<ShoppingItem> get scheduledItems =>
      allItems
          .where(
            (i) =>
                i.isScheduled &&
                !i.isCompleted &&
                !(i.scheduledDate != null &&
                    isSameDate(i.scheduledDate!, DateTime.now())),
          )
          .toList();

  List<ShoppingItem> get completedItems => categoryMap['Completed'] ?? [];

  // Helper function to compare dates
  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Function to add a new category
  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty &&
                    !categoryMap.containsKey(controller.text)) {
                  setState(() {
                    categoryMap[controller.text] = [];
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to update the category name
  void _updateCategory(String oldCategoryName) {
    final controller = TextEditingController(text: oldCategoryName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    // Remove the old category and add the updated category
                    List<ShoppingItem> items = categoryMap[oldCategoryName]!;
                    categoryMap.remove(oldCategoryName);
                    categoryMap[controller.text] = items;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Category name cannot be empty"),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Function to open a page displaying the items of a category
  Future<void> _openInfoPage(String title, List<ShoppingItem> items) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => InfoListPage(
              title: title,
              items: items,
              onItemToggle: (item, value) async {
                if (title == 'Completed') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: const Text('Delete Item'),
                          content: Text('Delete "${item.name}" permanently?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    setState(() {
                      categoryMap.forEach((key, list) => list.remove(item));
                    });
                  }
                } else {
                  setState(() {
                    if (value) {
                      categoryMap.forEach((key, list) => list.remove(item));
                      item.isCompleted = true;
                      categoryMap['Completed'] ??= [];
                      categoryMap['Completed']!.add(item);
                    }
                  });
                }
              },
            ),
      ),
    );
    setState(() {});
  }

  // Function to go to the category page
  Future<void> _goToCategoryPage(String category) async {
    final updated = await Navigator.push<List<ShoppingItem>>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                CategoryPage(category: category, items: categoryMap[category]!),
      ),
    );
    if (updated != null) {
      setState(() {
        categoryMap[category] = updated;
      });
    }
  }

  int get totalCount => allItems.length;
  int get todayCount => todayItems.length;
  int get scheduledCount => scheduledItems.length;
  int get completedCount => completedItems.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(icon: const Icon(Icons.add_box), onPressed: _addCategory),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return InfoCard(
                        title: 'Today',
                        count: todayCount,
                        onTap: () => _openInfoPage('Today', todayItems),
                      );
                    case 1:
                      return InfoCard(
                        title: 'Scheduled',
                        count: scheduledCount,
                        onTap: () => _openInfoPage('Scheduled', scheduledItems),
                      );
                    case 2:
                      return InfoCard(
                        title: 'All',
                        count: totalCount,
                        onTap: () => _openInfoPage('All', allItems),
                      );
                    default:
                      return InfoCard(
                        title: 'Completed',
                        count: completedCount,
                        onTap: () => _openInfoPage('Completed', completedItems),
                      );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount:
                    categoryMap.keys.where((k) => k != 'Completed').length,
                itemBuilder: (context, idx) {
                  final filteredKeys =
                      categoryMap.keys.where((k) => k != 'Completed').toList();
                  final category = filteredKeys[idx];
                  final items = categoryMap[category]!;
                  return ListTile(
                    title: Text(category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${items.length}'),
                        SizedBox(width: 10),

                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _updateCategory(category),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              () =>
                                  setState(() => categoryMap.remove(category)),
                        ),
                      ],
                    ),
                    onTap: () => _goToCategoryPage(category),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;

  const InfoCard({
    super.key,
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoListPage extends StatefulWidget {
  final String title;
  final List<ShoppingItem> items;
  final void Function(ShoppingItem, bool) onItemToggle;

  const InfoListPage({
    super.key,
    required this.title,
    required this.items,
    required this.onItemToggle,
  });

  @override
  State<InfoListPage> createState() => _InfoListPageState();
}

class _InfoListPageState extends State<InfoListPage> {
  late List<ShoppingItem> items;

  @override
  void initState() {
    super.initState();
    items = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    final isScheduledPage = widget.title == 'Scheduled';
    final isCompletedPage = widget.title == 'Completed';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            title: Text(item.name),
            subtitle:
                isScheduledPage && item.scheduledDate != null
                    ? Text(
                      item.scheduledDate!.toLocal().toString().split(' ')[0],
                    )
                    : null,
            trailing: Checkbox(
              value: isCompletedPage ? false : item.isCompleted,
              onChanged: (val) {
                widget.onItemToggle(item, val ?? false);
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}

class CategoryPage extends StatefulWidget {
  final String category;
  final List<ShoppingItem> items;

  const CategoryPage({super.key, required this.category, required this.items});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late List<ShoppingItem> items;

  @override
  void initState() {
    super.initState();
    items = widget.items;
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        bool isScheduled = false;
        DateTime? selectedDate;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  CheckboxListTile(
                    title: const Text('Scheduled'),
                    value: isScheduled,
                    onChanged:
                        (v) => setStateDialog(() => isScheduled = v ?? false),
                  ),
                  if (isScheduled)
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          setStateDialog(() => selectedDate = d);
                        }
                      },
                      child: Text(
                        selectedDate == null
                            ? 'Pick Date'
                            : selectedDate!.toLocal().toString().split(' ')[0],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Item name cannot be empty"),
                        ),
                      );
                    } else if (isScheduled && selectedDate != null) {
                      final newItem = ShoppingItem(
                        name: controller.text,
                        isScheduled: isScheduled,
                        scheduledDate: selectedDate,
                      );
                      setState(() => items.add(newItem));
                      Navigator.pop(context, items);
                    } else {
                      // If scheduled is selected but no date is picked, show a warning
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a scheduled date"),
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateItem(int index) {
    final controller = TextEditingController(text: items[index].name);
    bool isScheduled = items[index].isScheduled;
    DateTime? selectedDate = items[index].scheduledDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Update Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  CheckboxListTile(
                    title: const Text('Scheduled'),
                    value: isScheduled,
                    onChanged:
                        (v) => setStateDialog(() => isScheduled = v ?? false),
                  ),
                  if (isScheduled)
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          setStateDialog(() => selectedDate = d);
                        }
                      },
                      child: Text(
                        selectedDate == null
                            ? 'Pick Date'
                            : selectedDate!.toLocal().toString().split(' ')[0],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Item name cannot be empty"),
                        ),
                      );
                    } else if (isScheduled && selectedDate != null) {
                      setState(() {
                        items[index] = ShoppingItem(
                          name: controller.text,
                          isScheduled: isScheduled,
                          scheduledDate: selectedDate,
                        );
                      });
                      Navigator.pop(context);
                    } else {
                      // If scheduled is selected but no date is picked, show a warning
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a scheduled date"),
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text(
            'Are you sure you want to delete "${items[index].name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  items.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            title: Text(item.name),
            subtitle:
                item.scheduledDate != null
                    ? Text(
                      item.scheduledDate!.toLocal().toString().split(' ')[0],
                    )
                    : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _updateItem(i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteItem(i),
                ),
                Checkbox(
                  value: item.isCompleted,
                  onChanged: (bool? value) {
                    setState(() {
                      item.isCompleted = value ?? false;
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              // You can add additional functionality here if needed.
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
