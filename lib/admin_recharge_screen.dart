import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRechargeRequestsScreen extends StatelessWidget {
  const AdminRechargeRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('إدارة طلبات شحن الرصيد', style: TextStyle(color: goldColor)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recharge_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: goldColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات شحن معلقة حالياً',
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
              
              final String userId = data['userId'] ?? 'unknown';
              final String amount = data['amount'] ?? '0';
              final String status = data['status'] ?? 'pending';
              final String username = data['username'] ?? 'مستخدم مجهول';
              final String base64Image = data['imageBase64'] ?? '';

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
                      Text('المستخدم: $username', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('المبلغ المطلوب: $amount د.ع', style: const TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('الحالة: $status', style: TextStyle(color: status == 'pending' ? Colors.orange : (status == 'approved' ? Colors.green : Colors.red))),
                      const SizedBox(height: 12),
                      
                      // عرض لقطة الشاشة المحفوظة كـ Base64 للمشرف
                      if (base64Image.isNotEmpty) ...[
                        const Text('لقطة شاشة التحويل:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            // نافذة منبثقة لتكبير الصورة عند الضغط عليها
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.black,
                                child: InteractiveViewer(
                                  child: Image.memory(base64Decode(base64Image)),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(base64Image),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (status == 'pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('recharge_requests')
                                    .doc(doc.id)
                                    .update({'status': 'rejected'});
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('رفض'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () async {
                                final double addedAmount = double.tryParse(amount) ?? 0.0;
                                
                                // 1. تحديث حالة الطلب إلى مقبول
                                await FirebaseFirestore.instance
                                    .collection('recharge_requests')
                                    .doc(doc.id)
                                    .update({'status': 'approved'});

                                // 2. تحديث رصيد المستخدم في مجموعة users
                                if (userId != 'unknown') {
                                  final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
                                  
                                  final userSnapshot = await userDocRef.get();
                                  if (userSnapshot.exists) {
                                    final currentBalance = (userSnapshot.data()?['balance'] ?? 0).toDouble();
                                    await userDocRef.update({'balance': currentBalance + addedAmount});
                                  } else {
                                    await userDocRef.set({
                                      'balance': addedAmount,
                                      'username': username,
                                    }, SetOptions(merge: true));
                                  }
                                }
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('قبول'),
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
}