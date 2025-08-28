// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationContext _$ApplicationContextFromJson(Map<String, dynamic> json) =>
    ApplicationContext(
      appName: json['appName'] as String,
      activeItemId: json['activeItemId'] as String?,
      activeItemContent: json['activeItemContent'] as String?,
      openItems: (json['openItems'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList(),
    );

Map<String, dynamic> _$ApplicationContextToJson(ApplicationContext instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'activeItemId': instance.activeItemId,
      'activeItemContent': instance.activeItemContent,
      'openItems': instance.openItems,
    };
