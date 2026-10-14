import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'settings_screen.dart';

// Layout follows wireframe 1l. All values are placeholders for now.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 2, thickness: 2, color: Colors.black),
            _buildUserCard(),
            const Divider(height: 2, thickness: 2, color: Colors.black),
            _buildStats(),
            const Divider(height: 2, thickness: 2, color: Colors.black),
            _buildWorkingHours(),
            const Divider(height: 1),
            _buildMenuRow(
              title: 'Labels & categories',
              count: 4,
              onTap: () {
                // TODO: open labels screen (1k)
              },
            ),
            const Divider(height: 1),
            _buildMenuRow(
              title: 'Import & export',
              count: 2,
              onTap: () {
                // TODO: open import & export screen (1n)
              },
            ),
            const Divider(height: 1),
            _buildMenuRow(
              title: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Log out', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey, width: 2),
            ),
            child: const Icon(Icons.person, size: 36, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jane Doe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'jane.doe@example.com',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStat('87%', 'on time'),
          const VerticalDivider(width: 1, color: Colors.grey),
          _buildStat('14h', 'planned this week'),
          const VerticalDivider(width: 1, color: Colors.grey),
          _buildStat('23', 'tasks done'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String caption) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              caption,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHours() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKING HOURS',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text('Mon - Fri, 09:00 - 17:00'),
          SizedBox(height: 2),
          Text(
            'Lunch break 12:00 - 13:00',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required String title,
    int? count,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            Text('$count', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
