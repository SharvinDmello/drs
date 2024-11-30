import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // For saving files
import 'package:flutter_pdfview/flutter_pdfview.dart'; // For viewing PDFs
import 'package:shared_preferences/shared_preferences.dart'; // For persistent storage

class EbooksPage extends StatefulWidget {
  const EbooksPage({Key? key}) : super(key: key);

  @override
  _EbooksPageState createState() => _EbooksPageState();
}

class _EbooksPageState extends State<EbooksPage> {
  // List of books with local asset paths and favorite status
  final List<Map<String, dynamic>> books = [
    {
      'title': 'Linear Algebra',
      'assetPath': 'assets/Introduction_to_Linear_Algebra_Fifth_Edition.pdf',
      'isFavorite': false,
      'details': 'Author: Gilbert Strang',
    },
    {
      'title': 'Statistics',
      'assetPath': 'assets/MathematicalStatisticsandDataAnalysis3ed.pdf',
      'isFavorite': false,
      'details': 'Author: John Rice',
    },
    {
      'title': 'Matrix Computations',
      'assetPath': 'assets/vdoc.pub_matrix-computations.pdf',
      'isFavorite': false,
      'details': 'Category: Mathematics',
    },
    {
      'title': 'Data Warehouse',
      'assetPath':
      'assets/vdoc.pub_the-data-warehouse-toolkit-3rd-edition-the-definitive-guide-to-dimensional-modeling.pdf',
      'isFavorite': false,
      'details': 'Author: Ralph Kimball',
    },
    {
      'title': 'AI Basics',
      'assetPath':
      'assets/zlib.pub_artificial-intelligence-basics-a-non-technical-introduction.pdf',
      'isFavorite': false,
      'details': 'Category: AI',
    },
    {
      'title': 'Deep Learning',
      'assetPath': 'assets/zlib.pub_deep-learning.pdf',
      'isFavorite': false,
      'details': 'Author: Ian Goodfellow',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    for (var book in books) {
      final isFavorite = prefs.getBool(book['title']) ?? false;
      book['isFavorite'] = isFavorite;
    }
    _sortBooks();
  }

  Future<void> _saveFavorite(String title, bool isFavorite) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(title, isFavorite);
  }

  void toggleFavorite(int index) async {
    setState(() {
      books[index]['isFavorite'] = !books[index]['isFavorite'];
    });

    await _saveFavorite(books[index]['title'], books[index]['isFavorite']);
    _sortBooks();
  }

  void _sortBooks() {
    books.sort((a, b) {
      if (a['isFavorite'] == b['isFavorite']) return 0;
      return a['isFavorite'] ? -1 : 1;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-books'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          final title = book['title'] ?? 'Unknown Title';
          final details = book['details'] ?? '';
          final assetPath = book['assetPath'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      book['isFavorite'] ? Icons.star : Icons.star_border,
                      color: book['isFavorite'] ? Colors.yellow : Colors.grey,
                    ),
                    onPressed: () => toggleFavorite(index),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          details,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child: const Text('Open'),
                        onPressed: () {
                          if (assetPath != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerPage(assetPath),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error: PDF not available')),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Download'),
                        onPressed: () async {
                          if (assetPath != null) {
                            await _downloadFile(context, assetPath, title);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error: Asset path is null')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadFile(
      BuildContext context, String assetPath, String title) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$title.pdf');
      await file.writeAsBytes(data.buffer.asUint8List());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title downloaded to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error downloading the file')),
      );
    }
  }
}

class PdfViewerPage extends StatelessWidget {
  final String assetPath;

  const PdfViewerPage(this.assetPath, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: FutureBuilder<String>(
        future: _loadPdf(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading PDF.'));
          }

          final filePath = snapshot.data!;
          return PDFView(
            filePath: filePath,
          );
        },
      ),
    );
  }

  Future<String> _loadPdf(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp.pdf');
    await tempFile.writeAsBytes(data.buffer.asUint8List());
    return tempFile.path;
  }
}
