import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://127.0.0.1:8000'});

  Future<ScaleReading> getScaleReading() async {
    final response = await http.get(Uri.parse('$baseUrl/scale/reading'));
    if (response.statusCode == 200) {
      return ScaleReading.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get scale reading');
  }

  Future<void> logEntry({
    required String source,
    required String type,
    required double weight,
    double? tempPickup,
    double? tempDropoff,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'source': source,
        'type': type,
        'weight_lb': weight,
        'temp_pickup_f': tempPickup,
        'temp_dropoff_f': tempDropoff,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to log entry');
    }
  }

  Future<List<String>> getSources() async {
    final response = await http.get(Uri.parse('$baseUrl/sources'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['sources']);
    }
    throw Exception('Failed to get sources');
  }

  Future<List<FoodType>> getTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/types'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['types'] as List)
          .map((t) => FoodType.fromJson(t))
          .toList();
    }
    throw Exception('Failed to get types');
  }

  Future<Map<String, dynamic>> getTodayTotals({String? source}) async {
    final uri = source != null
        ? Uri.parse('$baseUrl/totals/today?source=$source')
        : Uri.parse('$baseUrl/totals/today');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get totals');
  }

  Future<void> undo() async {
    final response = await http.post(Uri.parse('$baseUrl/undo'));
    if (response.statusCode != 200) {
      throw Exception('Failed to undo');
    }
  }

  Future<void> redo() async {
    final response = await http.post(Uri.parse('$baseUrl/redo'));
    if (response.statusCode != 200) {
      throw Exception('Failed to redo');
    }
  }

  Future<Map<String, dynamic>> getStableReading({double timeout = 2.0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scale/stable?timeout=$timeout'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get stable reading');
  }
  Future<List<LogEntry>> getRecentHistory({int limit = 15, String? source}) async {
    final uri = source != null
        ? Uri.parse('$baseUrl/history/recent?limit=$limit&source=$source')
        : Uri.parse('$baseUrl/history/recent?limit=$limit');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['entries'] as List)
          .map((e) => LogEntry.fromJson(e))
          .toList();
    }
    throw Exception('Failed to get history');
  }
}

class ScaleReading {
  final double value;
  final String unit;
  final bool isStable;
  final bool available;

  ScaleReading({
    required this.value,
    required this.unit,
    required this.isStable,
    required this.available,
  });

  factory ScaleReading.fromJson(Map<String, dynamic> json) {
    return ScaleReading(
      value: json['value'].toDouble(),
      unit: json['unit'],
      isStable: json['is_stable'],
      available: json['available'],
    );
  }
}

class FoodType {
  final String name;
  final bool requiresTemp;
  final int sortOrder;

  FoodType({
    required this.name,
    required this.requiresTemp,
    required this.sortOrder,
  });

  factory FoodType.fromJson(Map<String, dynamic> json) {
    return FoodType(
      name: json['name'],
      requiresTemp: json['requires_temp'],
      sortOrder: json['sort_order'],
    );
  }
}

class LogEntry {
  final int id;
  final String source;
  final String type;
  final double weight;
  final String created_at;
  final double? tempPickup;
  final double? tempDropoff;

  LogEntry({
    required this.id,
    required this.source,
    required this.type,
    required this.weight,
    required this.created_at,
    this.tempPickup,
    this.tempDropoff,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] ?? 0,
      source: json['source'] ?? '',
      type: json['type'] ?? json['type_'] ?? '',
      weight: (json['weight_lb'] ?? 0.0).toDouble(),
      created_at: json['created_at'] ?? json['timestamp'] ?? '',
      tempPickup: json['temp_pickup_f'],
      tempDropoff: json['temp_dropoff_f'],
    );
  }
}
