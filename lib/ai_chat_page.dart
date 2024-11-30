import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController controller = TextEditingController();
  List<String> messages = [];
  bool isTyping = false;

  final String apiKey = "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"; // Use your OpenAI API key here

  // Send message to OpenAI API
  Future<void> sendMessage(String message) async {
    final url = Uri.parse("https://api.openai.com/v1/completions");

    // Preparing the request body
    final body = jsonEncode({
      "model": "gpt-3.5-turbo", // You can also use gpt-4 if you have access
      "messages": [
        {"role": "user", "content": message}
      ]
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey", // Make sure the API key is correct
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final chatGptResponse = responseData["choices"][0]["message"]["content"].trim();

      setState(() {
        messages.add("You: $message");
        messages.add("ChatGPT: $chatGptResponse");
        isTyping = false;
      });
    } else {
      // Handle error
      print('Error: ${response.statusCode}, ${response.body}');
      setState(() {
        messages.add("Error: Something went wrong. Please try again.");
        isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI ChatBot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(hintText: "Type a message"),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          messages.add("You: $value");
                          isTyping = true;
                        });
                        sendMessage(value);
                        controller.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final text = controller.text;
                    if (text.isNotEmpty) {
                      setState(() {
                        messages.add("You: $text");
                        isTyping = true;
                      });
                      sendMessage(text);
                      controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("ChatGPT is typing..."),
            ),
        ],
      ),
    );
  }
}
