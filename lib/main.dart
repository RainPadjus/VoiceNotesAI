import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'record.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Add this import
import 'package:animated_text_kit/animated_text_kit.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Notes App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        accentColor: Colors.cyanAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Record _audioRecorder = Record();
  bool _isRecording = false;
  String? _audioPath;
  String _statusMessage = 'Press the button to start recording';
  String _summaryText = '';
  List<String> _summaries = [];

  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/recorded_audio.wav';

        await _audioRecorder.start(
          path: filePath,
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          samplingRate: 16000,
          numChannels: 1,
        );
        print('Started recording audio at $filePath');
        setState(() {
          _isRecording = true;
          _audioPath = filePath;
        });
        _animationController?.forward();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant microphone permission'),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    print('Stopped recording audio');
    setState(() {
      _isRecording = false;
    });

    _animationController?.reverse();

    if (_audioPath != null) {
      _processAudio(_audioPath!);
    }
  }

  Future<void> _processAudio(String path) async {
    _updateStatusMessage('Transcribing...');
    String transcribedText = await _transcribeAudio(path);

    _updateStatusMessage('GPT-processing...');
    String transformedText = await _sendToGPT(transcribedText);

    _updateStatusMessage('READY!!');
    _saveToDatabase(transformedText);
  }

  Future<String> _transcribeAudio(String path) async {
    String apiUrl = "http://192.168.8.106:5000/transcribe";

    try {
      var headers = {
        'Content-Type': 'application/octet-stream',
      };

      var audioFile = File(path);
      var audioBytes = await audioFile.readAsBytes();

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: audioBytes,
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(
            'Failed to transcribe audio. Status code: ${response.statusCode}');
        return 'Error';
      }
    } catch (e) {
      print('Error transcribing audio: $e');
      return 'Error';
    }
  }

  Future<String> _sendToGPT(String text) async {
    String apiUrl = "http://192.168.8.106:5000/summarize";

    String prompt = "";

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"text": prompt + text}),
      );

      if (response.statusCode == 200) {
        print(
            "Make this text smaller(answer with smaller text without explanations): TEXT:");
        print(response.body);
        return response.body;
      } else {
        print('Failed to get summary. Status code: ${response.statusCode}');
        return 'Error';
      }
    } catch (e) {
      print('Error getting summary: $e');
      return 'Error';
    }
  }

  Future<void> _saveToDatabase(String text) async {
    // Save the text to your database
    setState(() {
      _summaries.add(text);
    });
  }

  void _updateStatusMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes App'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _isRecording
                    ? CircularProgressIndicator(
                        valueColor: _animation!.drive(
                          ColorTween(
                              begin: Colors.cyan.shade400,
                              end: Colors.cyan.shade200),
                        ),
                      )
                    : AnimatedDefaultTextStyle(
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                        ),
                        style: GoogleFonts.robotoMono(
                          fontSize: 18,
                          color: Colors.cyanAccent,
                        ),
                        duration: const Duration(milliseconds: 200),
                      ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _summaries.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.grey.shade800,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            _summaries[index],
                            style: TextStyle(color: Colors.cyanAccent),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
                  child: Icon(_isRecording ? Icons.stop : Icons.mic),
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
