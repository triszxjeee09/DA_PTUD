import 'package:flutter/material.dart';

/// Bộ lọc nâng cao: giá, dạng bào chế, đối tượng, nhà sản xuất, đánh giá, tồn kho, sắp xếp.
///
/// Trả về `Map<String, dynamic>` các tham số truy vấn gửi lên API (map rỗng = bỏ lọc).
class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({super.key, required this.initial});

  final Map<String, dynamic> initial;

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> initial,
  ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ProductFilterSheet(initial: initial),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _PriceRange {
  const _PriceRange(this.label, this.min, this.max);

  final String label;
  final double? min;
  final double? max;
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  static const List<_PriceRange> _prices = [
    _PriceRange('Dưới 50.000đ', null, 50000),
    _PriceRange('50.000đ - 200.000đ', 50000, 200000),
    _PriceRange('200.000đ - 500.000đ', 200000, 500000),
    _PriceRange('Trên 500.000đ', 500000, null),
  ];
  static const List<String> _forms = [
    'Viên nén',
    'Viên nang',
    'Siro',
    'Dung dịch',
    'Kem',
    'Viên sủi',
    'Thiết bị',
  ];
  static const Map<String, String> _audiences = {
    'Người lớn': 'Người lớn',
    'Trẻ em': 'Trẻ',
    'Phụ nữ mang thai': 'mang thai',
    'Người cao tuổi': 'cao tuổi',
  };
  static const Map<String, String> _sorts = {
    '': 'Mới nhất',
    'price_asc': 'Giá tăng dần',
    'price_desc': 'Giá giảm dần',
    'rating': 'Đánh giá cao',
  };

  late Map<String, dynamic> _filters;
  late final TextEditingController _manufacturer;

  @override
  void initState() {
    super.initState();
    _filters = {...widget.initial};
    _manufacturer = TextEditingController(
      text: widget.initial['manufacturer']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _manufacturer.dispose();
    super.dispose();
  }

  void _set(String key, Object? value) {
    setState(() {
      if (value == null || value == '') {
        _filters.remove(key);
      } else {
        _filters[key] = value;
      }
    });
  }

  bool _priceSelected(_PriceRange range) {
    return _filters['minPrice'] == range.min &&
        _filters['maxPrice'] == range.max;
  }

  void _togglePrice(_PriceRange range) {
    setState(() {
      if (_priceSelected(range)) {
        _filters.remove('minPrice');
        _filters.remove('maxPrice');
        return;
      }
      _filters.remove('minPrice');
      _filters.remove('maxPrice');
      if (range.min != null) {
        _filters['minPrice'] = range.min;
      }
      if (range.max != null) {
        _filters['maxPrice'] = range.max;
      }
    });
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    _section(
                      'Sắp xếp',
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final entry in _sorts.entries)
                            ChoiceChip(
                              label: Text(entry.value),
                              selected:
                                  (_filters['sort']?.toString() ?? '') ==
                                  entry.key,
                              onSelected: (_) => _set('sort', entry.key),
                            ),
                        ],
                      ),
                    ),
                    _section(
                      'Khoảng giá',
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final range in _prices)
                            FilterChip(
                              label: Text(range.label),
                              selected: _priceSelected(range),
                              onSelected: (_) => _togglePrice(range),
                            ),
                        ],
                      ),
                    ),
                    _section(
                      'Dạng bào chế',
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final form in _forms)
                            FilterChip(
                              label: Text(form),
                              selected: _filters['dosageForm'] == form,
                              onSelected: (selected) =>
                                  _set('dosageForm', selected ? form : null),
                            ),
                        ],
                      ),
                    ),
                    _section(
                      'Đối tượng sử dụng',
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final entry in _audiences.entries)
                            FilterChip(
                              label: Text(entry.key),
                              selected:
                                  _filters['targetAudience'] == entry.value,
                              onSelected: (selected) => _set(
                                'targetAudience',
                                selected ? entry.value : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _section(
                      'Nhà sản xuất / thương hiệu',
                      TextField(
                        controller: _manufacturer,
                        decoration: const InputDecoration(
                          hintText: 'VD: DHG Pharma, Sanofi...',
                        ),
                        onChanged: (value) =>
                            _set('manufacturer', value.trim()),
                      ),
                    ),
                    _section(
                      'Khác',
                      Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Đánh giá từ 4 sao'),
                            value: _filters['minRating'] != null,
                            onChanged: (value) =>
                                _set('minRating', value ? 4 : null),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Chỉ hiển thị sản phẩm còn hàng'),
                            value: _filters['inStock'] == true,
                            onChanged: (value) =>
                                _set('inStock', value ? true : null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(<String, dynamic>{}),
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(_filters),
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
