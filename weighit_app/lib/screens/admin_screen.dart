import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/app_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _selectedSource;
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin - Reports'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Range Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text('${_startDate.month}/${_startDate.day}/${_startDate.year}'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text('${_endDate.month}/${_endDate.day}/${_endDate.year}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Source Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Source Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Select Source',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Sources'),
                        ),
                        ...appState.sources.map((source) {
                          return DropdownMenuItem(
                            value: source,
                            child: Text(source),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSource = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Address
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Recipient',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (optional)',
                        hintText: 'Leave blank for default',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final startDate = _startDate.toIso8601String().split('T')[0];
                  final endDate = _endDate.toIso8601String().split('T')[0];
                  
                  // Build URL with query parameters
                  String url = 'http://127.0.0.1:8000/reports/csv?';
                  url += 'start_date=$startDate&';
                  url += 'end_date=$endDate&';
                  if (_selectedSource != null) url += 'source=$_selectedSource';
                  
                  // Open URL in browser to download
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Download URL: $url'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Download CSV Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final startDate = _startDate.toIso8601String().split('T')[0];
                  final endDate = _endDate.toIso8601String().split('T')[0];

                  // Build URL with query parameters
                  String url = 'http://127.0.0.1:8000/reports/email?';
                  url += 'start_date=$startDate&';
                  url += 'end_date=$endDate&';
                  if (_selectedSource != null) url += 'source=$_selectedSource&';
                  if (_emailController.text.isNotEmpty) {
                    url += 'recipient=${Uri.encodeComponent(_emailController.text)}';
                  }

                  // Make POST request
                  final response = await http.post(Uri.parse(url));

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email sent successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    throw Exception('Failed to send email');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.email),
              label: const Text('Email Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // System Controls
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scale Connection
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final response = await http.post(
                                  Uri.parse('http://127.0.0.1:8000/scale/reconnect?force_mock=false'),
                                );
                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Connected to Dymo scale'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.scale),
                            label: const Text('Connect Dymo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final response = await http.post(
                                  Uri.parse('http://127.0.0.1:8000/scale/reconnect?force_mock=true'),
                                );
                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Connected to dummy scale'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.developer_mode),
                            label: const Text('Connect Dummy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Close Application
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Close Application'),
                            content: const Text('This will close both the API and the app. Are you sure?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Close'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            // Shutdown API server
                            await http.post(Uri.parse('http://127.0.0.1:8000/system/shutdown'));

                            // Close Flutter app
                            if (context.mounted) {
                              // Exit the app
                              io.exit(0);
                            }
                          } catch (e) {
                            // API might already be down, just exit
                            io.exit(0);
                          }
                        }
                      },
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('Close Application'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
