import 'package:flutter/material.dart';
import 'package:yoga_monitor/screens/monitorpage.dart';

class InstructionsPage extends StatelessWidget {
  final String assetPath;
  final String instructions;
  final List<String> imagePaths; // List of image paths

  InstructionsPage({
    required this.assetPath,
    required this.instructions,
    required this.imagePaths,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instructions'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              child: Text(
                instructions,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 10), // Reduce the gap between text and images
            Container(
              height: 500, // Set the desired height
              child: Image(
                image: AssetImage(assetPath), // Use the received assetPath
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(height: 10), // Add spacing between the text and the image

            // Display multiple images using a ListView
            Container(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Instructions for Vrikshasana. \n Initial condition: Stand straight.\n '
                    'Step 1: Raise one leg. \n Step 2: Fold arms and bring them to chest level.'
                    '\n Step 3: Stretch hands in the vertical direction till straight. '
                    'Ensure the elbow is not bent.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonitorPage(),
                  ),
                );
              },
              child: Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}