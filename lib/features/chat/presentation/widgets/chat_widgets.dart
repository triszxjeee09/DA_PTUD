import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../product/data/models/product_model.dart';
import '../../data/chat_models.dart';

String chatTime(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) {
    return '';
  }
  final hm =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  final today = DateTime.now();
  final sameDay =
      today.year == date.year &&
      today.month == date.month &&
      today.day == date.day;
  return sameDay
      ? hm
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} $hm';
}

/// Danh sách tin nhắn tự cuộn xuống cuối khi có tin mới.
class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.animateTo(
            _controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.all(12),
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.isMine,
    required this.child,
    this.senderLabel,
    this.time,
  });

  final bool isMine;
  final Widget child;
  final String? senderLabel;
  final String? time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  senderLabel!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isMine ? Colors.white70 : AppTheme.primaryBlue,
                  ),
                ),
              ),
            child,
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  time!,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isMine ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ sản phẩm gợi ý trong khung chat; chạm để mở chi tiết.
class ChatProductCard extends StatelessWidget {
  const ChatProductCard({
    super.key,
    required this.productId,
    required this.name,
    this.price,
  });

  final String productId;
  final String name;
  final double? price;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Navigator.of(context)
              .pushNamed(AppRoutes.productDetail, arguments: {'id': productId}),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.lightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medication_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (price != null)
                    Text(
                      CurrencyFormatter.format(price!),
                      style: const TextStyle(
                        color: AppTheme.darkBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

List<Widget> botProductCards(List<ProductModel> products) {
  return [
    for (final product in products)
      ChatProductCard(
        productId: product.id,
        name: product.name,
        price: product.price,
      ),
  ];
}

/// Ô nhập tin nhắn: văn bản, ảnh, và (tùy chọn) nút gửi sản phẩm gợi ý.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    this.onPickProduct,
    this.allowImage = true,
    this.isSending = false,
    this.hint = 'Nhập tin nhắn...',
  });

  final Future<void> Function(String text, XFile? image) onSend;
  final VoidCallback? onPickProduct;
  final bool allowImage;
  final bool isSending;
  final String hint;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    _controller.clear();
    await widget.onSend(text, null);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) {
      return;
    }
    await widget.onSend('', picked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            if (widget.allowImage)
              IconButton(
                tooltip: 'Gửi ảnh',
                onPressed: widget.isSending ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
              ),
            if (widget.onPickProduct != null)
              IconButton(
                tooltip: 'Gợi ý sản phẩm',
                onPressed: widget.isSending ? null : widget.onPickProduct,
                icon: const Icon(Icons.medication_outlined),
              ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              tooltip: 'Gửi',
              onPressed: widget.isSending ? null : _submit,
              icon: widget.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
