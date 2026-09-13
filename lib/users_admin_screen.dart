import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  String _searchUsername = '';

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('إدارة المستخدمين (بأسماء المستخدمين)', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: Column(
        children: [
          // شريط البحث باسم المستخدم
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchUsername = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث باسم المستخدم...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: goldColor),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: goldColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: goldColor, width: 2),
                ),
              ),
            ),
          ),

          // قائمة المستخدمين من Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: goldColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد حسابات مسجلة حالياً', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                final docs = snapshot.data!.docs;

                // تصفية المستخدمين بناءً على اسم المستخدم المدخل في خانة البحث
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final username = (data['username'] ?? data['name'] ?? 'مستخدم مجهول').toString().toLowerCase();
                  return username.contains(_searchUsername);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('لا يوجد مطابق للبحث', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String username = data['username'] ?? data['name'] ?? 'مستخدم مجهول';
                    final double balance = (data['balance'] ?? 0).toDouble();
                    final bool isBanned = data['isBanned'] ?? false;

                    return Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isBanned ? Colors.red : goldColor, width: 1),
                      ),
                      child: ListTile(
                        title: Text(
                          'المستخدم: $username',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            'الرصيد: \$$balance\nالحالة: ${isBanned ? "محظور" : "نشط"}',
                            style: TextStyle(color: isBanned ? Colors.redAccent : Colors.grey, fontSize: 13),
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBanned ? Colors.green : Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            // عكس حالة الحظر مباشرة في قاعدة البيانات
                            await FirebaseFirestore.instance.collection('users').doc(doc.id).update({
                              'isBanned': !isBanned,
                            });
                          },
                          child: Text(isBanned ? 'إلغاء الحظر' : 'حظر'),
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
    );
  }
}