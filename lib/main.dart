import 'package:material_ui/material_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

class AppColors {
  static const Color navy = Color(0xFF0A1330);
  static const Color navySoft = Color(0xFF14224A);
  static const Color mint = Color(0xFF59F0B5);
  static const Color mintSoft = Color(0xFFDDFBF0);
  static const Color lavender = Color(0xFFE7DBFF);
  static const Color lavenderDark = Color(0xFF8F73FF);
  static const Color pageBg = Color(0xFFF7F8FC);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF101828);
  static const Color textSoft = Color(0xFF667085);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const TrustPayApp());
}

class TrustPayApp extends StatelessWidget {
  const TrustPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrustPay 360',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.pageBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.mint,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.pageBg,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textDark),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSoft),
        ),
      ),

      home: const TrustPayHome(),
    );
  }
}

class TrustPayHome extends StatefulWidget {
  const TrustPayHome({super.key});

  @override
  State<TrustPayHome> createState() => _TrustPayHomeState();
}

class _TrustPayHomeState extends State<TrustPayHome> {
  int currentPage = 0;
  bool useKannada = false;

  int sessionNumber = 1000;
  bool isSavingRequest = false;
  String sessionId = 'No payment request';

  String? activeRequestDocId;

  String paymentStatus = 'Not started';

  double amount = 500;
  bool firstPayment = true;
  bool recipientMatches = true;
  bool urgentRequest = false;
  bool receiptMissing = false;
  bool reviewSubmitted = false;

  final amountController = TextEditingController(text: '500');
  final expenseController = TextEditingController();
  final budgetController = TextEditingController(text: '5000');

  double monthlyBudget = 5000;
  String expenseCategory = 'Groceries';

  final List<Map<String, dynamic>> expenseRecords = [];
  final List<Map<String, dynamic>> collectionRecords = [];
  final List<String> timeline = [];

  String t(String english, String kannada) {
    return useKannada ? kannada : english;
  }

  String money(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  double get totalExpenses {
    return expenseRecords.fold<double>(
      0,
      (total, record) => total + (record['amount'] as double),
    );
  }

  double get totalCollections {
    return collectionRecords.fold<double>(
      0,
      (total, record) => total + (record['amount'] as double),
    );
  }

  int get riskScore {
    int score = 0;

    if (firstPayment) score += 15;
    if (!recipientMatches) score += 60;
    if (urgentRequest) score += 25;
    if (amount >= 5000) score += 20;

    return score.clamp(0, 100);
  }

  String get riskLevel {
    if (riskScore >= 60) {
      return t('High Risk', 'ಹೆಚ್ಚಿನ ಅಪಾಯ');
    }
    if (riskScore >= 25) {
      return t('Medium Risk', 'ಮಧ್ಯಮ ಅಪಾಯ');
    }
    return t('Low Risk', 'ಕಡಿಮೆ ಅಪಾಯ');
  }

  Color get riskColor {
    if (riskScore >= 60) return Colors.red;
    if (riskScore >= 25) return Colors.orange;
    return Colors.green;
  }

  String get translatedStatus {
    switch (paymentStatus) {
      case 'Awaiting payment':
        return t('Awaiting payment', 'ಪಾವತಿಗಾಗಿ ಕಾಯುತ್ತಿದೆ');
      case 'Awaiting merchant verification':
        return t(
          'Awaiting merchant verification',
          'ವ್ಯಾಪಾರಿಯ ಪರಿಶೀಲನೆಗಾಗಿ ಕಾಯುತ್ತಿದೆ',
        );
      case 'Matched':
        return t('Matched', 'ಹೊಂದಿಕೆಯಾಗಿದೆ');
      case 'Mismatch - Needs review':
        return t('Mismatch - Needs review', 'ಹೊಂದಿಕೆಯಾಗಿಲ್ಲ - ಪರಿಶೀಲನೆ ಅಗತ್ಯ');
      default:
        return t('Not started', 'ಪ್ರಾರಂಭವಾಗಿಲ್ಲ');
    }
  }

  String categoryLabel(String category) {
    switch (category) {
      case 'Groceries':
        return t('Groceries', 'ದಿನಸಿ');
      case 'Food':
        return t('Food', 'ಆಹಾರ');
      case 'Transport':
        return t('Transport', 'ಸಾರಿಗೆ');
      case 'Shopping':
        return t('Shopping', 'ಖರೀದಿ');
      case 'Bills':
        return t('Bills', 'ಬಿಲ್‌ಗಳು');
      default:
        return t('Others', 'ಇತರೆ');
    }
  }

  void showMessage(String english, String kannada) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t(english, kannada))));
  }

  double? parseAmount(String text) {
    final value = double.tryParse(text.trim());

    if (value == null || !value.isFinite || value <= 0 || value > 1000000000) {
      return null;
    }

    return value;
  }

  Future<void> createRequest() async {
    if (isSavingRequest) return;

    final value = parseAmount(amountController.text);

    if (value == null) {
      showMessage(
        'Please enter a valid amount',
        'ದಯವಿಟ್ಟು ಸರಿಯಾದ ಮೊತ್ತ ನಮೂದಿಸಿ',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please sign in before creating a request',
        'ವಿನಂತಿ ರಚಿಸುವ ಮೊದಲು ಸೈನ್ ಇನ್ ಮಾಡಿ',
      );
      return;
    }

    setState(() {
      isSavingRequest = true;
    });

    try {
      final savedDoc = await FirebaseFirestore.instance
          .collection('payment_requests')
          .add({
            'merchantId': user.uid,
            'merchantName': 'ABC Grocery Store',
            'amount': value,
            'status': 'Awaiting payment',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      setState(() {
        activeRequestDocId = savedDoc.id;

        amount = value;
        sessionNumber++;
        sessionId = 'TP360-$sessionNumber';
        paymentStatus = 'Awaiting payment';
        receiptMissing = false;
        reviewSubmitted = false;

        timeline
          ..clear()
          ..add('Merchant created a payment request');
      });

      showMessage(
        'Payment request saved to Firebase successfully',
        'ಪಾವತಿ ವಿನಂತಿ ಫೈರ್‌ಬೇಸ್‌ನಲ್ಲಿ ಯಶಸ್ವಿಯಾಗಿ ಉಳಿಸಲಾಗಿದೆ',
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint('Firestore save failed: $error');

      showMessage(
        'Could not save payment request. Please try again.',
        'ಪಾವತಿ ವಿನಂತಿ ಉಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingRequest = false;
        });
      }
    }
  }

  Future<void> saveDemoEvent(String eventType) async {
    final requestId = activeRequestDocId;

    debugPrint('FIREBASE DISPUTE REQUEST ID: $requestId');

    final user = FirebaseAuth.instance.currentUser;

    if (requestId == null || user == null) {
      debugPrint('No active Firebase payment request.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('payment_requests')
          .doc(requestId)
          .collection('demo_events')
          .add({
            'eventType': eventType,
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

      debugPrint('Demo event saved: $eventType');
    } catch (error) {
      debugPrint('Firebase event error: $error');

      if (mounted) {
        showMessage(
          'Could not save demo event to Firebase',
          'ಡೆಮೊ ಘಟನೆಯನ್ನು ಫೈರ್‌ಬೇಸ್‌ನಲ್ಲಿ ಉಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ',
        );
      }
    }
  }

  void simulatePayment() {
    if (paymentStatus != 'Awaiting payment') {
      showMessage('Create a payment request first', 'ಮೊದಲು ಪಾವತಿ ವಿನಂತಿ ರಚಿಸಿ');
      return;
    }
    saveDemoEvent('demo_payment_submitted');
    if (!recipientMatches) {
      showMessage(
        'Recipient mismatch. Check the recipient first.',
        'ಸ್ವೀಕರಿಸುವವರ ಹೆಸರು ಹೊಂದಿಕೆಯಾಗಿಲ್ಲ. ಮೊದಲು ಪರಿಶೀಲಿಸಿ.',
      );
      return;
    }

    setState(() {
      paymentStatus = 'Awaiting merchant verification';
      timeline.add('Customer initiated demo payment');
      timeline.add('Customer-side simulator reported success');
    });

    showMessage('Demo payment submitted', 'ಡೆಮೊ ಪಾವತಿ ಸಲ್ಲಿಸಲಾಗಿದೆ');
  }

  void verifyMerchantReceipt() {
    if (paymentStatus != 'Awaiting merchant verification') {
      return;
    }
    saveDemoEvent(
      receiptMissing ? 'demo_receipt_missing' : 'demo_receipt_matched',
    );

    setState(() {
      timeline.add('Merchant checked demo receipt');

      if (receiptMissing) {
        paymentStatus = 'Mismatch - Needs review';
        timeline.add('No matching demo receipt found');
        timeline.add('Dispute case created');
      } else {
        paymentStatus = 'Matched';
        timeline.add('Merchant demo receipt matched');

        final exists = collectionRecords.any(
          (record) => record['sessionId'] == sessionId,
        );

        if (!exists) {
          collectionRecords.add({'sessionId': sessionId, 'amount': amount});
        }
      }
    });
  }

  void submitForReview() {
    if (paymentStatus != 'Mismatch - Needs review' || reviewSubmitted) {
      return;
    }
    saveDemoEvent('demo_review_submitted');
    setState(() {
      reviewSubmitted = true;
      timeline.add('Submitted to demo human-review queue');
    });

    showMessage(
      'Dispute added to demo review queue',
      'ವಿವಾದವನ್ನು ಡೆಮೊ ಪರಿಶೀಲನಾ ಪಟ್ಟಿಗೆ ಸೇರಿಸಲಾಗಿದೆ',
    );
  }

  void addExpense() {
    final value = parseAmount(expenseController.text);

    if (value == null) {
      showMessage(
        'Enter a valid expense amount',
        'ಸರಿಯಾದ ಖರ್ಚಿನ ಮೊತ್ತ ನಮೂದಿಸಿ',
      );
      return;
    }

    setState(() {
      expenseRecords.add({'category': expenseCategory, 'amount': value});
      expenseController.clear();
    });
  }

  void updateBudget() {
    final value = parseAmount(budgetController.text);

    if (value == null) {
      showMessage('Enter a valid monthly budget', 'ಸರಿಯಾದ ಮಾಸಿಕ ಬಜೆಟ್ ನಮೂದಿಸಿ');
      return;
    }

    setState(() {
      monthlyBudget = value;
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    expenseController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  Widget section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget pageShell(String title, List<Widget> children) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        useKannada = !useKannada;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language,
                          size: 18,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          useKannada ? 'English' : 'ಕನ್ನಡ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget softCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget sectionTitle(String title, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: AppColors.textSoft),
          ),
        ],
      ],
    );
  }

  Widget quickActionTile({
    required IconData icon,
    required String title,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.navy, size: 24),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget metricChip({
    required IconData icon,
    required String value,
    required String label,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.navy),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget activityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(fontWeight: FontWeight.w800, color: amountColor),
          ),
        ],
      ),
    );
  }

  Widget homePage() {
    final score = riskScore;

    return pageShell('TrustPay 360', [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.navySoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220A1330),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                'Payments, with peace of mind.',
                'ನಿಮ್ಮ ಪಾವತಿ, ಸಂಪೂರ್ಣ ಭರವಸೆಯೊಂದಿಗೆ.',
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t(
                'A safer digital payment experience for both senders and merchants.',
                'ಕಳುಹಿಸುವವರು ಮತ್ತು ವ್ಯಾಪಾರಿಗಳಿಬ್ಬರಿಗೂ ಸುರಕ್ಷಿತ ಡಿಜಿಟಲ್ ಪಾವತಿ ಅನುಭವ.',
              ),
              style: const TextStyle(
                color: Color(0xFFD7DEEE),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x3343F5B2), width: 14),
                ),
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0E1839),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t('Demo Risk Score', 'ಡೆಮೊ ಅಪಾಯದ ಅಂಕ'),
                            style: const TextStyle(
                              color: Color(0xFFD7DEEE),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$score/100',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Text(
                              riskLevel,
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mint,
                foregroundColor: AppColors.navy,
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: () {
                setState(() {
                  currentPage = 1;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('Send safely', 'ಸುರಕ್ಷಿತವಾಗಿ ಕಳುಹಿಸಿ'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Icon(Icons.arrow_forward),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lavender,
                foregroundColor: AppColors.navy,
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: () {
                setState(() {
                  currentPage = 2;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('Receive payment', 'ಪಾವತಿ ಸ್ವೀಕರಿಸಿ'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      sectionTitle(
        t('Quick Actions', 'ತ್ವರಿತ ಆಯ್ಕೆಗಳು'),
        t(
          'Keep the same flow, now with a premium UI.',
          'ಅದೇ ಕಾರ್ಯವಿಧಾನ, ಈಗ ಉತ್ತಮ UI ಜೊತೆ.',
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          quickActionTile(
            icon: Icons.send_rounded,
            title: t('Send', 'ಕಳುಹಿಸಿ'),
            bgColor: AppColors.mintSoft,
            onTap: () {
              setState(() {
                currentPage = 1;
              });
            },
          ),
          const SizedBox(width: 12),
          quickActionTile(
            icon: Icons.qr_code_2_rounded,
            title: t('Receive', 'ಸ್ವೀಕರಿಸಿ'),
            bgColor: AppColors.lavender,
            onTap: () {
              setState(() {
                currentPage = 2;
              });
            },
          ),
          const SizedBox(width: 12),
          quickActionTile(
            icon: Icons.verified_user_outlined,
            title: t('Verify', 'ಪರಿಶೀಲಿಸಿ'),
            bgColor: const Color(0xFFE9F2FF),
            onTap: () {
              setState(() {
                currentPage = 3;
              });
            },
          ),
        ],
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          metricChip(
            icon: Icons.check_circle_outline,
            value: collectionRecords.length.toString(),
            label: t('Matched payments', 'ಹೊಂದಿದ ಪಾವತಿಗಳು'),
            bg: AppColors.mintSoft,
          ),
          const SizedBox(width: 12),
          metricChip(
            icon: Icons.warning_amber_rounded,
            value: paymentStatus == 'Mismatch - Needs review' ? '1' : '0',
            label: t('Needs review', 'ಪರಿಶೀಲನೆ ಬೇಕು'),
            bg: const Color(0xFFFFE9E5),
          ),
        ],
      ),
      const SizedBox(height: 22),

      sectionTitle(
        t('Recent Activity', 'ಇತ್ತೀಚಿನ ಚಟುವಟಿಕೆ'),
        t('Current demo payment session', 'ಪ್ರಸ್ತುತ ಡೆಮೊ ಪಾವತಿ ಸೆಷನ್'),
      ),

      const SizedBox(height: 12),

      softCard(
        child: Column(
          children: [
            if (timeline.isEmpty)
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.lavenderDark,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t(
                        'No demo activity yet',
                        'ಇನ್ನೂ ಯಾವುದೇ ಡೆಮೊ ಚಟುವಟಿಕೆ ಇಲ್ಲ',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t(
                        'Your payment activity will appear here.',
                        'ನಿಮ್ಮ ಪಾವತಿ ಚಟುವಟಿಕೆ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSoft),
                    ),
                  ],
                ),
              ),

            for (final event in timeline.reversed.take(5))
              activityRow(
                icon: Icons.history_rounded,
                title: event,
                subtitle: sessionId,
                amount: '',
                amountColor: AppColors.navy,
              ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      Text(
        t(
          'Rule-based safety assessment. Simulated payments only.',
          'ನಿಯಮಾಧಾರಿತ ಸುರಕ್ಷತಾ ಪರಿಶೀಲನೆ. ಡೆಮೊ ಪಾವತಿಗಳು ಮಾತ್ರ.',
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
      ),
    ]);
  }

  Widget riskPanel() {
    return Card(
      color: riskColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('Fraud Risk Score', 'ವಂಚನೆ ಅಪಾಯದ ಅಂಕ'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$riskScore / 100 - $riskLevel',
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            if (firstPayment)
              Text(
                t(
                  '• First-time recipient: verify the name.',
                  '• ಹೊಸ ಸ್ವೀಕರಿಸುವವರು: ಹೆಸರನ್ನು ಪರಿಶೀಲಿಸಿ.',
                ),
              ),
            if (!recipientMatches)
              Text(
                t(
                  '• Recipient name does not match.',
                  '• ಸ್ವೀಕರಿಸುವವರ ಹೆಸರು ಹೊಂದಿಕೆಯಾಗಿಲ್ಲ.',
                ),
              ),
            if (urgentRequest)
              Text(
                t(
                  '• Suspicious urgency detected.',
                  '• ಅನುಮಾನಾಸ್ಪದ ತುರ್ತು ಒತ್ತಡ ಕಂಡುಬಂದಿದೆ.',
                ),
              ),
            if (amount >= 5000)
              Text(t('• Large payment amount.', '• ದೊಡ್ಡ ಮೊತ್ತದ ಪಾವತಿ.')),
            const SizedBox(height: 12),
            Text(
              t(
                'This is a rule-based demo score, not a '
                    'real fraud detection service.',
                'ಇದು ನಿಯಮಾಧಾರಿತ ಡೆಮೊ ಅಂಕ ಮಾತ್ರ, '
                    'ನಿಜವಾದ ವಂಚನೆ ಪತ್ತೆ ಸೇವೆಯಲ್ಲ.',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget sendPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PAGE HEADING
        Text(
          t('Check before you pay.', 'ಪಾವತಿ ಮಾಡುವ ಮೊದಲು ಪರಿಶೀಲಿಸಿ.'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          t(
            'Review payment details and potential risks.',
            'ಪಾವತಿ ವಿವರಗಳು ಮತ್ತು ಸಂಭಾವ್ಯ ಅಪಾಯಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.',
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textSoft),
        ),

        const SizedBox(height: 20),

        // MERCHANT DETAILS CARD
        softCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.lavenderDark,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('ABC Grocery Store', 'ABC ದಿನಸಿ ಅಂಗಡಿ'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('Demo merchant', 'ಡೆಮೊ ವ್ಯಾಪಾರಿ'),
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 30),

              Text(
                t('Payment amount', 'ಪಾವತಿ ಮೊತ್ತ'),
                style: const TextStyle(color: AppColors.textSoft),
              ),

              const SizedBox(height: 6),

              Text(
                money(amount),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                t('Session: $sessionId', 'ಸೆಷನ್: $sessionId'),
                style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // LIVE RISK SCORE - EXISTING LOGIC
        riskPanel(),

        const SizedBox(height: 24),

        sectionTitle(t('Payment safety checks', 'ಪಾವತಿ ಸುರಕ್ಷತಾ ಪರಿಶೀಲನೆ')),

        const SizedBox(height: 12),

        // EXISTING SAFETY CHECKBOXES
        softCard(
          child: Column(
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.navy,
                value: firstPayment,
                title: Text(
                  t('First-time recipient', 'ಮೊದಲ ಬಾರಿಗೆ ಹಣ ಸ್ವೀಕರಿಸುವವರು'),
                ),
                onChanged: (value) {
                  setState(() {
                    firstPayment = value ?? false;
                  });
                },
              ),

              const Divider(),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.navy,
                value: recipientMatches,
                title: Text(
                  t(
                    'Recipient matches merchant',
                    'ಸ್ವೀಕರಿಸುವವರ ಹೆಸರು ವ್ಯಾಪಾರಿಗೆ ಹೊಂದುತ್ತದೆ',
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    recipientMatches = value ?? false;
                  });
                },
              ),

              const Divider(),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.navy,
                value: urgentRequest,
                title: Text(
                  t('Urgent payment pressure', 'ತಕ್ಷಣ ಪಾವತಿಸಲು ಒತ್ತಡ'),
                ),
                onChanged: (value) {
                  setState(() {
                    urgentRequest = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // EXISTING PAYMENT FUNCTION
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 58),
            ),
            onPressed: paymentStatus == 'Awaiting payment'
                ? simulatePayment
                : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              t('Proceed to demo payment', 'ಡೆಮೊ ಪಾವತಿಗೆ ಮುಂದುವರಿಯಿರಿ'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // CURRENT PAYMENT STATUS
        softCard(
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.lavenderDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('Status: $translatedStatus', 'ಸ್ಥಿತಿ: $translatedStatus'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // PAYMENT SAFETY WARNING
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB45309),
                size: 28,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Stay alert', 'ಎಚ್ಚರವಾಗಿರಿ'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t(
                        'Always check the recipient and amount before confirming a payment. This is a demo only.',
                        'ಪಾವತಿಯನ್ನು ದೃಢೀಕರಿಸುವ ಮೊದಲು ಸ್ವೀಕರಿಸುವವರು ಮತ್ತು ಮೊತ್ತವನ್ನು ಪರಿಶೀಲಿಸಿ. ಇದು ಡೆಮೊ ಮಾತ್ರ.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  void openSavedRequest(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final savedAmount = (data['amount'] as num).toDouble();
    final savedStatus = data['status'] as String? ?? 'Awaiting payment';

    setState(() {
      amount = savedAmount;
      amountController.text = savedAmount.toStringAsFixed(2);

      activeRequestDocId = doc.id;

      sessionId = 'TP360-${doc.id.substring(0, 8).toUpperCase()}';
      paymentStatus = savedStatus;

      receiptMissing = false;
      reviewSubmitted = false;

      timeline
        ..clear()
        ..add('Merchant reopened a saved payment request');

      currentPage = 2;
    });

    showMessage(
      'Saved payment request opened successfully',
      'ಉಳಿಸಿದ ಪಾವತಿ ವಿನಂತಿ ಯಶಸ್ವಿಯಾಗಿ ತೆರೆಯಲಾಗಿದೆ',
    );
  }

  Widget savedRequestsPanel() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Text(
        t(
          'Please sign in to view saved requests.',
          'ಉಳಿಸಿದ ವಿನಂತಿಗಳನ್ನು ನೋಡಲು ಸೈನ್ ಇನ್ ಮಾಡಿ.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Saved Payment Requests', 'ಉಳಿಸಿದ ಪಾವತಿ ವಿನಂತಿಗಳು'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('payment_requests')
              .where('merchantId', isEqualTo: user.uid)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                t(
                  'Could not load saved requests.',
                  'ಉಳಿಸಿದ ವಿನಂತಿಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.',
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data!.docs.toList();

            requests.sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;

              return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
                aTime?.millisecondsSinceEpoch ?? 0,
              );
            });

            if (requests.isEmpty) {
              return Text(
                t(
                  'No saved payment requests yet.',
                  'ಇನ್ನೂ ಯಾವುದೇ ಉಳಿಸಿದ ಪಾವತಿ ವಿನಂತಿಗಳಿಲ್ಲ.',
                ),
              );
            }

            return Column(
              children: requests.map((doc) {
                final data = doc.data();
                final amount = (data['amount'] as num).toDouble();
                final status = data['status'] as String? ?? '';

                return Card(
                  child: ListTile(
                    onTap: () => openSavedRequest(doc),

                    leading: const Icon(
                      Icons.receipt_long,
                      color: Colors.indigo,
                    ),
                    title: Text(money(amount)),
                    subtitle: Text(
                      '${data['merchantName'] ?? ''}\n'
                      '${t('Status', 'ಸ್ಥಿತಿ')}: '
                      '${status == 'Awaiting payment' ? t('Awaiting payment', 'ಪಾವತಿಗಾಗಿ ಕಾಯುತ್ತಿದೆ') : status}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget receivePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(
          t('Receive Payment', 'ಪಾವತಿ ಸ್ವೀಕರಿಸಿ'),
          t(
            'Create and verify payment requests.',
            'ಪಾವತಿ ವಿನಂತಿಗಳನ್ನು ರಚಿಸಿ ಮತ್ತು ಪರಿಶೀಲಿಸಿ.',
          ),
        ),

        const SizedBox(height: 18),

        // PREMIUM MERCHANT CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.navySoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220A1330),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x2259F0B5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.mint,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('ABC Grocery Store', 'ABC ದಿನಸಿ ಅಂಗಡಿ'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          t('Demo merchant', 'ಡೆಮೊ ವ್ಯಾಪಾರಿ'),
                          style: const TextStyle(
                            color: AppColors.mint,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                t('Current request amount', 'ಪ್ರಸ್ತುತ ವಿನಂತಿಯ ಮೊತ್ತ'),
                style: const TextStyle(color: Color(0xFFD7DEEE), fontSize: 14),
              ),

              const SizedBox(height: 8),

              Text(
                money(amount),
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 22),

              // EXISTING AMOUNT CONTROLLER
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.navySoft,
                  labelText: t('Enter amount', 'ಮೊತ್ತ ನಮೂದಿಸಿ'),
                  labelStyle: const TextStyle(color: Color(0xFFD7DEEE)),
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(color: AppColors.mint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // EXISTING FIREBASE REQUEST FUNCTION
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size(0, 56),
                  ),
                  onPressed: createRequest,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    t('Create Payment Request', 'ಪಾವತಿ ವಿನಂತಿ ರಚಿಸಿ'),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // CURRENT SESSION DETAILS
        softCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(t('Payment Session', 'ಪಾವತಿ ಸೆಷನ್')),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.lavenderDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t('Session: $sessionId', 'ಸೆಷನ್: $sessionId')),
                  ),
                ],
              ),

              const Divider(height: 26),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  t('Status: $translatedStatus', 'ಸ್ಥಿತಿ: $translatedStatus'),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        sectionTitle(t('Merchant Verification', 'ವ್ಯಾಪಾರಿ ಪರಿಶೀಲನೆ')),

        const SizedBox(height: 12),

        // VERIFICATION CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.lavender,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.lavenderDark,
                    size: 36,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      t('Verify Payment Receipt', 'ಪಾವತಿ ಸ್ವೀಕೃತಿ ಪರಿಶೀಲಿಸಿ'),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // EXISTING DISPUTE SIMULATION SWITCH
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: receiptMissing,
                title: Text(
                  t(
                    'Simulate missing merchant receipt',
                    'ವ್ಯಾಪಾರಿಯ ಸ್ವೀಕೃತಿ ಕಾಣೆಯಾಗಿರುವಂತೆ ತೋರಿಸಿ',
                  ),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  t(
                    'Enable this to demonstrate a dispute.',
                    'ವಿವಾದ ತೋರಿಸಲು ಇದನ್ನು ಆನ್ ಮಾಡಿ.',
                  ),
                  style: const TextStyle(color: AppColors.textSoft),
                ),
                onChanged: (value) {
                  setState(() {
                    receiptMissing = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              // EXISTING MERCHANT VERIFICATION FUNCTION
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 56),
                  ),
                  onPressed: paymentStatus == 'Awaiting merchant verification'
                      ? verifyMerchantReceipt
                      : null,
                  icon: const Icon(Icons.verified),
                  label: Text(
                    t('Verify Demo Receipt', 'ಡೆಮೊ ಸ್ವೀಕೃತಿ ಪರಿಶೀಲಿಸಿ'),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // DEMO SAFETY NOTICE
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFB45309)),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  t(
                    'Verification uses simulated records, not real bank or UPI confirmation.',
                    'ಪರಿಶೀಲನೆ ಡೆಮೊ ದಾಖಲೆಗಳನ್ನು ಬಳಸುತ್ತದೆ, ನಿಜವಾದ ಬ್ಯಾಂಕ್ ಅಥವಾ UPI ದೃಢೀಕರಣವಲ್ಲ.',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // EXISTING FIREBASE SAVED REQUESTS
        softCard(child: savedRequestsPanel()),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget firebaseDisputeTimeline() {
    final requestId = activeRequestDocId;

    if (requestId == null) {
      return Text(
        t(
          'Open a saved payment request to view Firebase history.',
          'ಫೈರ್‌ಬೇಸ್ ಇತಿಹಾಸ ನೋಡಲು ಉಳಿಸಿದ ಪಾವತಿ ವಿನಂತಿ ತೆರೆಯಿರಿ.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Firebase Dispute History', 'ಫೈರ್‌ಬೇಸ್ ವಿವಾದ ಇತಿಹಾಸ'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('payment_requests')
              .doc(requestId)
              .collection('demo_events')
              .orderBy('createdAt')
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                t(
                  'Unable to load Firebase dispute history.',
                  'ಫೈರ್‌ಬೇಸ್ ವಿವಾದ ಇತಿಹಾಸ ಲೋಡ್ ಆಗಲಿಲ್ಲ.',
                ),
              );
            }

            if (snapshot.hasError) {
              debugPrint('FIREBASE DISPUTE ERROR: ${snapshot.error}');

              return Text('Firebase error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final events = snapshot.data!.docs;

            if (events.isEmpty) {
              return Text(
                t(
                  'No saved demo events for this request.',
                  'ಈ ವಿನಂತಿಗೆ ಉಳಿಸಿದ ಡೆಮೊ ಘಟನೆಗಳಿಲ್ಲ.',
                ),
              );
            }

            return Column(
              children: events.map((doc) {
                final data = doc.data();
                final eventType = data['eventType'] as String? ?? '';
                final timestamp = data['createdAt'] as Timestamp?;

                String title;

                switch (eventType) {
                  case 'demo_payment_submitted':
                    title = t(
                      'Demo payment submitted',
                      'ಡೆಮೊ ಪಾವತಿ ಸಲ್ಲಿಸಲಾಗಿದೆ',
                    );
                    break;

                  case 'demo_receipt_matched':
                    title = t(
                      'Demo merchant receipt matched',
                      'ಡೆಮೊ ವ್ಯಾಪಾರಿ ರಸೀದಿ ಹೊಂದಿಕೆಯಾಗಿದೆ',
                    );
                    break;

                  case 'demo_receipt_missing':
                    title = t(
                      'Demo merchant receipt missing',
                      'ಡೆಮೊ ವ್ಯಾಪಾರಿ ರಸೀದಿ ಕಾಣೆಯಾಗಿದೆ',
                    );
                    break;

                  case 'demo_review_submitted':
                    title = t(
                      'Submitted for demo review',
                      'ಡೆಮೊ ಪರಿಶೀಲನೆಗೆ ಸಲ್ಲಿಸಲಾಗಿದೆ',
                    );
                    break;

                  default:
                    title = eventType;
                }

                final timeText = timestamp == null
                    ? t('Time pending', 'ಸಮಯ ಬಾಕಿ ಇದೆ')
                    : timestamp.toDate().toLocal().toString().split('.').first;

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.indigo),
                    title: Text(title),
                    subtitle: Text(timeText),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget disputesPage() {
    final isMatched = paymentStatus == 'Matched';
    final needsReview = paymentStatus == 'Mismatch - Needs review';

    final statusColor = isMatched
        ? AppColors.mint
        : needsReview
        ? const Color(0xFFFF9B9B)
        : AppColors.lavender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(
          t('Dispute Replay', 'ವಿವಾದ ಮರುಪರಿಶೀಲನೆ'),
          t(
            'Track your payment verification journey.',
            'ನಿಮ್ಮ ಪಾವತಿ ಪರಿಶೀಲನೆಯ ಹಂತಗಳನ್ನು ವೀಕ್ಷಿಸಿ.',
          ),
        ),

        const SizedBox(height: 20),

        // PREMIUM PAYMENT SESSION CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.navySoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220A1330),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x2259F0B5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      color: AppColors.mint,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      t('Payment Session', 'ಪಾವತಿ ಸೆಷನ್'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                sessionId,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              const Divider(color: Color(0xFF344466)),

              const SizedBox(height: 12),

              Text(
                t('Verification Status', 'ಪರಿಶೀಲನೆ ಸ್ಥಿತಿ'),
                style: const TextStyle(color: Color(0xFFD7DEEE), fontSize: 13),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF24345A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      isMatched
                          ? Icons.verified_user
                          : needsReview
                          ? Icons.warning_amber_rounded
                          : Icons.pending_outlined,
                      color: statusColor,
                      size: 26,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        translatedStatus,
                        style: TextStyle(
                          fontSize: 16,
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        // EXISTING TRANSACTION TIMELINE
        sectionTitle(
          t('Transaction Timeline', 'ವಹಿವಾಟಿನ ಸಮಯರೇಖೆ'),
          t(
            'Follow each recorded payment event.',
            'ದಾಖಲಾದ ಪ್ರತಿಯೊಂದು ಪಾವತಿ ಘಟನೆಯನ್ನು ವೀಕ್ಷಿಸಿ.',
          ),
        ),

        const SizedBox(height: 14),

        softCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timeline.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t(
                      'No transaction events yet.',
                      'ಇನ್ನೂ ಯಾವುದೇ ವಹಿವಾಟು ಇಲ್ಲ.',
                    ),
                  ),
                ),

              for (int i = 0; i < timeline.length; i++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: AppColors.mintSoft,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),

                            if (i < timeline.length - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: AppColors.mintSoft,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.pageBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              timeline[i],
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // EXISTING FIREBASE HISTORY
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.lavender,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_outlined,
                size: 32,
                color: AppColors.lavenderDark,
              ),

              const SizedBox(height: 12),

              firebaseDisputeTimeline(),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // EXISTING MISMATCH AND REVIEW LOGIC
        if (needsReview) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFB91C1C),
                      size: 32,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        t('Payment Mismatch', 'ಪಾವತಿ ಹೊಂದಾಣಿಕೆ ಸಮಸ್ಯೆ'),
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  t(
                    'A payment mismatch was detected.',
                    'ಪಾವತಿಯಲ್ಲಿ ಹೊಂದಾಣಿಕೆ ಸಮಸ್ಯೆ ಕಂಡುಬಂದಿದೆ.',
                  ),
                  style: const TextStyle(color: Color(0xFF991B1B)),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 56),
                    ),
                    onPressed: reviewSubmitted ? null : submitForReview,
                    icon: const Icon(Icons.support_agent),
                    label: Text(
                      reviewSubmitted
                          ? t('Submitted for Review', 'ಪರಿಶೀಲನೆಗೆ ಸಲ್ಲಿಸಲಾಗಿದೆ')
                          : t(
                              'Submit for Human Review',
                              'ಮಾನವ ಪರಿಶೀಲನೆಗೆ ಸಲ್ಲಿಸಿ',
                            ),
                    ),
                  ),
                ),

                if (reviewSubmitted) ...[
                  const SizedBox(height: 14),

                  Text(
                    t(
                      'Review Status: Pending (Demo)',
                      'ಪರಿಶೀಲನೆ ಸ್ಥಿತಿ: ಬಾಕಿ (ಡೆಮೊ)',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // EXISTING SUCCESS STATUS
        if (isMatched)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF087F45),
                  size: 38,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    t(
                      'Demo payment records matched successfully.',
                      'ಡೆಮೊ ಪಾವತಿ ದಾಖಲೆಗಳು ಯಶಸ್ವಿಯಾಗಿ ಹೊಂದಿವೆ.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF087F45),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget firebaseFinancialOverview() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Text(
        t(
          'Please sign in to view Firebase insights.',
          'ಫೈರ್‌ಬೇಸ್ ಮಾಹಿತಿಯನ್ನು ನೋಡಲು ಸೈನ್ ಇನ್ ಮಾಡಿ.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Firebase Payment Overview', 'ಫೈರ್‌ಬೇಸ್ ಪಾವತಿ ಮಾಹಿತಿ'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('payment_requests')
              .where('merchantId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Financial Insights error: ${snapshot.error}');
              return Text(
                t(
                  'Unable to load Firebase financial insights.',
                  'ಫೈರ್‌ಬೇಸ್ ಹಣಕಾಸು ಮಾಹಿತಿ ಲೋಡ್ ಆಗಲಿಲ್ಲ.',
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data!.docs.toList();

            double totalRequested = 0;

            for (final doc in requests) {
              final value = doc.data()['amount'];

              if (value is num) {
                totalRequested += value.toDouble();
              }
            }

            requests.sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;

              return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
                aTime?.millisecondsSinceEpoch ?? 0,
              );
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.receipt_long,
                      color: Colors.indigo,
                    ),
                    title: Text(
                      t('Total Payment Requests', 'ಒಟ್ಟು ಪಾವತಿ ವಿನಂತಿಗಳು'),
                    ),
                    trailing: Text(
                      '${requests.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                    title: Text(
                      t('Total Amount Requested', 'ವಿನಂತಿಸಿದ ಒಟ್ಟು ಮೊತ್ತ'),
                    ),
                    trailing: Text(
                      money(totalRequested),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  t(
                    'These are demo requests, not confirmed payments.',
                    'ಇವು ಡೆಮೊ ವಿನಂತಿಗಳು, ದೃಢಪಟ್ಟ ಪಾವತಿಗಳಲ್ಲ.',
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  t('Recent Payment Requests', 'ಇತ್ತೀಚಿನ ಪಾವತಿ ವಿನಂತಿಗಳು'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (requests.isEmpty)
                  Text(
                    t('No payment requests yet.', 'ಇನ್ನೂ ಪಾವತಿ ವಿನಂತಿಗಳಿಲ್ಲ.'),
                  ),

                for (final doc in requests.take(5))
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(
                      money((doc.data()['amount'] as num).toDouble()),
                    ),
                    subtitle: Text(
                      t(
                        'Awaiting payment (demo request)',
                        'ಪಾವತಿಗಾಗಿ ಕಾಯುತ್ತಿದೆ (ಡೆಮೊ ವಿನಂತಿ)',
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget insightsPage() {
    const categories = [
      'Groceries',
      'Food',
      'Transport',
      'Shopping',
      'Bills',
      'Others',
    ];

    return section(t('Financial Insights', 'ಹಣಕಾಸು ಮಾಹಿತಿ'), [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.navySoft],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.mint,
              size: 32,
            ),
            const SizedBox(height: 15),
            Text(
              t('Remaining Budget', 'ಉಳಿದ ಬಜೆಟ್'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                money(monthlyBudget - totalExpenses),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t(
                'Monthly Budget: ${money(monthlyBudget)}',
                'ಮಾಸಿಕ ಬಜೆಟ್: ${money(monthlyBudget)}',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              t(
                'Total Expenses: ${money(totalExpenses)}',
                'ಒಟ್ಟು ಖರ್ಚು: ${money(totalExpenses)}',
              ),
              style: const TextStyle(color: AppColors.mint),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: monthlyBudget > 0
                    ? (totalExpenses / monthlyBudget).clamp(0.0, 1.0).toDouble()
                    : 0.0,
                minHeight: 10,
                backgroundColor: const Color(0xFF344466),
                color: AppColors.mint,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      Row(
        children: [
          metricChip(
            icon: Icons.account_balance_wallet_outlined,
            value: money(totalCollections),
            label: t('Demo Collections', 'ಡೆಮೊ ಸ್ವೀಕೃತಿಗಳು'),
            bg: AppColors.mintSoft,
          ),
          const SizedBox(width: 12),
          metricChip(
            icon: Icons.receipt_long_outlined,
            value: money(totalExpenses),
            label: t('Total Expenses', 'ಒಟ್ಟು ಖರ್ಚು'),
            bg: AppColors.lavender,
          ),
        ],
      ),

      const SizedBox(height: 24),
      firebaseFinancialOverview(),
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 20),

      Text(
        t('Personal Budget Tracker', 'ವೈಯಕ್ತಿಕ ಬಜೆಟ್ ಟ್ರ್ಯಾಕರ್'),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: budgetController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: t('Monthly budget (₹)', 'ಮಾಸಿಕ ಬಜೆಟ್ (₹)'),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
        ),
        onPressed: updateBudget,
        child: Text(t('Save Budget', 'ಬಜೆಟ್ ಉಳಿಸಿ')),
      ),

      const SizedBox(height: 25),
      Text(
        t('Add Expense', 'ಖರ್ಚು ಸೇರಿಸಿ'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: expenseController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: t('Expense Amount (₹)', 'ಖರ್ಚಿನ ಮೊತ್ತ (₹)'),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      DropdownButton<String>(
        value: expenseCategory,
        isExpanded: true,
        items: categories.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(categoryLabel(category)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              expenseCategory = value;
            });
          }
        },
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.navy,
          minimumSize: const Size(double.infinity, 56),
        ),
        onPressed: addExpense,
        icon: const Icon(Icons.add),
        label: Text(t('Add Expense', 'ಖರ್ಚು ಸೇರಿಸಿ')),
      ),
      const SizedBox(height: 20),
      Text(
        t('Expense History', 'ಖರ್ಚಿನ ಇತಿಹಾಸ'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      if (expenseRecords.isEmpty)
        Text(t('No expenses recorded yet.', 'ಇನ್ನೂ ಯಾವುದೇ ಖರ್ಚು ದಾಖಲಾಗಿಲ್ಲ.')),
      for (final record in expenseRecords)
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text(categoryLabel(record['category'] as String)),
          trailing: Text(money(record['amount'] as double)),
        ),
      const Divider(height: 35),
      Text(
        t('Merchant Collections', 'ವ್ಯಾಪಾರಿಯ ಸ್ವೀಕೃತಿಗಳು'),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Text(
        t(
          'Verified Demo Collections: ${money(totalCollections)}',
          'ಪರಿಶೀಲಿಸಿದ ಡೆಮೊ ಸ್ವೀಕೃತಿಗಳು: ${money(totalCollections)}',
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      if (collectionRecords.isEmpty)
        Text(
          t('No matched demo payments yet.', 'ಹೊಂದಿಕೆಯಾದ ಡೆಮೊ ಪಾವತಿಗಳಿಲ್ಲ.'),
        ),
      for (final record in collectionRecords)
        ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(record['sessionId'] as String),
          trailing: Text(money(record['amount'] as double)),
        ),
      const Divider(height: 35),
      Text(
        t('Financial Safety Tips', 'ಹಣಕಾಸು ಸುರಕ್ಷತಾ ಸಲಹೆಗಳು'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      ListTile(
        leading: const Icon(Icons.security),
        title: Text(
          t(
            'Never share your UPI PIN or OTP.',
            'ನಿಮ್ಮ UPI ಪಿನ್ ಅಥವಾ OTP ಯಾರಿಗೂ ತಿಳಿಸಬೇಡಿ.',
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.verified_user),
        title: Text(
          t(
            'Always check the recipient before paying.',
            'ಪಾವತಿಗೂ ಮೊದಲು ಸ್ವೀಕರಿಸುವವರನ್ನು ಪರಿಶೀಲಿಸಿ.',
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.warning_amber),
        title: Text(
          t(
            'Do not trust payment screenshots alone.',
            'ಪಾವತಿ ಸ್ಕ್ರೀನ್‌ಶಾಟ್‌ಗಳನ್ನು ಮಾತ್ರ ನಂಬಬೇಡಿ.',
          ),
        ),
      ),
    ]);
  }

  Widget buildPage() {
    switch (currentPage) {
      case 0:
        return homePage();
      case 1:
        return sendPage();
      case 2:
        return receivePage();
      case 3:
        return disputesPage();
      default:
        return insightsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10264D),
        foregroundColor: Colors.white,

        title: const Text(
          'TrustPay 360',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                useKannada = !useKannada;
              });
            },
            icon: const Icon(Icons.language, color: Colors.white, size: 22),
            label: Text(
              useKannada ? 'English' : 'ಕನ್ನಡ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: buildPage(),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (states) => TextStyle(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.mint
                      : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: NavigationBar(
              height: 74,
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0x1F59F0B5),
              selectedIndex: currentPage,
              onDestinationSelected: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.home, color: AppColors.mint),
                  label: t('Home', 'ಮುಖಪುಟ'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.send_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.send, color: AppColors.mint),
                  label: t('Send', 'ಕಳುಹಿಸಿ'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.storefront, color: AppColors.mint),
                  label: t('Receive', 'ಸ್ವೀಕರಿಸಿ'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.history, color: AppColors.mint),
                  label: t('Disputes', 'ವಿವಾದ'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.bar_chart, color: AppColors.mint),
                  label: t('Insights', 'ಮಾಹಿತಿ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
