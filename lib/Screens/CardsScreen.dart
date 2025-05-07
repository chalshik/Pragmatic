import 'package:flutter/material.dart';
import 'package:pragmatic/Widgets/AuthWrapper.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cards'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Welcome to the Cards Screen!',
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate to another screen
                },
                child: const Text('Go to Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}