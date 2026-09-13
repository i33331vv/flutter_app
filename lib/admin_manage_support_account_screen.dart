import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManageSupportAccountsScreen extends StatefulWidget {
  const AdminManageSupportAccountsScreen({super.key});

  @override
  State<AdminManageSupportAccountsScreen> createState() => _AdminManageSupportAccountsScreenState();
}

class _AdminManageSupportAccountsScreenState extends State<AdminManageSupportAccountsScreen> {
  final TextEditingController _accountController = TextEditingController();
  final Color goldColor = const Color(0xFFD4AF37);

  // دالة لإضافة حساب جديد لقاعدة البيانات
  void _addAccount() async {
    String account = _accountController.text.trim();
    if (account.isEmpty) return;

    await FirebaseFirestore.instance.collection('support_accounts').add({
      'account': account,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _accountController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة الحساب بنجاح ✅'), backgroundColor: Colors.green),
    );
  }

  // دالة لحذف حساب
  void _deleteAccount(String docId) async {
    await FirebaseFirestore.instance.collection('support_accounts').doc(docId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الحساب 🗑️'), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: Text('إدارة حسابات الدعم المجاني', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: goldColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // حقل إضافة حساب جديد
            TextField(
              controller: _accountController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'اكتب اسم الحساب أو الرابط المراد متابعته...',
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: goldColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addAccount,
                child: const Text('إضافة حساب للدعم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('الحسابات المضافة حالياً:', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            // قائمة الحسابات المضافة مع زر الحذف
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('support_accounts').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: goldColor));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا توجد حسابات مضافة حالياً', style: TextStyle(color: Colors.grey)));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final String account = data['account'] ?? '';

                      return Card(
                        color: const Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: goldColor.withValues(alpha: 0.5)),
                        ),
                        child: ListTile(
                          title: Text(account, style: const TextStyle(color: Colors.white, fontSize: 15)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteAccount(doc.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}