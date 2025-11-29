import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/scale_display.dart';
import '../widgets/source_selector.dart';
import '../widgets/food_type_button.dart';
import '../widgets/temperature_dialog.dart';
import '../widgets/todays_entries_table.dart';
import 'admin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initialize();
    });
  }

  Future<void> _handleFoodTypeSelection(String foodTypeName) async {
    final appState = context.read<AppState>();
    
    // Select the type first
    appState.selectFoodType(foodTypeName);

    // Check if this food type requires temperature
    final foodType = appState.getFoodTypeByName(foodTypeName);
    if (foodType == null) {
      _showError('Invalid food type');
      return;
    }

    double? tempPickup;
    double? tempDropoff;

    if (foodType.requiresTemp) {
      // Show temperature dialog
      final result = await showDialog<Map<String, double>>(
        context: context,
        builder: (context) => const TemperatureDialog(),
      );

      if (result == null) {
        // User cancelled, clear selection
        appState.selectFoodType(''); // Or clear selection method
        return;
      }

      tempPickup = result['pickup'];
      tempDropoff = result['dropoff'];
    }

    // Log the entry immediately
    await appState.logEntry(
      tempPickup: tempPickup,
      tempDropoff: tempDropoff,
    );

    if (appState.errorMessage != null) {
      _showError(appState.errorMessage!);
    }
    // Success notification removed - table update is sufficient
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (appState.errorMessage != null && appState.foodTypes.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Initialization Failed',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  appState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AppState>().initialize();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Label - Scale - Logo
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Pantry Log Logo
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/pantry_logo.png',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  // Center: Source Selector & Scale Display
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        const SourceSelector(),
                        const SizedBox(height: 12),
                        const ScaleDisplay(),
                      ],
                    ),
                  ),
                  
                  // Right: Scale Logo with hidden admin button
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            'assets/scale_logo.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 60,
                            height: 30,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(60, 30),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Food Type Buttons (Single Row)
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: appState.foodTypes.map((foodType) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: appState.isLogging 
                              ? null 
                              : () => _handleFoodTypeSelection(foodType.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade800,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.blue.shade100),
                            ),
                          ),
                          child: Text(
                            foodType.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Undo/Redo (Small row below buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: appState.undo,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo Last Entry'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: appState.redo,
                    icon: const Icon(Icons.redo),
                    label: const Text('Redo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom: History Table
              const Expanded(
                child: TodaysEntriesTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
