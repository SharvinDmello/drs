import 'package:flutter/material.dart';
import 'playlist_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideosPage extends StatefulWidget {
  @override
  _VideosPageState createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  List playlists = [];
  List filteredPlaylists = [];
  final String apiKey = 'AIzaSyAM3XTkYu4HpSiYKtzsktFvZC-jQB3mNgA';
  bool isLoading = false;
  final List<String> channelIds = [
    'UC7btqG2Ww0_2LwuQxpvo2HQ', // First channel ID
    'UCBwmMxybNva6P_5VmxjzwqA' // Add your second channel ID here
  ];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
  }

  // Fetch playlists from all channel IDs
  void fetchPlaylists() async {
    setState(() {
      isLoading = true;
    });

    List allPlaylists = [];

    for (String channelId in channelIds) {
      String url =
          'https://www.googleapis.com/youtube/v3/playlists?part=snippet&channelId=$channelId&key=$apiKey';

      try {
        final response = await http.get(Uri.parse(url));
        final data = json.decode(response.body);
        allPlaylists.addAll(data['items'] ?? []);
      } catch (e) {
        // Handle errors for specific channels
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text("Failed to fetch playlists for channel ID: $channelId"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    }

    setState(() {
      playlists = allPlaylists;
      filteredPlaylists = playlists; // Initially show all playlists
      isLoading = false;
    });
  }

  // Filter playlists based on search query
  void filterPlaylists(String query) {
    setState(() {
      filteredPlaylists = playlists
          .where((playlist) =>
      playlist['snippet']['title']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          playlist['snippet']['description']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Classes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search playlists...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: filterPlaylists,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: filteredPlaylists.length,
        itemBuilder: (context, index) {
          var playlist = filteredPlaylists[index];
          String playlistTitle = playlist['snippet']['title'];
          String playlistDescription =
          playlist['snippet']['description'];
          String thumbnailUrl = playlist['snippet']['thumbnails']
          ['high']['url']; // Fetch high-res thumbnail

          return Card(
            margin:
            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistPage(
                      playlistId: playlist['id'],
                      playlistName: playlist['snippet']['title'],
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
                      // Thumbnail
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
                      // Playlist title and description
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlistTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              playlistDescription,
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
