import 'package:json_annotation/json_annotation.dart';

part 'application_context.g.dart';

@JsonSerializable()
class ApplicationContext {
  final String appName;
  final String? activeItemId;
  final String? activeItemContent;
  final List<Map<String, dynamic>>? openItems; // Generic list of items in the window

  ApplicationContext({
    required this.appName,
    this.activeItemId,
    this.activeItemContent,
    this.openItems,
  });

  factory ApplicationContext.fromJson(Map<String, dynamic> json) =>
      _$ApplicationContextFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationContextToJson(this);

  @override
  String toString() {
    return 'ApplicationContext(appName: \$appName, activeItemId: \$activeItemId, activeItemContent: \$activeItemContent, openItems: \$openItems)';
  }
}
