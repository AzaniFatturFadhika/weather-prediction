import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate to login page on logout
    void _logout() {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }

    return Scaffold(
      // The scaffold background color is now set by the theme in main.dart
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 24),
          _buildProfileMenu(context),
          const SizedBox(height: 24),
          _buildLogoutButton(context, _logout),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: const CircleAvatar(
                  radius: 56,
                  backgroundImage: NetworkImage(
                    // Placeholder image
                    'https://i.pravatar.cc/150?u=a042581f4e29026704d',
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.cardColor,
                  child: Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mamur Sayor',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1901029@iot.bdu.ac.bd',
            style: TextStyle(
              fontSize: 16.0,
              color: theme.colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildMenuCard(
            context,
            children: [
              _buildMenuListTile(
                context,
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  // Handle navigation or action
                },
              ),
              _buildMenuListTile(
                context,
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // Handle navigation or action
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            context,
            children: [
              _buildMenuListTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  // Handle navigation or action
                },
              ),
              _buildMenuListTile(
                context,
                icon: Icons.language_outlined,
                title: 'Language',
                onTap: () {
                  // Handle navigation or action
                },
              ),
              _buildMenuListTile(
                context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  // Handle navigation or action
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, VoidCallback onLogout) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Logout',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: theme.colorScheme.error.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.hintColor),
      onTap: onTap,
    );
  }
}
