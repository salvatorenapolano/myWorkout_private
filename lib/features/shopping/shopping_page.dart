import 'package:flutter/material.dart';

/// Tab "Spesa". Segnaposto: mostrerà la lista generata dalla dieta.
class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spesa')),
      body: const Center(
        child: Text('Qui arriverà la lista della spesa'),
      ),
    );
  }
}
