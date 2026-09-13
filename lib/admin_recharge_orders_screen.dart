import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class AdminRechargeOrdersScreen extends StatelessWidget {
  const AdminRechargeOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('إدارة طلبات الشحن', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب الطلبات وترتيبها تنازلياً بحيث يظهر الطلب الأحدث في الأعلى دائماً
        stream: FirebaseFirestore.instance
            .collection('recharge_orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: goldColor));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'خطأ في جلب البيانات: ${snapshot.error}\n(ملاحظة: إذا طُلب فهرس Index من فايربيس، يرجى النقر على الرابط الموجود في الكونسول لتفعيله)',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات شحن رصيد مرسلة حالياً',
                textAlign: TextAlign.center,
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
              final String username = data['username'] ?? 'مستخدم مجهول';
              final double amount = (data['amount'] ?? 0).toDouble();
              final String receiptUrl = data['receiptUrl'] ?? '';
              final String status = data['status'] ?? 'قيد المراجعة';

              Color statusColor = Colors.orange;
              if (status == 'مقبول') statusColor = Colors.green;
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
                      Text('المستخدم: $username', style: const TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('المبلغ المطلوب: \$$amount', style: const TextStyle(color: Colors.white, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('الحالة: $status', style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      // معاينة صورة الإيصال عبر Base64 Memory
                      if (receiptUrl.isNotEmpty) ...[
                        const Text('صورة الإيصال:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildReceiptImage(receiptUrl),
                        ),
                        const SizedBox(height: 8),
                        
                        // زر حفظ الصورة في الجهاز
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: goldColor),
                              foregroundColor: goldColor,
                            ),
                            onPressed: () => _saveImageToDevice(context, receiptUrl),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('حفظ الصورة في الجهاز'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (status == 'قيد المراجعة') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('recharge_orders')
                                    .doc(doc.id)
                                    .update({'status': 'مرفوض'});
                              },
                              child: const Text('رفض'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              onPressed: () async {
                                final batch = FirebaseFirestore.instance.batch();
                                final orderRef = FirebaseFirestore.instance.collection('recharge_orders').doc(doc.id);
                                final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

                                batch.update(orderRef, {'status': 'مقبول'});
                                batch.update(userRef, {'balance': FieldValue.increment(amount)});

                                await batch.commit();
                              },
                              child: const Text('قبول وإضافة الرصيد'),
                            ),
                          ],
                        ),
                      ],
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

  // دالة عرض الصورة المعالجة من Base64
  Widget _buildReceiptImage(String receiptData) {
    try {
      String base64String = receiptData;
      if (receiptData.contains(',')) {
        base64String = receiptData.split(',').last;
      }
      
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Text(
          'تعذر عرض الصورة',
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    } catch (e) {
      return const Text(
        'صيغة الصورة غير صالحة',
        style: TextStyle(color: Colors.redAccent),
      );
    }
  }

  // دالة حفظ الصورة في المستندات المحلية للجهاز
  Future<void> _saveImageToDevice(BuildContext context, String receiptData) async {
    try {
      String base64String = receiptData;
      if (receiptData.contains(',')) {
        base64String = receiptData.split(',').last;
      }
      
      final bytes = base64Decode(base64String);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الصورة بنجاح في المسار:\n$filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ الصورة: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}