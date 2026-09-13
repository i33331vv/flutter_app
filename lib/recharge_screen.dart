import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _amountController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  
  final Color customGoldColor = const Color(0xFFD4AF37);
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRechargeRequest() async {
    if (_amountController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال المبلغ وإرفاق لقطة الشاشة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('الرجاء تسجيل الدخول أولاً');
      }

      String username = 'مستخدم';
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        username = userData['username'] ?? userData['name'] ?? 'مستخدم';
      } else if (user.email != null && user.email!.contains('@')) {
        username = user.email!.split('@')[0];
      }

      List<int> imageBytes = await _selectedImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('recharge_orders').add({
        'userId': user.uid,
        'username': username,
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'receiptUrl': 'data:image/jpeg;base64,$base64Image',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'قيد المراجعة',
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الشحن بنجاح، بانتظار موافقة المشرف')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('شحن الرصيد', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: customGoldColor),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots() 
            : null,
        builder: (context, userSnapshot) {
          double balance = 0.0;
          if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            balance = (data['balance'] ?? 0).toDouble();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: customGoldColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('عدد رصيدك:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('$balance د.ع', style: TextStyle(color: customGoldColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🔥 الصندوق الإرشادي مع رسالة الثقة واسم محمد مدين 🔥
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: customGoldColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لشحن رصيد حول المبلغ الى الأرقام الظاهرة في الأسفل:',
                        style: TextStyle(color: customGoldColor, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'اسياسيل : 07703456710\nزين كاش : 07706835751\nماستر : 1137316012',
                        style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                      ),
                      const Divider(color: Colors.grey, height: 25),
                      const Text(
                        '⚠️ تنبيه هام:\nعند قيامك بتحويل المبلغ، قم بعمل لقطة شاشة (إيصال التحويل) وارفقها في خيار "إرفاق لقطة الشاشة" أدناه، خلافاً عن ذلك قد يسبب تأخير في شحن رصيدك.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 13, height: 1.4, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '✨ مع تحيات إدارة دعم محمد مدين - نضمن لك السرعة والأمان التام في إنجاز كافة معاملاتك بكل ثقة ومصداقية.',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'أدخل المبلغ المراد شحنه',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: customGoldColor)),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: Colors.black),
                  label: Text(_selectedImage == null ? 'إرفاق لقطة الشاشة' : 'تم اختيار الصورة (تغيير)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customGoldColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                if (_selectedImage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: customGoldColor),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),

                _isLoading
                    ? Center(child: CircularProgressIndicator(color: customGoldColor))
                    : ElevatedButton(
                        onPressed: (_amountController.text.isNotEmpty && _selectedImage != null)
                            ? _submitRechargeRequest
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('تأكيد وإرسال طلب الشحن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}