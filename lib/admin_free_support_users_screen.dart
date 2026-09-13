import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFreeSupportUsersScreen extends StatelessWidget {
  const AdminFreeSupportUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('إدارة مستخدمي الدعم المجاني', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: goldColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمين', style: TextStyle(color: Colors.grey)));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final userId = doc.id;
              final username = data['username'] ?? data['name'] ?? 'مستخدم';
              
              int points = 0;
              if (data['points'] != null) {
                points = int.tryParse(data['points'].toString()) ?? 0;
              }

              final isSupportBanned = data['isSupportBanned'] ?? false;

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSupportBanned ? Colors.red : goldColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المستخدم: $username', style: const TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('النقاط: $points نقطة', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('حالة الدعم: ${isSupportBanned ? "محظور" : "نشط"}', style: TextStyle(color: isSupportBanned ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => _updatePoints(context, userId, points, true),
                            child: const Text('إضافة نقاط', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            onPressed: () => _updatePoints(context, userId, points, false),
                            child: const Text('قص نقاط', style: TextStyle(color: Colors.black)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isSupportBanned ? Colors.grey : Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                                'isSupportBanned': !isSupportBanned,
                              });
                            },
                            child: Text(isSupportBanned ? 'فك الحظر' : 'حظر', style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updatePoints(BuildContext context, String userId, int currentPoints, bool isAdd) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(isAdd ? 'إضافة نقاط' : 'قص نقاط', style: const TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'أدخل العدد...', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              int val = int.tryParse(controller.text.trim()) ?? 0;
              if (val <= 0) return;

              int change = isAdd ? val : -val;
              if (!isAdd && currentPoints < val) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('النقاط المراد خصمها أكبر من رصيد المستخدم!')));
                return;
              }

              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                'points': FieldValue.increment(change),
              });

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}