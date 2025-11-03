import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/map_page.dart';
import '../pages/pickup_page.dart';
import '../pages/profile_page.dart';
import '../models/device.dart';
import '../models/user_model.dart';

class EwasteNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final UserModel? user;
  final List<Device> devices;
  final void Function(Device)? onDeviceUpdated;

  const EwasteNavigationBar({
    super.key,
    required this.selectedIndex,
    this.user,
    this.devices = const [],
    this.onDeviceUpdated,
  });

  void _handleNavigation(BuildContext context, int idx) {
    if (idx == selectedIndex) return; // Already on this tab
    Widget page;
    switch (idx) {
      case 0:
        page = HomePage(user: user);
        break;
      case 1:
        page = const MapPage();
        break;
      case 3:
        page = const PickupPage();
        break;
      case 4:
        // Provide required arguments for ProfilePage
        page = ProfilePage(
          devices: devices,
          onDeviceUpdated: onDeviceUpdated ?? (d) {},
          name: user?.displayName ?? 'User',
          phone: user?.phoneNumber ?? 'Not provided',
          address: 'Not provided', // You can add this to UserModel if needed
          user: user,
        );
        break;
      default:
        return;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (c) => page));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomAppBar(
          color: Colors.white,
          height: 70,
          padding: EdgeInsets.zero,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () => _handleNavigation(context, 0),
              ),
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Maps',
                selected: selectedIndex == 1,
                onTap: () => _handleNavigation(context, 1),
              ),
              const SizedBox(width: 40),
              _NavItem(
                icon: Icons.local_shipping_outlined,
                activeIcon: Icons.local_shipping,
                label: 'Pickup',
                selected: selectedIndex == 3,
                onTap: () => _handleNavigation(context, 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                selected: selectedIndex == 4,
                onTap: () => _handleNavigation(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 26,
              color: selected ? cs.primary : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? cs.primary : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
