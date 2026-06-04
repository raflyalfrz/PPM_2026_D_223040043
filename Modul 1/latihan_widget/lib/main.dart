import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Column di atas"),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 50, height: 50, color: Colors.red),
                SizedBox(width: 10),
                Container(width: 50, height: 50, color: Colors.blue),
                SizedBox(width: 10),
                Container(width: 50, height: 50, color: Colors.green),
              ],
            ),

            SizedBox(height: 20),
            Text("Column di bawah"),
          ],
        ),
      ),
    ),
  ));
}