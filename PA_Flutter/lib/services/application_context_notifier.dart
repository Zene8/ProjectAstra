import 'package:flutter/foundation.dart';
import 'package:project_astra/models/application_context.dart';

class ApplicationContextNotifier extends ChangeNotifier {
  final List<ApplicationContext> _contexts = [];

  List<ApplicationContext> get contexts => _contexts;

  void addOrUpdateContext(ApplicationContext newContext) {
    final index = _contexts.indexWhere((context) => context.appName == newContext.appName);
    if (index != -1) {
      _contexts[index] = newContext;
    } else {
      _contexts.add(newContext);
    }
    notifyListeners();
  }

  void removeContext(String appName) {
    _contexts.removeWhere((context) => context.appName == appName);
    notifyListeners();
  }

  void clearContexts() {
    _contexts.clear();
    notifyListeners();
  }
}
