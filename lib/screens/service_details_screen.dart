import 'package:flutter/material.dart';
import 'package:vayujal_technician/DatabaseActions/service_history_modals/service_history_modal.dart';
import 'package:vayujal_technician/navigation/custom_app_bar.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceHistoryItem service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar:CustomAppBar(title: "Service history"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab indicator (Service History selected)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Service History'),
                  
                ),
                
                
              ],
            ),
            const SizedBox(height: 20),
            
            // Service Details Card
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AWG Serial Number: ${service.srNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(service.serviceType),
                    Text('Technician: ${service.technician}'),
                    const SizedBox(height: 16),
                    
                    // Issues & Resolution
                    const Text(
                      'Issues & Resolution',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('Issues: ${service.issues ?? "Water Leakage from the unit"}'),
                    Text('Resolution: ${service.resolution ?? "Replaced water pipe connection"}'),
                    const SizedBox(height: 16),
                    
                    // Parts Replaced
                    const Text(
                      'Parts Replaced:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    ...(service.partsReplaced ?? ['Water Pipe', 'Filter Assembly'])
                        .map((part) => Text('• $part')),
                    const SizedBox(height: 4),
                    const Text('New S/N: FLTR-2023-45678'),
                    const SizedBox(height: 16),
                    
                    // AMC Checklist
                    const Text(
                      'AMC Checklist',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildChecklistItem('Filters changed as per AMC'),
                    _buildChecklistItem('All sensors functioning properly'),
                    _buildChecklistItem('Electrical check completed'),
                    _buildChecklistItem('Water generation & dispenser check'),
                    _buildChecklistItem('Leakage check completed'),
                    _buildChecklistItem('Full machine cleaning done'),
                    const SizedBox(height: 16),
                    
                    // Technician Suggestions
                    const Text(
                      'Technician Suggestions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...(service.technicianSuggestions ?? [
                      'Keep the area around the unit clean and dry',
                      'Check for leaks weekly',
                      'Schedule next maintenance in 3 months'
                    ]).map((suggestion) => Text('• $suggestion')),
                    const SizedBox(height: 16),
                    
                    // Next Service Date
                    if (service.nextServiceDate != null)
                      Text(
                        'Next Service: ${service.nextServiceDate!.day.toString().padLeft(2, '0')}-${service.nextServiceDate!.month.toString().padLeft(2, '0')}-${service.nextServiceDate!.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}