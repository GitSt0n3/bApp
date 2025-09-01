import 'package:flutter/material.dart';

class GestionStaffScreen extends StatelessWidget {
  final int shopId;
  final String shopName;

  const GestionStaffScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Barberos — $shopName')),
      body: const Center(
        child: Text('Gestión de staff (próxima versión)'),
      ),
    );
  }
}
