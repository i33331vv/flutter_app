import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminServiceOrdersScreen extends StatelessWidget {
  const AdminServiceOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('إدارة طلبات شراء الخدمات', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: goldColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات شراء خدمات حالياً',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // تصفية المستندات لاستبعاد طلبات الدعم المجاني نهائياً
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String serviceName = (data['serviceName'] ?? data['title'] ?? data['service'] ?? '').toString();
            if (serviceName.contains('دعم مجاني') || serviceName.contains('مجاني')) {
              return false;
            }
            return true;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات شراء خدمات حالياً',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String orderId = doc.id;
              final String userId = data['userId'] ?? '';
              
              // 1. تحديد اسم صاحب الطلب (الذي قام بالشراء)
              String username = data['username'] ?? data['name'] ?? 'مستخدم';

              // 2. البحث الشامل عن الحساب المراد زيادته بجميع الاحتمالات الممكنة لتسمية الحقل
              final String targetUsername = data['targetUsername'] ?? 
                                            data['account'] ?? 
                                            data['link'] ?? 
                                            data['usernameTarget'] ?? 
                                            data['target'] ?? 
                                            data['user'] ?? 
                                            data['input'] ?? 
                                            data['inputValue'] ?? 'غير محدد';

              // 3. نوع الخدمة
              final String serviceName = data['serviceName'] ?? data['title'] ?? data['service'] ?? 'خدمة شراء';
              
              final double price = (data['price'] ?? data['amount'] ?? 0).toDouble();
              final String status = data['status'] ?? 'قيد المراجعة';
              final String rejectReason = data['rejectReason'] ?? '';

              Color statusColor = Colors.orange;
              if (status == 'قيد التنفيذ') statusColor = Colors.blue;
              if (status == 'مكتمل') statusColor = Colors.green;
              if (status == 'مرفوض') statusColor = Colors.red;

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: goldColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('صاحب الطلب: $username', style: const TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('نوع الخدمة: $serviceName', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('الحساب المراد زيادته: $targetUsername', style: const TextStyle(color: cyanAccentColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('المبلغ المسحوب: \$$price', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('الحالة: $status', style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold)),

                      if (status == 'مرفوض' && rejectReason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('سبب الرفض: $rejectReason', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],

                      const SizedBox(height: 12),

                      // أزرار التحكم
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (status == 'قيد المراجعة')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('service_orders').doc(orderId).update({
                                  'status': 'قيد التنفيذ',
                                });
                              },
                              child: const Text('قيد التنفيذ'),
                            ),

                          if (status == 'قيد التنفيذ' || status == 'قيد المراجعة')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('service_orders').doc(orderId).update({
                                  'status': 'مكتمل',
                                });
                              },
                              child: const Text('مكتمل'),
                            ),

                          if (status != 'مكتمل' && status != 'مرفوض')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () {
                                _showRejectDialog(context, orderId, userId, price);
                              },
                              child: const Text('رفض واسترجاع المبلغ'),
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

  // تعريف اللون السماوي لتجنب أي خطأ في اللون
  static const Color cyanAccentColor = Colors.cyanAccent;

  // نافذة الرفض وإعادة الرصيد
  void _showRejectDialog(BuildContext context, String orderId, String userId, double price) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('سبب الرفض', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'اكتب سبب الرفض هنا...',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              String reason = reasonController.text.trim();
              if (reason.isEmpty) reason = 'لم يتم ذكر السبب';

              final firestore = FirebaseFirestore.instance;
              final batch = firestore.batch();

              final orderRef = firestore.collection('service_orders').doc(orderId);
              final userRef = firestore.collection('users').doc(userId);

              batch.update(orderRef, {
                'status': 'مرفوض',
                'rejectReason': reason,
              });

              batch.update(userRef, {
                'balance': FieldValue.increment(price),
              });

              await batch.commit();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );
  }
}