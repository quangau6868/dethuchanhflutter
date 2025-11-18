import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HighlightScreen(),
    );
  }
}

class HighlightScreen extends StatefulWidget {
  @override
  _HighlightScreenState createState() => _HighlightScreenState();
}

class _HighlightScreenState extends State<HighlightScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> wordTimings = [];
  String fullText = "";
  int currentHighlightIndex = -1;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    loadJson();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadJson() async {
    String data = await rootBundle.loadString('assets/jamesflora.json');
    Map<String, dynamic> jsonResult = jsonDecode(data);

    wordTimings.clear();
    fullText = "";
    int textIndex = 0;

    for (var item in jsonResult['word']) {
      int startMs = item[0];        // t0 = start time (ms)
      int durationMs = item[1];     // t1 = duration (không phải end!)
      String word = item[2].toString().trim();

      int endMs = startMs + durationMs;

      // Tính begin và end trong chuỗi fullText
      int b = fullText.length;
      int e = b + word.length;

      wordTimings.add({
        't0': startMs,
        't1': endMs,       // ← ĐÃ SỬA: giờ là end time thật sự
        'word': word,
        'b': b,
        'e': e,
      });

      fullText += word;
      textIndex += word.length;

      // Thêm khoảng trắng giữa các từ (trừ từ cuối cùng)
      if (textIndex < 1000) { // đủ lớn để không phải từ cuối
        fullText += " ";
      }
    }

    fullText = fullText.trim();
    setState(() {});
  }

  void startAudio() async {
    await audioPlayer.play(AssetSource('jamesflora.wav'));
    timer = Timer.periodic(Duration(milliseconds: 30), (_) async {
      final position = await audioPlayer.getCurrentPosition();
      if (position != null) {
        updateHighlight(position.inMilliseconds);
      }
    });
  }

  void pauseAudio() async => await audioPlayer.pause();

  void stopAudio() async {
    await audioPlayer.stop();
    timer?.cancel();
    setState(() => currentHighlightIndex = -1);
  }

  void updateHighlight(int currentMs) {
    int newIndex = -1;

    for (int i = 0; i < wordTimings.length; i++) {
      if (currentMs >= wordTimings[i]['t0'] && currentMs <= wordTimings[i]['t1']) {
        newIndex = i;
        break;
      }
    }

    if (newIndex != currentHighlightIndex) {
      setState(() {
        currentHighlightIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TextSpan> spans = [];

    if (wordTimings.isNotEmpty && fullText.isNotEmpty) {
      for (int i = 0; i < wordTimings.length; i++) {
        var timing = wordTimings[i];
        String word = timing['word'];

        spans.add(TextSpan(
          text: word + (i < wordTimings.length - 1 ? " " : ""), // tự động thêm space
          style: TextStyle(
            fontSize: 22,
            color: Colors.black87,
            backgroundColor: i == currentHighlightIndex
                ? Colors.amberAccent.withOpacity(0.9)
                : Colors.transparent,
            fontWeight: i == currentHighlightIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("James & Flora - Karaoke Highlight"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(children: spans),
                  ),
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: startAudio,
                    icon: Icon(Icons.play_arrow),
                    label: Text("Play"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: pauseAudio,
                    icon: Icon(Icons.pause),
                    label: Text("Pause"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  ElevatedButton.icon(
                    onPressed: stopAudio,
                    icon: Icon(Icons.stop),
                    label: Text("Stop"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}