import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hello Flutter!',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900, color:
              Colors.deepPurple, letterSpacing: 2,),
            ),
            SizedBox(height: 8),
            Text('Ini teks biasa dengan ukuran kecil',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  ));
}