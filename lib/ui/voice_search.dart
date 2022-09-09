import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../style/app_colors.dart';

class VoiceSearchPage extends StatefulWidget {
  const VoiceSearchPage({Key? key}) : super(key: key);

  @override
  VoiceSearchPageState createState() => VoiceSearchPageState();
}

class VoiceSearchPageState extends State<VoiceSearchPage> {
  SpeechToText speechToText = SpeechToText();
  bool _speechEnabled = true;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    speechToText.initialize().then((value) {
      _speechEnabled = value;
      setState(() {});
    }).whenComplete(() => _startListening());
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await speechToText.listen(
      onResult: _onSpeechResult,
    );

    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    // if (_lastWords.isNotEmpty) {
    //   Navigator.pop(context, _lastWords);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context, _lastWords);
                    },
                    alignment: Alignment.center,
                    color: accent,
                    icon: const Icon(MdiIcons.closeThick),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Text(
                    // If listening is active show the recognized words
                    speechToText.isListening
                        ? _lastWords.isEmpty
                            ? 'आप बोलिए !\nहम सुन रहे हैं...\n\n\nSpeak Now !\nListening... '
                            : _lastWords
                        // If listening isn't active but could be tell the user
                        // how to start it, otherwise indicate that speech
                        // recognition is not yet ready or not supported on
                        // the target device
                        : _speechEnabled
                            ? _lastWords.isEmpty
                                ? 'पुनः प्रयास करें...\n\n\nTry Again... '
                                : _lastWords
                            : 'Speech not available',
                    style: TextStyle(
                      color: accent,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _lastWords);
            },
            style: ElevatedButton.styleFrom(
              primary: accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Search",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: AvatarGlow(
            animate: speechToText.isListening,
            endRadius: 100,
            glowColor: Colors.red,
            child: FloatingActionButton(
              backgroundColor:
                  speechToText.isNotListening ? accent : Colors.red,
              mini: false,
              shape: const CircleBorder(),
              onPressed:
                  // If not yet listening for speech start, otherwise stop
                  speechToText.isNotListening
                      ? _startListening
                      : _stopListening,
              tooltip: 'Listen',
              child: Icon(
                speechToText.isNotListening
                    ? MdiIcons.microphoneOff
                    : MdiIcons.microphone,
                color: speechToText.isListening ? Colors.white : Colors.black,
              ),
            ),
          )),
    );
  }
}
