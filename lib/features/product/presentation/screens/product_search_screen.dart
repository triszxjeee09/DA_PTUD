import 'package:flutter/material.dart';

class ProductSearchScreen extends StatelessWidget {
  const ProductSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm sản phẩm')),
      body: const Center(child: Text('Tìm thuốc, triệu chứng, vitamin...')),
    );
  }
}
