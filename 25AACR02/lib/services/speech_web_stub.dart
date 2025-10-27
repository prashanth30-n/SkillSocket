// Web-compatible stub for speech_to_text
class SpeechToText {
  bool get isAvailable => false;
  bool get isListening => false;

  Future<bool> initialize() async => false;

  void listen({
    Function(dynamic)? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    bool? partialResults,
    String? localeId,
    Function(dynamic)? onSoundLevelChange,
  }) {}

  void stop() {}
  void cancel() {}
}

class SpeechRecognitionResult {
  final String recognizedWords;
  final bool finalResult;

  SpeechRecognitionResult(this.recognizedWords, this.finalResult);
}
