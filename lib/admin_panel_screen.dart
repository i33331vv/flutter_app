import 'package:flutter/material.dart';

// استيراد شاشات لوحة تحكم المشرف
import 'users_admin_screen.dart'; 
import 'admin_free_support_orders_screen.dart';
import 'admin_recharge_orders_screen.dart';
import 'banned_users_screen.dart';
import 'admin_service_orders_screen.dart'; // شاشة إدارة طلبات شراء الخدمات للمطور

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildAdminButton(
              context,
              title: 'إدارة المستخدمين والبحث',
              color: Colors.blue,
              icon: Icons.people,
              targetScreen: const UsersAdminScreen(),
            ),
            const SizedBox(height: 12),
            _buildAdminButton(
              context,
              title: 'إدارة طلبات الدعم المجاني',
              color: Colors.red,
              icon: Icons.card_giftcard,
              targetScreen: const AdminFreeSupportOrdersScreen(),
            ),
            const SizedBox(height: 12),
            _buildAdminButton(
              context,
              title: 'إدارة طلبات الشحن',
              color: Colors.green,
              icon: Icons.account_balance_wallet,
              targetScreen: const AdminRechargeOrdersScreen(),
            ),
            const SizedBox(height: 12),
            
            // 🔥 زر إدارة طلبات شراء الخدمات الجديد للمطور 🔥
            _buildAdminButton(
              context,
              title: 'إدارة طلبات شراء الخدمات',
              color: Colors.deepPurple,
              icon: Icons.shopping_cart_checkout,
              targetScreen: const AdminServiceOrdersScreen(),
            ),
            
            const SizedBox(height: 12),
            _buildAdminButton(
              context,
              title: 'قائمة المستخدمين المحظورين',
              color: Colors.orange,
              icon: Icons.block,
              targetScreen: const BannedUsersScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لتصميم الأزرار بشكل موحد وأنيق
  Widget _buildAdminButton(
    BuildContext context, {
    required String title,
    required Color color,
    required IconData icon,
    required Widget targetScreen,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      icon: Icon(icon, size: 26),
      label: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}