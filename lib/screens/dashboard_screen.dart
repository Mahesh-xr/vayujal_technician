
import 'package:flutter/material.dart';
import 'package:vayujal_technician/navigation/bottom_navigation.dart';
import 'package:vayujal_technician/navigation/custom_app_bar.dart';
import 'package:vayujal_technician/widgets/dashbord/quick_actions_section.dart';
import 'package:vayujal_technician/widgets/dashbord/status_cards_grid.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[80],
      appBar: const CustomAppBar(title: 'Dashboard'),
      body: _buildMainContent(),
      bottomNavigationBar: BottomNavigation(
      currentIndex: 0, // 'Devices' tab index
      onTap:(currentIndex) => BottomNavigation.navigateTo(currentIndex, context) ,
),

    );
  }

  Widget _buildMainContent() {
    return const SingleChildScrollView(
      
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusCardsGrid(),
          SizedBox(height: 32),
          QuickActionsSection(),
        ],
      ),
    );
  }
}