import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FreeSupportScreen extends StatefulWidget {
  final String userId;
  const FreeSupportScreen({super.key, required this.userId});

  @override
  State<FreeSupportScreen> createState() => _FreeSupportScreenState();
}

class _FreeSupportScreenState extends State<FreeSupportScreen> {
  int userPoints = 0;
  bool isSupportBanned = false;
  late final WebViewController controller;
  bool isLoading = true;

  List<String> targetAccounts = [];
  String currentAccount = '';
  
  bool showNextButton = false;
  bool isFollowingRecorded = false;
  bool dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndAccounts();
  }

  void _fetchUserDataAndAccounts() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        
        // التحقق من حالة الحظر الخاصة بالدعم المجاني فقط
        isSupportBanned = data['isSupportBanned'] ?? false;

        var pts = data['points'];
        setState(() {
          userPoints = (pts is int) ? pts : int.tryParse(pts.toString()) ?? 0;
        });
      }

      if (isSupportBanned) {
        setState(() => dataLoaded = true);
        return;
      }

      List<dynamic> followedAccounts = [];
      if (userDoc.exists && userDoc.data()?['followed_accounts'] != null) {
        followedAccounts = userDoc.data()?['followed_accounts'] ?? [];
      }

      final accountsSnapshot = await FirebaseFirestore.instance.collection('support_accounts').get();
      
      List<String> fetchedAccounts = [];
      for (var doc in accountsSnapshot.docs) {
        var acc = doc.data()['account'];
        if (acc != null && acc.toString().trim().isNotEmpty) {
          String accountStr = acc.toString().trim();
          if (!followedAccounts.contains(accountStr)) {
            fetchedAccounts.add(accountStr);
          }
        }
      }

      setState(() {
        targetAccounts = fetchedAccounts;
        if (targetAccounts.isNotEmpty) {
          targetAccounts.shuffle();
          currentAccount = targetAccounts.first;
        }
        dataLoaded = true;
      });

      if (!isSupportBanned) {
        _initWebView();
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => dataLoaded = true);
    }
  }

  void _initWebView() {
    String initialUrl = currentAccount.isNotEmpty 
        ? 'https://www.instagram.com/$currentAccount/' 
        : 'https://www.instagram.com/accounts/login/';

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1")
      ..addJavaScriptChannel(
        'InstagramAction',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'followed') {
            _handleFollowAction(true);
          } else if (message.message == 'unfollowed') {
            _handleFollowAction(false);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => isLoading = false);
            _injectFollowListener();
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  void _injectFollowListener() {
    controller.runJavaScript('''
      document.addEventListener('click', function(event) {
        let target = event.target;
        if (target.tagName === 'BUTTON' || target.tagName === 'DIV' || target.tagName === 'SPAN') {
          let text = (target.innerText || target.textContent || "").trim();
          if (text === 'متابعة' || text === 'Follow') {
            InstagramAction.postMessage('followed');
          } else if (text === 'متابعة من الصديق' || text === 'Following' || text === 'إلغاء المتابعة') {
            InstagramAction.postMessage('unfollowed');
          }
        }
      }, true);
    ''');
  }

  void _handleFollowAction(bool isFollow) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    if (isFollow && !isFollowingRecorded) {
      isFollowingRecorded = true;
      await userRef.update({
        'points': FieldValue.increment(3),
        'followed_accounts': FieldValue.arrayUnion([currentAccount]),
      });

      setState(() {
        userPoints += 3;
        showNextButton = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة 3 نقاط بنجاح!')),
      );
    } else if (!isFollow && isFollowingRecorded) {
      isFollowingRecorded = false;
      await userRef.update({'points': FieldValue.increment(-3)});
      setState(() {
        userPoints -= 3;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم خصم 3 نقاط بسبب إلغاء المتابعة!')),
      );
    }
  }

  void _goToNextAccount() {
    setState(() {
      if (targetAccounts.isNotEmpty) {
        targetAccounts.remove(currentAccount);
      }
      if (targetAccounts.isNotEmpty) {
        currentAccount = targetAccounts.first;
      } else {
        currentAccount = '';
      }
      showNextButton = false;
      isFollowingRecorded = false;
      isLoading = true;
    });

    if (currentAccount.isNotEmpty) {
      controller.loadRequest(Uri.parse('https://www.instagram.com/$currentAccount/'));
    }
  }

  void _startTargetAction() {
    if (currentAccount.isEmpty) return;
    setState(() => isLoading = true);
    controller.loadRequest(Uri.parse('https://www.instagram.com/$currentAccount/'));
  }

  void _showClaimDialog() {
    final TextEditingController usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('المطالبة بنقاطي (500 متابع = 1000 نقطة)', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 15)),
        content: TextField(
          controller: usernameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'أدخل اسم مستخدم انستغرام',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              String igUser = usernameController.text.trim();
              if (igUser.isEmpty) return;

              final currentMessenger = ScaffoldMessenger.of(context);
              final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
              final docSnap = await userRef.get();
              
              int currentPoints = 0;
              if (docSnap.exists && docSnap.data()?['points'] != null) {
                var p = docSnap.data()?['points'];
                currentPoints = (p is int) ? p : int.tryParse(p.toString()) ?? 0;
              }

              if (currentPoints < 1000) {
                Navigator.pop(dialogContext);
                currentMessenger.showSnackBar(
                  const SnackBar(content: Text('نقاطك غير كافية! تحتاج إلى 1000 نقطة على الأقل.')),
                );
                return;
              }

              Navigator.pop(dialogContext);

              setState(() {
                userPoints = currentPoints - 1000;
              });

              currentMessenger.showSnackBar(
                const SnackBar(
                  content: Text('تم إرسال طلبك بنجاح وهو قيد المراجعه وتم خصم 1000 نقطة!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );

              await userRef.update({
                'points': currentPoints - 1000,
              });

              String username = 'مستخدم';
              if (docSnap.exists && docSnap.data()?['username'] != null) {
                username = docSnap.data()?['username'];
              }

              await FirebaseFirestore.instance.collection('service_orders').add({
                'userId': widget.userId,
                'username': username, 
                'targetUsername': igUser, 
                'serviceName': 'دعم مجاني (500 متابع)',
                'price': 0, 
                'points_deducted': 1000,
                'followers_count': 500,
                'status': 'قيد المراجعة',
                'rejectReason': '',
                'timestamp': FieldValue.serverTimestamp(),
              });
            },
            child: const Text('إرسال الطلب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('خدمة الدعم المجاني', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF111111),
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: !dataLoaded
          ? const Center(child: CircularProgressIndicator(color: goldColor))
          : isSupportBanned
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, color: Colors.redAccent, size: 60),
                        SizedBox(height: 16),
                        Text(
                          'تم حظرك من استخدام خدمة الدعم المجاني من قِبل المشرف!',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'نقاطك محفوظة ولن يتم المساس بها.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : targetAccounts.isEmpty || currentAccount.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'لا توجد حسابات جديدة للمتابعة حالياً!\nلقد قمت بمتابعة كافة الحسابات المتاحة أو لم تقم الإدارة بإضافة حسابات بعد.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: goldColor, width: 1.2),
                          ),
                          child: Column(
                            children: [
                              Text('نقاطك الحالية: $userPoints', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: goldColor)),
                              const Divider(color: Colors.grey, height: 12),
                              const Text('• كل 1000 نقطة = 500 متابع', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('• الحساب الحالي للمتابعة: @$currentAccount', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade800),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  WebViewWidget(controller: controller),
                                  if (isLoading)
                                    const Center(child: CircularProgressIndicator(color: goldColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: const Color(0xFF1A1A1A),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: goldColor,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onPressed: showNextButton ? _goToNextAccount : _startTargetAction,
                                  child: Text(
                                    showNextButton ? 'الانتقال للحساب التالي' : 'الانتقال للمتابعة',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onPressed: _showClaimDialog,
                                  child: const Text('المطالبة بنقاطي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}