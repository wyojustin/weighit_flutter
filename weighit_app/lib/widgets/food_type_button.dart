import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class FoodTypeButton extends StatelessWidget {
  final FoodType foodType;

  const FoodTypeButton({
    super.key,
    required this.foodType,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSelected = appState.selectedFoodType == foodType.name;

    return Material(
      color: isSelected ? Colors.blue.shade600 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          appState.selectFoodType(foodType.name);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              foodType.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
