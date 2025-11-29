import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class TodaysEntriesTable extends StatelessWidget {
  const TodaysEntriesTable({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final history = appState.recentHistory;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No entries yet today',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                columns: const [
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Source')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Temp (In/Out)')),
                ],
                rows: history.take(4).map((entry) {
                  // Parse timestamp
                  String timeString = '';
                  try {
                    final dt = DateTime.parse(entry.created_at).toLocal();
                    timeString = DateFormat('h:mm a').format(dt);
                  } catch (e) {
                    timeString = '-';
                  }

                  // Format temps
                  String tempString = '-';
                  if (entry.tempPickup != null || entry.tempDropoff != null) {
                    final inTemp = entry.tempPickup?.toStringAsFixed(1) ?? '-';
                    final outTemp = entry.tempDropoff?.toStringAsFixed(1) ?? '-';
                    tempString = '$inTemp / $outTemp';
                  }

                  return DataRow(cells: [
                    DataCell(Text(timeString)),
                    DataCell(Text(entry.source)),
                    DataCell(Text(entry.type, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(
                      '${NumberFormat('0.00').format(entry.weight)} lb',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                    DataCell(Text(tempString)),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
