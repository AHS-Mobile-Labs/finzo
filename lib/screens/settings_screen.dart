import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/currency_model.dart';
import '../providers/finance_provider.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Profile Section ──────────────────────────────────────
          const _SectionTitle(title: 'Profile'),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withAlpha(38),
                child: Text(
                  provider.userName.isNotEmpty
                      ? provider.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                provider.userName.isNotEmpty ? provider.userName : 'Set Name',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Tap to change',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              trailing: const Icon(
                Icons.edit_rounded,
                color: Colors.white38,
                size: 18,
              ),
              onTap: () => _showNameDialog(context, provider),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Currency Section ─────────────────────────────────────
          const _SectionTitle(title: 'Currency'),
          const SizedBox(height: 8),
          _CurrencySelector(
            current: provider.currency,
            onChanged: (c) => provider.setCurrency(c),
          ),
          const SizedBox(height: 24),

          // ─── Database Section ─────────────────────────────────────
          const _SectionTitle(title: 'Database'),
          const SizedBox(height: 8),
          _DatabaseSection(provider: provider),
          const SizedBox(height: 24),

          // ─── About Section ────────────────────────────────────────
          const _SectionTitle(title: 'About'),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finzo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Offline Personal Finance Manager',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNameDialog(BuildContext context, FinanceProvider provider) {
    final ctrl = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Your Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                provider.setUserName(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _DatabaseSection extends StatelessWidget {
  final FinanceProvider provider;
  const _DatabaseSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            title: Text(
              provider.currentBookName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Current book',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          FutureBuilder<String?>(
            future: provider.currentDbPath,
            builder: (context, snap) {
              if (!snap.hasData || snap.data == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        snap.data!,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          ListTile(
            leading: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white54,
              size: 20,
            ),
            title: const Text('Switch Book', style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => _showSwitchBookSheet(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.add_rounded,
              color: Colors.white54,
              size: 20,
            ),
            title: const Text(
              'Create New Book',
              style: TextStyle(fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => _showCreateBookDialog(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.file_download_outlined,
              color: Colors.white54,
              size: 20,
            ),
            title: const Text('Import Book', style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => _importBook(context),
          ),
        ],
      ),
    );
  }

  void _showSwitchBookSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: .78,
        child: _BookListSheet(provider: provider),
      ),
    );
  }

  void _showCreateBookDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Create New Book'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter book name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await provider.createNewBook(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created and switched to "$name"')),
                  );
                }
              }
            },
            child: const Text('Create & Switch'),
          ),
        ],
      ),
    );
  }

  Future<void> _importBook(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;
      final sourcePath = result.files.single.path!;
      if (!sourcePath.endsWith('.books.db')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid .books.db file'),
            ),
          );
        }
        return;
      }
      final bookName = await DatabaseService.importBook(sourcePath);
      await provider.switchBook(bookName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported and switched to "$bookName"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}

class _BookListSheet extends StatefulWidget {
  final FinanceProvider provider;
  const _BookListSheet({required this.provider});

  @override
  State<_BookListSheet> createState() => _BookListSheetState();
}

class _BookListSheetState extends State<_BookListSheet> {
  List<String> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await widget.provider.listBooks();
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.provider.currentBookName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Switch Book',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_books.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No books found',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (_, i) {
                  final book = _books[i];
                  final isActive = book == current;
                  return ListTile(
                    leading: Icon(
                      Icons.menu_book_rounded,
                      color: isActive ? AppTheme.primaryColor : Colors.white38,
                    ),
                    title: Text(
                      book,
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isActive ? AppTheme.primaryColor : Colors.white,
                      ),
                    ),
                    trailing: isActive
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 20,
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white24,
                              size: 20,
                            ),
                            onPressed: () => _confirmDelete(context, book),
                          ),
                    onTap: isActive
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await widget.provider.switchBook(book);
                          },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String bookName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Book?'),
        content: Text(
          'This will permanently delete "$bookName" and all its data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await widget.provider.deleteBook(bookName);
              if (ok) {
                _loadBooks();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$bookName" deleted')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final CurrencyModel current;
  final ValueChanged<CurrencyModel> onChanged;

  const _CurrencySelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(current.symbol, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(
              current.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              current.code,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => _showPicker(context),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: .82,
        child: _CurrencyPickerSheet(
          current: current,
          onSelect: (c) {
            onChanged(c);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final CurrencyModel current;
  final ValueChanged<CurrencyModel> onSelect;
  const _CurrencyPickerSheet({required this.current, required this.onSelect});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = CurrencyModel.supported.where((c) {
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.symbol.contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Currency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search currency...',
              prefixIcon: Icon(Icons.search, color: Colors.white38),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                final isSelected = c.code == widget.current.code;
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          (isSelected ? AppTheme.primaryColor : Colors.white12)
                              .withAlpha(isSelected ? 50 : 25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(c.symbol, style: const TextStyle(fontSize: 16)),
                  ),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    c.code,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                          size: 20,
                        )
                      : null,
                  onTap: () => widget.onSelect(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
