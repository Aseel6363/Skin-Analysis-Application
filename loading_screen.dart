import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom Pink Spinner
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  color: const Color(0xFFD7B0E2), // Light pink-purple
                  strokeWidth: 10,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Analyzing your\nskin...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E2EB),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'This may take a few seconds',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
