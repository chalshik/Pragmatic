import 'package:flutter/material.dart';
import 'package:pragmatic/Providers/QuestionProvider.dart';
import 'package:pragmatic/Widgets/options.dart';
import 'package:provider/provider.dart';

class GameProcess extends StatefulWidget {
  const GameProcess({super.key});

  @override
  State<GameProcess> createState() => _GameProcessState();
}

class _GameProcessState extends State<GameProcess> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game in Progress'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<QuestionProvider>(
          builder: (context, questionProvider, child) {
            final currentQuestion = questionProvider.currentQuestion;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Question display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    currentQuestion != null 
                        ? currentQuestion.question 
                        : "Waiting for question...",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Options
                if (currentQuestion != null) ...[
                  const Text(
                    'Choose your answer:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Map through options
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    int index = entry.key;
                    String option = entry.value;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: BlockButton(
                        text: option,
                        onPressed: () {
                          print("Selected option ${index + 1}: $option");
                          // Add your answer submission logic here
                        },
                      ),
                    );
                  }).toList(),
                ] else ...[
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading question...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}