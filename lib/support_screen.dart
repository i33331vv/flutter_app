import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // دالة مساعدة لفتح الروابط الخارجية (واتساب، انستقرام، تليكرام)
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // التعامل مع الخطأ بصمت أو طباعته
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('المساعدة والدعم الفني', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // بطاقة الترحيب والتوضيح
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: goldColor, width: 1.5),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.support_agent, color: goldColor, size: 45),
                    SizedBox(height: 12),
                    Text(
                      'نحن هنا لمساعدتك في أي وقت!',
                      style: TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'إذا واجهتك أي مشكلة تقنية، تأخير في تنفيذ الطلبات، أو استفسار حول خدماتنا وعمليات الشحن، لا تتردد في التواصل معنا عبر إحدى الوسائل أدناه. فريق الدعم متاح لخدمتك على مدار الساعة.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                'قنوات التواصل المباشر:',
                style: TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // زر انستقرام
              _buildSupportButton(
                icon: Icons.camera_alt,
                color: Colors.purpleAccent,
                title: 'تواصل عبر انستقرام',
                subtitle: '@i3_1v',
                onTap: () => _launchURL('https://www.instagram.com/i3_1v?stkn=MTcxNWVocDB6ZWllMg=='),
              ),
              const SizedBox(height: 12),

              // زر واتساب
              _buildSupportButton(
                icon: Icons.chat,
                color: Colors.green,
                title: 'تواصل عبر واتساب',
                subtitle: '07706835751',
                onTap: () => _launchURL('https://wa.me/+9647706835751'),
              ),
              const SizedBox(height: 12),

              // زر تليجرام
              _buildSupportButton(
                icon: Icons.send,
                color: Colors.blueAccent,
                title: 'تواصل عبر تليجرام',
                subtitle: '07706835751',
                onTap: () => _launchURL('https://t.me/+9647706835751'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تصميم موحد لأزرار وسائل التواصل
  Widget _buildSupportButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}