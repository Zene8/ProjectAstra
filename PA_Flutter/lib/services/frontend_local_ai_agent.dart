import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class FrontendLocalAIAgent {
  late LlamaCpp _llama;
  final String modelPath;

  FrontendLocalAIAgent({required this.modelPath});

  Future<void> init() async {
    // TODO: Ensure llama.cpp shared libraries are correctly placed for each platform.
    // Android: android/app/src/main/jniLibs/arm64-v8a/libllama.so
    // iOS: ios/Runner/libllama.dylib
    // Linux: linux/flutter/ephemeral/libllama.so
    // macOS: macos/Flutter/ephemeral/libllama.dylib
    // Windows: windows/flutter/ephemeral/llama.dll

    // TODO: Ensure the GGUF model file is included as an asset and its path is correct.
    // Example: assets/models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf
    // Add to pubspec.yaml: assets:
    //   - assets/models/

    _llama = LlamaCpp(modelPath: modelPath);
    await _llama.init();
  }

  Stream<String> generateResponse(String prompt) async* {
    if (!_llama.isInitialized) {
      throw Exception("LlamaCpp not initialized. Call init() first.");
    }

    // Basic prompt template for chat
    final formattedPrompt = "<|user|>
$prompt<|end|>
<|assistant|>";

    await for (final token in _llama.textCompletion(prompt: formattedPrompt)) {
      yield token;
    }
  }

  void dispose() {
    _llama.dispose();
  }
}
