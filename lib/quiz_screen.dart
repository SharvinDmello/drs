import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizScreen extends StatefulWidget {
  final String filePath;

  QuizScreen({required this.filePath});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> questions = [];
  int currentQuestionIndex = 0;
  List<int?> selectedAnswers = [];
  int score = 0;
  bool isSubmitted = false;
  List<Color> optionColors = [
    Colors.transparent,
    Colors.transparent,
    Colors.transparent,
    Colors.transparent
  ];
  String feedback = "";
  String errorText = "";

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final jsonString = await rootBundle.loadString(widget.filePath);
      final dynamic data = json.decode(jsonString);

      if (data is List) {
        setState(() {
          questions = data;
          selectedAnswers = List.generate(data.length, (_) => null);
        });
      } else if (data is Map && data.containsKey('questions')) {
        setState(() {
          questions = data['questions'];
          selectedAnswers =
              List.generate(data['questions'].length, (_) => null);
        });
      } else {
        print('Unexpected JSON structure');
      }
    } catch (e) {
      print('Error loading questions: $e');
    }
  }

  void handleAnswer(int selectedIndex) {
    if (!isSubmitted) {
      setState(() {
        selectedAnswers[currentQuestionIndex] = selectedIndex;
        errorText = "";
        feedback = "";
        optionColors = [
          Colors.transparent,
          Colors.transparent,
          Colors.transparent,
          Colors.transparent
        ];
      });
    }
  }

  void submitAnswer() {
    setState(() {
      if (selectedAnswers[currentQuestionIndex] == null) {
        errorText = "Select any option";
        return;
      }
      isSubmitted = true;
      final currentQuestion = questions[currentQuestionIndex];

      if (selectedAnswers[currentQuestionIndex] != null &&
          selectedAnswers[currentQuestionIndex] == currentQuestion['answer']) {
        score++;
        feedback = "Correct!";
      } else {
        feedback = "Incorrect!";
      }

      for (int i = 0; i < currentQuestion['options'].length; i++) {
        if (i == currentQuestion['answer']) {
          optionColors[i] = Colors.green;
        } else if (i == selectedAnswers[currentQuestionIndex]) {
          optionColors[i] = Colors.red;
        } else {
          optionColors[i] = Colors.transparent;
        }
      }
    });
  }

  void nextQuestion() {
    if (selectedAnswers[currentQuestionIndex] != null) {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          isSubmitted = false;
          feedback = "";
          optionColors = [
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
            Colors.transparent
          ];
        });
      }
    } else {
      setState(() {
        errorText = "Select any option";
      });
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        isSubmitted = false;
        feedback = "";
        optionColors = [
          Colors.transparent,
          Colors.transparent,
          Colors.transparent,
          Colors.transparent
        ];
      });
    }
  }

  void skipQuestion() {
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        isSubmitted = false;
        feedback = "";
        optionColors = [
          Colors.transparent,
          Colors.transparent,
          Colors.transparent,
          Colors.transparent
        ];
      }
    });
  }

  void clearAnswer() {
    setState(() {
      selectedAnswers[currentQuestionIndex] = null;
      feedback = "";
      errorText = "";
      optionColors = [
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent
      ];
    });
  }

  void navigateToResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          score: score,
          questions: questions,
          selectedAnswers: selectedAnswers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      final currentQuestion = questions[currentQuestionIndex];
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz'),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Score: $score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Question ${currentQuestionIndex + 1} / ${questions.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  currentQuestion['question'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                ...List.generate(currentQuestion['options'].length, (index) {
                  return GestureDetector(
                    onTap: () {
                      if (!isSubmitted) {
                        handleAnswer(index);
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedAnswers[currentQuestionIndex] == index
                            ? Colors.blue.shade100
                            : optionColors[index],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 1.5,
                        ),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: selectedAnswers[currentQuestionIndex],
                            onChanged: (value) {
                              if (!isSubmitted) {
                                handleAnswer(value!);
                              }
                            },
                          ),
                          Expanded(
                            child: Text(
                              currentQuestion['options'][index],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 10),
                if (feedback.isNotEmpty)
                  Text(
                    feedback,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: feedback == "Correct!"
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                if (errorText.isNotEmpty)
                  Text(
                    errorText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed:
                      currentQuestionIndex > 0 ? previousQuestion : null,
                      child: Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (currentQuestionIndex < questions.length - 1)
                          ElevatedButton(
                            onPressed:
                            isSubmitted ? nextQuestion : submitAnswer,
                            child: Text(isSubmitted ? 'Next' : 'Submit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: navigateToResults,
                            child: Text('Submit Quiz'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        SizedBox(width: 10),
                        if (currentQuestionIndex < questions.length - 1)
                          ElevatedButton(
                            onPressed: selectedAnswers[currentQuestionIndex] ==
                                null
                                ? skipQuestion
                                : null,
                            child: Text('Skip'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: clearAnswer,
                      child: Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class ResultsScreen extends StatelessWidget {
  final int score;
  final List<dynamic> questions;
  final List<int?> selectedAnswers;

  ResultsScreen({
    required this.score,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Score: $score / ${questions.length}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final isCorrect =
                      selectedAnswers[index] == question['answer'];
                  return Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${index + 1}: ${question['question']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...List.generate(question['options'].length, (i) {
                            final isSelected =
                                selectedAnswers[index] == i;
                            final isAnswer = question['answer'] == i;
                            return Text(
                              '${isAnswer ? '✓' : ''} ${question['options'][i]}',
                              style: TextStyle(
                                color: isSelected
                                    ? (isCorrect ? Colors.green : Colors.red)
                                    : null,
                              ),
                            );
                          }),
                          SizedBox(height: 8),
                          Text(
                            isCorrect
                                ? 'Correct Answer!'
                                : 'Correct Answer: ${question['options'][question['answer']]}',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back to Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
