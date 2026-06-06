import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Baris di bawah ini menggunakan Row:'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Kotak(color: Colors.red),
                _Kotak(color: Colors.green),
                _Kotak(color: Colors.blue),
              ],
            ),
            SizedBox(height: 16),
            Text('Column = vertikal ↕'),
            Text('Row = horizontal ↔'),
          ],
        ),
      ),
    ),
  ));
}

class _Kotak extends StatelessWidget {
  final Color color;
  const _Kotak({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 60, height: 60, color: color);
  }
}