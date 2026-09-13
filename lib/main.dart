import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محمد مدين',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF111111),
      ),
      // التحقق المباشر من حالة المصادقة عند فتح التطبيق
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // إذا كان جارياً التحقق من الحالة
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF111111),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              ),
            );
          }

          // إذا كان المستخدم مسجلاً دخوله بالفعل
          if (snapshot.hasData && snapshot.data != null) {
            // استخراج اسم المستخدم من البريد الإلكتروني الوهمي
            String email = snapshot.data!.email ?? '';
            String username = email.contains('@') ? email.split('@')[0] : '';
            return HomeScreen(username: username);
          }

          // إذا لم يكن مسجلاً أو قام بتسجيل الخروج
          return const AuthScreen();
        },
      ),
    );
  }
}