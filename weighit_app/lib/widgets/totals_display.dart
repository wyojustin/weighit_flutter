import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';

class TotalsDisplay extends StatelessWidget {
  const TotalsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final totals = appState.todayTotals;

    if (totals == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final totalsByType = totals['totals_by_type'] as Map<String, dynamic>? ?? {};
    final totalWeight = totals['total_weight'] as num? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Totals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (totalsByType.isEmpty)
            const Text(
              'No entries yet today',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            )
          else
            ...totalsByType.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${NumberFormat('0.00').format(entry.value)} lb',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 24, thickness: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${NumberFormat('0.00').format(totalWeight)} lb',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
