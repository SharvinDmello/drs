import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class UploadDocumentPage extends StatefulWidget {
  const UploadDocumentPage({Key? key}) : super(key: key);

  @override
  _UploadDocumentPageState createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  List<String> uploadedFiles = [];
  String message = "No files uploaded yet.";

  // Function to pick and upload a document
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? filePath = result.files.single.path;

      if (filePath != null) {
        // Get the app's documents directory
        Directory appDocDirectory = await getApplicationDocumentsDirectory();
        String directoryPath = '${appDocDirectory.path}/uploaded_documents';

        // Create the directory if it doesn't exist
        await Directory(directoryPath).create(recursive: true);

        // Get the file name and copy the file to the new directory
        File documentFile = File(filePath);
        String newFilePath = '$directoryPath/${result.files.single.name}';
        await documentFile.copy(newFilePath);

        setState(() {
          uploadedFiles.add(newFilePath);
          message = 'Document uploaded successfully to: $newFilePath';
        });
      }
    }
  }

  // Display all uploaded files
  Widget _buildUploadedFilesList() {
    if (uploadedFiles.isEmpty) {
      return const Center(child: Text('No uploaded files.'));
    }
    return ListView.builder(
      itemCount: uploadedFiles.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(uploadedFiles[index]),
          onTap: () {
            // Handle file viewing (e.g., open PDF, text files, etc.)
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Document"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickDocument,
              child: const Text("Upload Document"),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildUploadedFilesList())
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const UploadDocumentPage(),
  ));
}
