import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  // دالة لتلوين وتصميم شارة الحالة
  Widget _getStatusBadge(String status) {
    Color bgColor;
    Color textColor = Colors.black;

    switch (status) {
      case 'قيد المراجعة':
        bgColor = Colors.orangeAccent;
        break;
      case 'قيد التنفيذ':
        bgColor = Colors.blueAccent;
        textColor = Colors.white;
        break;
      case 'مكتمل':
        bgColor = Colors.green;
        textColor = Colors.white;
        break;
      case 'مرفوض':
      case 'رفض':
        bgColor = Colors.redAccent;
        textColor = Colors.white;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('سجل الطلبات التفصيلي', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'الرجاء تسجيل الدخول لعرض طلباتك',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('service_orders')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: goldColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد طلبات حالياً.\nقم بشراء خدمة لتظهر هنا!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp? timeA = dataA['timestamp'] as Timestamp?;
                  Timestamp? timeB = dataB['timestamp'] as Timestamp?;
                  if (timeA == null || timeB == null) return 0;
                  return timeB.compareTo(timeA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    final String title = data['title'] ?? data['serviceName'] ?? 'طلب خدمة';
                    final String targetUser = data['targetUsername'] ?? data['account'] ?? data['username'] ?? 'غير معروف';
                    final dynamic price = data['price'] ?? data['amount'] ?? 0;
                    final String status = data['status'] ?? 'قيد المراجعة';
                    
                    // 🔥 شملنا جميع الأسماء المحتملة لحقل سبب الرفض لضمان ظهوره فوراً
                    final String? rejectionReason = data['rejectReason'] ?? data['rejectionReason'] ?? data['reject_reason'] ?? data['reason'];
                    
                    String dateStr = '';
                    if (data['timestamp'] != null) {
                      DateTime dateTime = (data['timestamp'] as Timestamp).toDate();
                      dateStr = dateTime.toString().substring(0, 16);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: goldColor.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shopping_cart, color: Colors.blueAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'خدمة متابعين',
                                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              _getStatusBadge(status),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 16),

                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'الحساب المستهدف: @$targetUser',
                            style: const TextStyle(color: goldColor, fontSize: 13),
                          ),
                          
                          if ((status == 'مرفوض' || status == 'رفض') && rejectionReason != null && rejectionReason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'سبب الرفض: $rejectionReason',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المبلغ: \$$price',
                                style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                dateStr,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}