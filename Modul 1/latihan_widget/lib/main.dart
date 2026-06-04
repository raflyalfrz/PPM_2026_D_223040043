import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Container(
          width: 300, height: 100,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.black,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 50,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text('Box',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
        ),
      ),
    ),
  ));
}