import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    void navigateTo(String routeName) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed(routeName);
    }

    return Drawer(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 0),
          Container(
            color: const Color(0xFFC67B02),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.menu, color: Colors.white, size: 32),
                SizedBox(width: 10),
                Text('Menu', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              children: [
                DrawerMenuItem(
                  icon: Icons.home,
                  text: "Menu Utama",
                  onTap: () => navigateTo('/home'),
                ),
                DrawerMenuItem(
                  icon: Icons.menu_book,
                  text: "Buku Tamu",
                  onTap: () => navigateTo('/guestbook'),
                ),
                DrawerMenuItem(
                  icon: Icons.settings,
                  text: "Setting",
                  onTap: () => navigateTo('/setting'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text(
              "Keluar Aplikasi",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              await windowManager.close();
            },
          ),
        ],
      ),
    );
  }
}

class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 28, color: Colors.black),
      title: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}