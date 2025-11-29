import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';

class ScaleDisplay extends StatelessWidget {
  const ScaleDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final reading = appState.currentReading;

    if (reading == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            'Connecting...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reading.isStable ? Colors.green : Colors.grey.shade300,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!reading.available)
            const Text(
              'Scale Unavailable',
              style: TextStyle(
                fontSize: 32, // Kept original 32px as per "no unrelated edits"
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            )
          else
            Text(
              '${reading.value.toStringAsFixed(2)} ${reading.unit}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}
