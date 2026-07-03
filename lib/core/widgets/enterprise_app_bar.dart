import 'package:flutter/material.dart';

class EnterpriseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userName;
  final String role;
  final VoidCallback onLogout;

  const EnterpriseAppBar({
    super.key,
    required this.title,
    required this.userName,
    required this.role,
    required this.onLogout,
  });

  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      title: Text(title),
      actions: [
        const Icon(Icons.notifications_none),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          offset: const Offset(0, 45),
          onSelected: (value) {
            if (value == 'logout') {
              onLogout();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 10),
                  Text("Profile"),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 10),
                  Text("Logout"),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      role.toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
