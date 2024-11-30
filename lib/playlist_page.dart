import 'package:flutter/material.dart';
import 'video_player_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaylistPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  PlaylistPage({required this.playlistId, required this.playlistName});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List videos = [];
  bool isLoading = true;
  final String apiKey = 'AIzaSyAM3XTkYu4HpSiYKtzsktFvZC-jQB3mNgA';

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  void fetchVideos() async {
    String url =
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=${widget.playlistId}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    setState(() {
      videos = data['items'];
      isLoading = false; // Stop loading once data is fetched
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playlistName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          var video = videos[index];
          String videoTitle = video['snippet']['title'];
          String videoDescription =
          video['snippet']['description'];
          String thumbnailUrl = video['snippet']['thumbnails']
          ['high']['url']; // Fetch high-res thumbnail

          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      videoId: video['snippet']['resourceId']['videoId'],
                      videoTitle: video['snippet']['title'],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      // Video Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          thumbnailUrl,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 15),
                      // Video Title and Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              videoTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              videoDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
