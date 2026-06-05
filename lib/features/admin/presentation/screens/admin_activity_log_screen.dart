import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_activity_log_model.dart';
import '../../providers/admin_activity_log_provider.dart';

class AdminActivityLogScreen extends StatefulWidget {
  const AdminActivityLogScreen({super.key});

  @override
  State<AdminActivityLogScreen> createState() => _AdminActivityLogScreenState();
}

class _AdminActivityLogScreenState extends State<AdminActivityLogScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _actionController = TextEditingController();
  final _entityController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _didStart = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AdminActivityLogProvider>().loadLogs(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _actionController.dispose();
    _entityController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      final provider = context.read<AdminActivityLogProvider>();
      if (provider.hasMore && !provider.isLoading && !provider.isLoadingMore) {
        provider.loadLogs();
      }
    }
  }

  Future<void> _applyFilters() {
    return context.read<AdminActivityLogProvider>().loadLogs(
      refresh: true,
      keyword: _searchController.text,
      action: _actionController.text,
      entityName: _entityController.text,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  Future<void> _pickFromDate() async {
    final date = await _pickDate(_fromDate ?? DateTime.now());
    if (date == null || !mounted) {
      return;
    }

    setState(() => _fromDate = date);
    await _applyFilters();
  }

  Future<void> _pickToDate() async {
    final date = await _pickDate(_toDate ?? DateTime.now());
    if (date == null || !mounted) {
      return;
    }

    setState(() => _toDate = date);
    await _applyFilters();
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
  }

  void _clearFilters() {
    _searchController.clear();
    _actionController.clear();
    _entityController.clear();
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    context.read<AdminActivityLogProvider>().clearFilters();
  }

  void _openDetail(AdminActivityLogModel log) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ActivityLogDetailSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    final provider = context.watch<AdminActivityLogProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử hoạt động')),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _applyFilters,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ActivityLogFilters(
              searchController: _searchController,
              actionController: _actionController,
              entityController: _entityController,
              fromDate: _fromDate,
              toDate: _toDate,
              isLoading: provider.isLoading,
              onSearch: _applyFilters,
              onChanged: () => setState(() {}),
              onPickFromDate: _pickFromDate,
              onPickToDate: _pickToDate,
              onClearFilters: _clearFilters,
            ),
            const SizedBox(height: 16),
            if (provider.isLoading && provider.logs.isEmpty)
              const SizedBox(
                height: 360,
                child: AppLoading(message: 'Đang tải lịch sử hoạt động...'),
              )
            else if (provider.errorMessage != null && provider.logs.isEmpty)
              _ActivityLogErrorView(
                message: provider.errorMessage!,
                onRetry: _applyFilters,
              )
            else if (provider.logs.isEmpty)
              const _ActivityLogEmptyView()
            else ...[
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ...provider.logs.map(
                (log) =>
                    _ActivityLogCard(log: log, onTap: () => _openDetail(log)),
              ),
              if (provider.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: provider.loadLogs,
                    icon: const Icon(Icons.expand_more_rounded),
                    label: const Text('Tải thêm'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityLogFilters extends StatelessWidget {
  const _ActivityLogFilters({
    required this.searchController,
    required this.actionController,
    required this.entityController,
    required this.fromDate,
    required this.toDate,
    required this.isLoading,
    required this.onSearch,
    required this.onChanged,
    required this.onPickFromDate,
    required this.onPickToDate,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final TextEditingController actionController;
  final TextEditingController entityController;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isLoading;
  final Future<void> Function() onSearch;
  final VoidCallback onChanged;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Tìm hoạt động',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      searchController.clear();
                      onSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: actionController,
                enabled: !isLoading,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: const InputDecoration(labelText: 'Action'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: entityController,
                enabled: !isLoading,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: const InputDecoration(labelText: 'Entity name'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'Từ ngày',
                value: fromDate,
                onTap: isLoading ? null : onPickFromDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateButton(
                label: 'Đến ngày',
                value: toDate,
                onTap: isLoading ? null : onPickToDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onSearch,
                icon: const Icon(Icons.filter_alt_rounded),
                label: const Text('Lọc'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              onPressed: isLoading ? null : onClearFilters,
              tooltip: 'Xóa bộ lọc',
              icon: const Icon(Icons.filter_alt_off_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.value, this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.event_rounded),
      label: Text(
        value == null ? label : DateFormatter.formatDate(value!),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.log, required this.onTap});

  final AdminActivityLogModel log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _fallback(log.actionLabel, log.action),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(log.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _fallback(log.description, 'Không có mô tả'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: Icons.person_rounded, label: _userText(log)),
                  _InfoChip(
                    icon: Icons.table_chart_rounded,
                    label: _fallback(log.entityName, 'Không có entity'),
                  ),
                  _InfoChip(
                    icon: Icons.language_rounded,
                    label: _fallback(log.ipAddress, 'Không có IP'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _userText(AdminActivityLogModel log) {
    final name = log.userFullName?.trim();
    final email = log.userEmail?.trim();
    if (name != null && name.isNotEmpty) {
      return email == null || email.isEmpty ? name : '$name / $email';
    }

    return email == null || email.isEmpty ? 'Không có user' : email;
  }

  String _formatTime(DateTime? value) {
    return value == null
        ? 'Chưa có thời gian'
        : DateFormatter.formatDateTime(value);
  }

  String _fallback(String? value, String fallback) {
    final text = value?.trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryBlue),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ActivityLogDetailSheet extends StatelessWidget {
  const _ActivityLogDetailSheet({required this.log});

  final AdminActivityLogModel log;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
          Text(
            'Chi tiết hoạt động',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Action', value: log.action),
          _DetailRow(label: 'Nhãn action', value: log.actionLabel),
          _DetailRow(label: 'Mô tả', value: log.description),
          _DetailRow(label: 'User ID', value: log.userId),
          _DetailRow(label: 'Người dùng', value: log.userFullName),
          _DetailRow(label: 'Email', value: log.userEmail),
          _DetailRow(label: 'Entity', value: log.entityName),
          _DetailRow(label: 'Entity ID', value: log.entityId),
          _DetailRow(label: 'IP', value: log.ipAddress),
          _DetailRow(label: 'User agent', value: log.userAgent),
          _DetailRow(
            label: 'Thời gian',
            value: log.createdAt == null
                ? null
                : DateFormatter.formatDateTime(log.createdAt!),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(text == null || text.isEmpty ? 'Chưa có' : text),
        ],
      ),
    );
  }
}

class _ActivityLogErrorView extends StatelessWidget {
  const _ActivityLogErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.error,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityLogEmptyView extends StatelessWidget {
  const _ActivityLogEmptyView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(
        child: Text(
          'Chưa có lịch sử hoạt động phù hợp.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NoPermissionView extends StatelessWidget {
  const _NoPermissionView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Bạn không có quyền truy cập khu vực Admin.')),
    );
  }
}
