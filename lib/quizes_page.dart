import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quiz_screen.dart'; // Import the new quiz screen

class QuizzesPage extends StatefulWidget {
  @override
  _QuizzesPageState createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  Map<String, String> quizFiles = {};
  String? selectedQuizName;

  @override
  void initState() {
    super.initState();
    loadQuizFiles();
  }

  Future<void> loadQuizFiles() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final files = manifestMap.keys
          .where((key) => key.startsWith('assets/questions/') && key.endsWith('.json'))
          .toList();

      setState(() {
        quizFiles = {
          for (var file in files)
            _formatQuizName(file.split('/').last.replaceAll('.json', '')): file
        };
        selectedQuizName = quizFiles.keys.isNotEmpty ? quizFiles.keys.first : null;
      });
    } catch (e) {
      debugPrint('Error loading quiz files: $e');
    }
  }

  String _formatQuizName(String fileName) {
    return fileName
        .replaceAll('_', ' ')
        .splitMapJoin(
      RegExp(r'[a-zA-Z]+'),
      onMatch: (m) => m.group(0)![0].toUpperCase() + m.group(0)!.substring(1),
    )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Quiz',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 5,
      ),
      body: Center(
        child: quizFiles.isEmpty
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  value: selectedQuizName,
                  items: quizFiles.keys.map((quizName) {
                    return DropdownMenuItem<String>(
                      value: quizName,
                      child: Text(
                        quizName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedQuizName = value;
                    });
                  },
                  style: TextStyle(color: Colors.deepPurple),
                  underline: SizedBox(),
                  iconEnabledColor: Colors.deepPurple,
                  iconDisabledColor: Colors.grey,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectedQuizName != null
                    ? () {
                  final selectedQuizFile = quizFiles[selectedQuizName!];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        filePath: selectedQuizFile!,
                      ),
                    ),
                  );
                }
                    : null,
                child: Text(
                  'Start Quiz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
