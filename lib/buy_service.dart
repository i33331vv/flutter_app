import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyServiceScreen extends StatefulWidget {
  const BuyServiceScreen({super.key});

  @override
  State<BuyServiceScreen> createState() => _BuyServiceScreenState();
}

class _BuyServiceScreenState extends State<BuyServiceScreen> {
  final List<Map<String, dynamic>> _packages = [
    {'title': '1200 متابع', 'price': 10.0},
    {'title': '2500 متابع', 'price': 20.0},
    {'title': '3800 متابع', 'price': 30.0},
    {'title': '5100 متابع', 'price': 40.0},
    {'title': '6400 متابع', 'price': 50.0},
    {'title': '7700 متابع', 'price': 60.0},
    {'title': '9000 متابع', 'price': 70.0},
    {'title': '10300 متابع', 'price': 80.0},
    {'title': '11600 متابع', 'price': 90.0},
    {'title': '12900 متابع', 'price': 100.0},
    {'title': '14200 متابع', 'price': 110.0},
    {'title': '15500 متابع', 'price': 120.0},
    {'title': '16800 متابع', 'price': 130.0},
    {'title': '18100 متابع', 'price': 140.0},
  ];

  bool _isOrdering = false;

  // دالة إتمام الطلب وخصم المبلغ بعد التأكيد
  Future<void> _processOrder(String title, double price, double currentBalance, String targetUsername) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (currentBalance < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رصيدك لا يكفي! اشحن رصيدك أولاً لإتمام الطلب.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isOrdering = true);

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // خصم المبلغ من الرصيد الموحد باستخدام Transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);
        double latestBalance = 0.0;
        if (snapshot.exists) {
          latestBalance = (snapshot.data()?['balance'] ?? 0).toDouble();
        }

        if (latestBalance < price) {
          throw Exception('رصيدك لا يكفي!');
        }

        double newBalance = latestBalance - price;
        transaction.update(userDocRef, {'balance': newBalance});
      });

      // إرسال الطلب للمطور مع اسم الحساب المستهدف والحالة قيد المراجعة
      await FirebaseFirestore.instance.collection('service_orders').add({
        'userId': user.uid,
        'username': targetUsername, // اسم الحساب المراد زيادة المتابعين له
        'title': title,
        'price': price,
        'status': 'قيد المراجعة',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isOrdering = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال طلبك بنجاح ($title) للحساب ($targetUsername) وهو الآن قيد المراجعة.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOrdering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // نافذة إدخال اسم المستخدم ثم الانتقال لنافذة التأكيد
  void _showUsernameDialog(String title, double price, double currentBalance) {
    final TextEditingController usernameController = TextEditingController();
    const Color goldColor = Color(0xFFD4AF37);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('طلب: $title', style: const TextStyle(color: goldColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اكتب اسم المستخدم الخاص بك بعناية، أي خطأ فيه سوف يؤخر العملية:',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'مثال: username@ أو رابط الحساب',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
            onPressed: () {
              String targetUser = usernameController.text.trim();
              if (targetUser.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء كتابة اسم المستخدم أولاً')),
                );
                return;
              }
              Navigator.pop(context); // إغلاق نافذة الاسم
              _showConfirmationDialog(title, price, currentBalance, targetUser); // فتح نافذة التأكيد
            },
            child: const Text('التالي', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // نافذة التأكيد النهائى قبل الشراء وخصم الرصيد
  void _showConfirmationDialog(String title, double price, double currentBalance, String targetUser) {
    const Color goldColor = Color(0xFFD4AF37);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('تأكيد الشراء', style: TextStyle(color: goldColor)),
        content: Text(
          'هل أنت متأكد من الشراء؟\n\nالخدمة: $title\nالمبلغ: \$$price\nالحساب: $targetUser',
          style: const TextStyle(color: Colors.white, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // إغلاق نافذة التأكيد
              _processOrder(title, price, currentBalance, targetUser); // تنفيذ الطلب والخصم
            },
            child: const Text('تأكيد وإرسال', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
        title: const Text('شراء خدمة - دعم محمد مدين', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
            : null,
        builder: (context, snapshot) {
          double userBalance = 0.0;
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            userBalance = (data['balance'] ?? 0).toDouble();
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: goldColor, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$userBalance\$',
                      style: const TextStyle(fontSize: 22, color: goldColor, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'رصيدك الحالي',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  'جميع الخدمات متابعين حقيقيين وعراقيين 100%',
                  style: TextStyle(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final pkg = _packages[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: goldColor, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                pkg['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: goldColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${pkg['price']}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _isOrdering
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: goldColor, strokeWidth: 2),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: goldColor,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _showUsernameDialog(pkg['title'], pkg['price'], userBalance),
                                    child: const Text(
                                      'اطلب الآن',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}