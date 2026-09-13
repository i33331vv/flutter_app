import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String phone;
  double balance;
  bool isBanned;

  UserModel({
    required this.phone,
    this.balance = 0.0,
    this.isBanned = false,
  });

  // تحويل البيانات من فايربيس
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      isBanned: map['isBanned'] ?? false,
    );
  }

  // تحويل البيانات لإرسالها لفايربيس
  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'balance': balance,
      'isBanned': isBanned,
    };
  }
}

class UsersManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // جلب المستخدم أو إنشاؤه في فايربيس
  static Future<UserModel> getUser(String phone) async {
    final docRef = _firestore.collection('users').doc(phone);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      return UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
    } else {
      final newUser = UserModel(phone: phone, balance: 0.0, isBanned: false);
      await docRef.set(newUser.toMap());
      return newUser;
    }
  }
}