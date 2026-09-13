import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'buy_service.dart';
import 'free_support_screen.dart';
import 'recharge_screen.dart';
import 'orders_screen.dart';
import 'support_screen.dart';
import 'auth_screen.dart';
import 'users_admin_screen.dart';
import 'banned_users_screen.dart';
import 'admin_free_support_orders_screen.dart';
import 'admin_recharge_orders_screen.dart';
import 'admin_service_orders_screen.dart';
import 'admin_manage_support_account_screen.dart';
import 'admin_free_support_users_screen.dart'; // 🔥 استيراد شاشة إدارة مستخدمي ونقاط الدعم المجاني الجديدة

class HomeScreen extends StatelessWidget {
  final String? username;
  const HomeScreen({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return DashboardScreen(username: username ?? '');
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final bool isBanned = data['isBanned'] ?? false;

          if (isBanned) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حظرك من قبل المشرف!'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            });
          }
        }

        return DashboardScreen(username: username ?? '');
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String username;
  const DashboardScreen({super.key, this.username = ''});

  final String developerUsername = 'ali'; 

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final currentUser = FirebaseAuth.instance.currentUser;
    
    bool isDeveloper = (username.trim() == developerUsername);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('لوحة الخدمات الرئيسية', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: () => _logout(context),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // أزرار المشرف الخاصة
            if (isDeveloper) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UsersAdminScreen()),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('إدارة المستخدمين والبحث', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminFreeSupportOrdersScreen()),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('إدارة طلبات الدعم المجاني', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),

              // زر إدارة حسابات الدعم المجاني (إضافة/حذف حسابات المتابعة)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminManageSupportAccountsScreen()),
                    );
                  },
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text('إدارة حسابات الدعم المجاني', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),

              // 🔥 زر إدارة مستخدمي ونقاط وحظر الدعم المجاني (الجديد كلياً) 🔥
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminFreeSupportUsersScreen()),
                    );
                  },
                  icon: const Icon(Icons.supervised_user_circle),
                  label: const Text('إدارة نقاط ومستخدمي الدعم المجاني', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminRechargeOrdersScreen()),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('إدارة طلبات الشحن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminServiceOrdersScreen()),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('إدارة طلبات شراء الخدمات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BannedUsersScreen()),
                    );
                  },
                  icon: const Icon(Icons.block, color: Colors.black),
                  label: const Text('قائمة المستخدمين المحظورين وفك الحظر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // باقي الخدمات العامة
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCustomCard(context, 'شراء خدمة', Icons.shopping_cart, goldColor, const BuyServiceScreen()),
                  _buildCustomCard(
                    context, 
                    'الدعم المجاني', 
                    Icons.card_giftcard, 
                    goldColor, 
                    FreeSupportScreen(userId: currentUser != null ? currentUser.uid : '')
                  ),
                  _buildCustomCard(context, 'شحن رصيد', Icons.account_balance_wallet, goldColor, const RechargeScreen()),
                  _buildCustomCard(context, 'الطلبات', Icons.list_alt, goldColor, const OrdersScreen()),
                  _buildCustomCard(context, 'المساعدة والدعم', Icons.help_outline, goldColor, const SupportScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCard(BuildContext context, String title, IconData icon, Color color, Widget destinationScreen) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationScreen),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}