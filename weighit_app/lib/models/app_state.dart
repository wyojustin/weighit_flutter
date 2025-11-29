import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Scale reading
  ScaleReading? _currentReading;
  ScaleReading? get currentReading => _currentReading;

  // Sources and types
  List<String> _sources = [];
  List<String> get sources => _sources;
  
  String? _selectedSource;
  String? get selectedSource => _selectedSource;

  List<FoodType> _foodTypes = [];
  List<FoodType> get foodTypes => _foodTypes;

  String? _selectedFoodType;
  String? get selectedFoodType => _selectedFoodType;

  // Totals
  Map<String, dynamic>? _todayTotals;
  Map<String, dynamic>? get todayTotals => _todayTotals;

  // History
  List<LogEntry> _recentHistory = [];
  List<LogEntry> get recentHistory => _recentHistory;

  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLogging = false;
  bool get isLogging => _isLogging;

  // Initialize app state
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Start scale reading loop immediately
    _startScaleReadingLoop();

    try {
      // Load sources and types
      await Future.wait([
        _loadSources(),
        _loadFoodTypes(),
      ]);

      // Load initial totals and history
      await Future.wait([
        refreshTotals(),
        refreshHistory(),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSources() async {
    try {
      _sources = await _apiService.getSources();
      if (_sources.isNotEmpty) {
        _selectedSource = _sources.first;
      }
    } catch (e) {
      debugPrint('Error loading sources: $e');
      rethrow;
    }
  }

  Future<void> _loadFoodTypes() async {
    try {
      _foodTypes = await _apiService.getTypes();
      // Sort by sort_order
      _foodTypes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      debugPrint('Error loading food types: $e');
      rethrow;
    }
  }

  void _startScaleReadingLoop() {
    // Poll scale reading every 200ms
    Future.delayed(const Duration(milliseconds: 200), () async {
      try {
        _currentReading = await _apiService.getScaleReading();
        notifyListeners();
      } catch (e) {
        debugPrint('Error reading scale: $e');
        _currentReading = ScaleReading(
          value: 0.0,
          unit: 'lb',
          isStable: false,
          available: false,
        );
        notifyListeners();
      }
      // Continue loop
      _startScaleReadingLoop();
    });
  }

  Future<void> refreshTotals() async {
    try {
      _todayTotals = await _apiService.getTodayTotals(source: _selectedSource);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing totals: $e');
      _errorMessage = 'Failed to load totals';
      notifyListeners();
    }
  }

  Future<void> refreshHistory() async {
    try {
      _recentHistory = await _apiService.getRecentHistory(source: _selectedSource);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing history: $e');
    }
  }

  void selectFoodType(String foodType) {
    _selectedFoodType = foodType;
    notifyListeners();
  }

  void selectSource(String? source) {
    _selectedSource = source;
    refreshTotals();
    refreshHistory();
  }

  Future<void> logEntry({
    double? tempPickup,
    double? tempDropoff,
  }) async {
    if (_selectedFoodType == null) {
      _errorMessage = 'Please select a food type';
      notifyListeners();
      return;
    }

    if (_selectedSource == null) {
      _errorMessage = 'Please select a source';
      notifyListeners();
      return;
    }

    _isLogging = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get stable reading
      final stableReading = await _apiService.getStableReading();
      
      // Log the entry
      await _apiService.logEntry(
        source: _selectedSource!,
        type: _selectedFoodType!,
        weight: stableReading['value'],
        tempPickup: tempPickup,
        tempDropoff: tempDropoff,
      );

      // Refresh totals and history
      await refreshTotals();
      await refreshHistory();

      // Clear selection
      _selectedFoodType = null;
      
      _isLogging = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to log entry: $e';
      _isLogging = false;
      notifyListeners();
    }
  }

  Future<void> undo() async {
    try {
      await _apiService.undo();
      await refreshTotals();
      await refreshHistory();
    } catch (e) {
      _errorMessage = 'Failed to undo: $e';
      notifyListeners();
    }
  }

  Future<void> redo() async {
    try {
      await _apiService.redo();
      await refreshTotals();
      await refreshHistory();
    } catch (e) {
      _errorMessage = 'Failed to redo: $e';
      notifyListeners();
    }
  }

  FoodType? getFoodTypeByName(String name) {
    try {
      return _foodTypes.firstWhere((type) => type.name == name);
    } catch (e) {
      return null;
    }
  }
}
