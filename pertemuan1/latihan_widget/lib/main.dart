import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(title: const Text('Latihan Icon')),
      body: const Center(
        child: Text('Lihat ikon-ikon di bawah 👇'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.grey.shade100,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.token, size: 48, color: Colors.red),
            Icon(Icons.html, size: 64, color: Colors.green),
            Icon(Icons.abc, size: 32, color: Colors.purple),
            Icon(Icons.bolt, size: 24, color: Colors.grey),
          ],
        ),
      ),
    ),
  ));
}