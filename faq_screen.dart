import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  // Data structure for Questions and Answers
  final List<Map<String, String>> faqData = const [
    {
      'question': 'What is GlowUp AI?',
      'answer': 'GlowUp AI is a smart skincare assistant that analyzes your skin and provides personalized recommendations.',
    },
    {
      'question': 'How does the skin scan work?',
      'answer': 'The app uses AI to analyze your photo and detect skin type, tone, and conditions.',
    },
    {
      'question': 'Is my data safe?',
      'answer': 'Yes, your data is securely stored and never shared without your permission.',
    },
    {
      'question': 'How often should I scan my skin?',
      'answer': 'You can scan your skin anytime, but we recommend once a week for best tracking.',
    },
    {
      'question': 'Can I delete my data?',
      'answer': 'Yes, you can delete your data anytime from the Privacy Settings.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FAQ',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png',
              width: 35,
              height: 35,
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: faqData.length,
        separatorBuilder: (context, index) => const Divider(height: 32, color: Colors.grey),
        itemBuilder: (context, index) {
          final item = faqData[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['question']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['answer']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}