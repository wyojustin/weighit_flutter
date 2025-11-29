import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class SourceSelector extends StatelessWidget {
  const SourceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: appState.selectedSource,
          hint: const Text('Select Donor Source'),
          isExpanded: true,
          items: appState.sources.map((source) {
            return DropdownMenuItem<String>(
              value: source,
              child: Text(
                source,
                style: const TextStyle(fontSize: 18),
              ),
            );
          }).toList(),
          onChanged: (value) {
            appState.selectSource(value);
          },
        ),
      ),
    );
  }
}
