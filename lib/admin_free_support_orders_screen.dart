import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFreeSupportOrdersScreen extends StatelessWidget {
  const AdminFreeSupportOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('إدارة طلبات الدعم المجاني', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_orders')
            .where('price', isEqualTo: 0) // تصفية طلبات الدعم المجاني حصراً
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: goldColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات دعم مجاني حالياً',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String userId = data['userId'] ?? '';
              final String targetAccount = data['targetUsername'] ?? 'غير معروف';
              final int pointsDeducted = data['points_deducted'] ?? 1000;
              final int followersCount = data['followers_count'] ?? 500;
              final String status = data['status'] ?? 'قيد المراجعة';
              final String? rejectReason = data['rejectionReason'];

              Color statusColor = Colors.orange;
              if (status == 'قيد التنفيذ') statusColor = Colors.blue;
              if (status == 'مكتمل') statusColor = Colors.green;
              if (status == 'رفض' || status == 'مرفوض') statusColor = Colors.red;

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
                      Text('الحساب المستهدف: @$targetAccount', style: const TextStyle(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('معرف المستخدم (ID): $userId', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('النقاط المخصومة: $pointsDeducted نقطة ($followersCount متابع)', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('الحالة: $status', style: TextStyle(color: statusColor, fontSize: 15, fontWeight: FontWeight.bold)),

                      if ((status == 'رفض' || status == 'مرفوض') && rejectReason != null && rejectReason.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('السبب: $rejectReason', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'قيد المراجعة') ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('service_orders')
                                    .doc(doc.id)
                                    .update({'status': 'قيد التنفيذ'});
                              },
                              child: const Text('قيد التنفيذ'),
                            ),
                            const SizedBox(width: 8),
                          ],

                          if (status == 'قيد المراجعة' || status == 'قيد التنفيذ') ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('service_orders')
                                    .doc(doc.id)
                                    .update({'status': 'مكتمل'});
                              },
                              child: const Text('اكتمال'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () {
                                final TextEditingController reasonController = TextEditingController();

                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    title: const Text('سبب الرفض', style: TextStyle(color: goldColor)),
                                    content: TextField(
                                      controller: reasonController,
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText: 'اكتب سبب رفض الطلب هنا...',
                                        hintStyle: TextStyle(color: Colors.grey),
                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        onPressed: () async {
                                          String reason = reasonController.text.trim();
                                          if (reason.isEmpty) reason = 'لم يتم ذكر السبب';

                                          final scaffoldContext = context;
                                          Navigator.pop(dialogContext);

                                          try {
                                            await FirebaseFirestore.instance.runTransaction((transaction) async {
                                              final orderRef = FirebaseFirestore.instance.collection('service_orders').doc(doc.id);
                                              final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

                                              final userSnapshot = await transaction.get(userRef);

                                              int currentPoints = 0;
                                              if (userSnapshot.exists && userSnapshot.data()?['points'] != null) {
                                                var p = userSnapshot.data()?['points'];
                                                currentPoints = (p is int) ? p : int.tryParse(p.toString()) ?? 0;
                                              }
                                              int refundedPoints = currentPoints + pointsDeducted;

                                              transaction.update(orderRef, {
                                                'status': 'رفض',
                                                'rejectionReason': reason,
                                              });

                                              if (userSnapshot.exists) {
                                                transaction.update(userRef, {'points': refundedPoints});
                                              } else {
                                                transaction.set(userRef, {'points': refundedPoints}, SetOptions(merge: true));
                                              }
                                            });

                                            if (scaffoldContext.mounted) {
                                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                                const SnackBar(
                                                  content: Text('تم رفض الطلب واسترجاع النقاط للمستخدم بنجاح'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (scaffoldContext.mounted) {
                                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                                SnackBar(
                                                  content: Text('حدث خطأ أثناء الرفض: $e'),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('تأكيد الرفض واسترجاع النقاط'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('رفض'),
                            ),
                          ],
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
}