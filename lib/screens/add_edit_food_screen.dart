import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/ai_service.dart';
import '../providers/food_provider.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

class AddEditFoodScreen extends ConsumerStatefulWidget {
  final FoodItem? foodItem;
  const AddEditFoodScreen({super.key, this.foodItem});

  @override
  ConsumerState<AddEditFoodScreen> createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends ConsumerState<AddEditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _tagCtrl;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  ExpiryType _expiryType = ExpiryType.strict;
  List<String> _tags = [];
  List<int> _reminders = [1];
  
  bool _isScanning = false;

  static const _predefinedTags = [
    'Latticini', 'Carne', 'Verdure', 'Frutta', 'Surgelati', 'Refrigerati',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.foodItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _tagCtrl = TextEditingController();
    if (item != null) {
      _expiryDate = item.expiryDate;
      _expiryType = item.expiryType;
      _tags = List.from(item.tags);
      _reminders = List.from(item.reminders);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final item = FoodItem(
        id: widget.foodItem?.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        expiryDate: _expiryDate,
        expiryType: _expiryType,
        tags: _tags,
        reminders: _reminders,
        createdAt: widget.foodItem?.createdAt,
      );
      final notifier = ref.read(foodListProvider.notifier);
      if (widget.foodItem == null) {
        notifier.addItem(item);
      } else {
        notifier.updateItem(item);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _addTag(String val) {
    val = val.trim();
    if (val.isNotEmpty && !_tags.contains(val)) {
      setState(() { _tags.add(val); _tagCtrl.clear(); });
    }
  }

  Future<void> _pickImageAndScan() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Scatta foto', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Scegli dalla galleria', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;
      
      setState(() => _isScanning = true);
      
      final result = await AiService.extractFoodInfo(image);
      if (result != null) {
        setState(() {
          if (result.name.isNotEmpty) _nameCtrl.text = result.name;
          if (result.description.isNotEmpty) _descCtrl.text = result.description;
          if (result.expirationDate != null) _expiryDate = result.expirationDate!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dati estratti con successo!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.urgent),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.foodItem != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Modifica alimento' : 'Aggiungi alimento'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Salva',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [

            // ── AI Scanner ──
            if (!isEditing) ...[
              InkWell(
                onTap: _isScanning ? null : _pickImageAndScan,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _isScanning
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isScanning ? 'Analisi in corso...' : 'Scansiona etichetta con IA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (!_isScanning)
                              const Text(
                                'Compila in automatico con una foto',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Name ──
            _FormSection(
              label: 'Nome *',
              child: TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(hintText: 'Inserisci il nome dell\'alimento'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Il nome è obbligatorio' : null,
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ──
            _FormSection(
              label: 'Descrizione',
              child: TextFormField(
                controller: _descCtrl,
                decoration:
                    const InputDecoration(hintText: 'Descrizione facoltativa...'),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),

            // ── Expiration Date ──
            _FormSection(
              label: 'Data di scadenza',
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy', 'it').format(_expiryDate),
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const Icon(Icons.calendar_month_outlined,
                          size: 20, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Expiration Type ──
            _FormSection(
              label: 'Tipo di scadenza',
              child: _SegmentedToggle(
                options: ExpiryType.values.map((e) => e.label).toList(),
                selectedIndex: ExpiryType.values.indexOf(_expiryType),
                onChanged: (i) =>
                    setState(() => _expiryType = ExpiryType.values[i]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tags ──
            _FormSection(
              label: 'Tag',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._predefinedTags.map((tag) {
                        final selected = _tags.contains(tag);
                        return _ToggleTagChip(
                          label: tag,
                          selected: selected,
                          onTap: () => setState(() {
                            selected ? _tags.remove(tag) : _tags.add(tag);
                          }),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Custom tag row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagCtrl,
                          decoration: const InputDecoration(
                            hintText: '+ Nuovo tag',
                            isDense: true,
                          ),
                          onSubmitted: _addTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: AppColors.primary),
                        onPressed: () => _addTag(_tagCtrl.text),
                      ),
                    ],
                  ),
                  // Custom tags (non-predefined)
                  if (_tags.any((t) => !_predefinedTags.contains(t))) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .where((t) => !_predefinedTags.contains(t))
                          .map((t) => Chip(
                                label: Text(t),
                                onDeleted: () =>
                                    setState(() => _tags.remove(t)),
                                deleteIconColor: AppColors.textSecondary,
                                backgroundColor: AppColors.chipBg,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Reminders ──
            _FormSection(
              label: 'Promemoria',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [0, 1, 2, 3, 5, 7].map((d) {
                  final selected = _reminders.contains(d);
                  return _ToggleTagChip(
                    label: d == 0
                        ? 'Lo stesso giorno'
                        : '$d giorn${d == 1 ? 'o' : 'i'} prima',
                    selected: selected,
                    onTap: () => setState(() {
                      selected ? _reminders.remove(d) : _reminders.add(d);
                    }),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // ── Save button ──
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navActive,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isEditing ? 'Salva modifiche' : 'Aggiungi alla dispensa',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Reusable form section with label
// ───────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ───────────────────────────────────────────────
//  Segmented toggle (Use By / Best Before)
// ───────────────────────────────────────────────
class _SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedToggle({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: options.asMap().entries.map((e) {
          final selected = e.key == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Toggle tag chip (tap to select/deselect)
// ───────────────────────────────────────────────
class _ToggleTagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.chipText,
          ),
        ),
      ),
    );
  }
}
