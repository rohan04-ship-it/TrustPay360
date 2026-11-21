import 'package:material_ui/material_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

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

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10264D),
          primary: const Color(0xFF10264D),
          secondary: const Color(0xFF00B8A9),
          surface: Colors.white,
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F8FC),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF10264D),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10264D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget homePage() {
    return section(t('Welcome to TrustPay 360', 'TrustPay 360 ಗೆ ಸ್ವಾಗತ'), [
      Card(
        color: const Color(0xFF10264D),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFF00B8A9),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'TrustPay 360',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'One Payment. Two-Sided Protection.',
                  'ಒಂದು ಪಾವತಿ. ಎರಡೂ ಬದಿಗೂ ರಕ್ಷಣೆ.',
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                t(
                  'Fraud awareness, demo payment verification and dispute tracking.',
                  'ವಂಚನೆ ಜಾಗೃತಿ, ಡೆಮೊ ಪಾವತಿ ಪರಿಶೀಲನೆ ಮತ್ತು ವಿವಾದ ಟ್ರ್ಯಾಕಿಂಗ್.',
                ),
                style: const TextStyle(color: Color(0xFFDDE8F3)),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 24),

      Text(
        t('Quick Actions', 'ತ್ವರಿತ ಆಯ್ಕೆಗಳು'),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF10264D),
        ),
      ),

      const SizedBox(height: 14),

      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () {
              setState(() {
                currentPage = 1;
              });
            },
            icon: const Icon(Icons.send),
            label: Text(t('Send Money', 'ಹಣ ಕಳುಹಿಸಿ')),
          ),

          FilledButton.icon(
            onPressed: () {
              setState(() {
                currentPage = 2;
              });
            },
            icon: const Icon(Icons.store),
            label: Text(t('Receive Money', 'ಹಣ ಸ್ವೀಕರಿಸಿ')),
          ),

          FilledButton.icon(
            onPressed: () {
              setState(() {
                currentPage = 3;
              });
            },
            icon: const Icon(Icons.history),
            label: Text(t('Disputes', 'ವಿವಾದಗಳು')),
          ),

          FilledButton.icon(
            onPressed: () {
              setState(() {
                currentPage = 4;
              });
            },
            icon: const Icon(Icons.bar_chart),
            label: Text(t('Insights', 'ವಿಶ್ಲೇಷಣೆ')),
          ),
        ],
      ),

      const SizedBox(height: 24),

      Text(
        t(
          'One Payment. Two-Sided Protection.',
          'ಒಂದು ಪಾವತಿ. ಎರಡೂ ಬದಿಗೂ ರಕ್ಷಣೆ.',
        ),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Text(
        t(
          'TrustPay 360 helps customers and merchants '
              'check payment risks, verify demo transaction '
              'records, and manage payment disputes.',
          'TrustPay 360 ಗ್ರಾಹಕರು ಮತ್ತು ವ್ಯಾಪಾರಿಗಳಿಗೆ '
              'ಪಾವತಿಯ ಅಪಾಯ ಪರಿಶೀಲನೆ, ಡೆಮೊ ವಹಿವಾಟು '
              'ಪರಿಶೀಲನೆ ಮತ್ತು ವಿವಾದ ನಿರ್ವಹಣೆಗೆ ಸಹಾಯ ಮಾಡುತ್ತದೆ.',
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () {
          setState(() {
            currentPage = 2;
          });
        },
        icon: const Icon(Icons.add_circle),
        label: Text(t('Create Payment Request', 'ಪಾವತಿ ವಿನಂತಿ ರಚಿಸಿ')),
      ),
      const SizedBox(height: 16),
      Text(t('Current Session: $sessionId', 'ಪ್ರಸ್ತುತ ಸೆಷನ್: $sessionId')),
      Text(t('Status: $translatedStatus', 'ಸ್ಥಿತಿ: $translatedStatus')),
      const SizedBox(height: 14),
      Text(
        t(
          'Demo only. No real money is transferred.',
          'ಇದು ಡೆಮೊ ಮಾತ್ರ. ನಿಜವಾದ ಹಣ ವರ್ಗಾವಣೆ ಆಗುವುದಿಲ್ಲ.',
        ),
        style: const TextStyle(fontWeight: FontWeight.bold),
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
    return section(t('Send Money Safely', 'ಸುರಕ್ಷಿತವಾಗಿ ಹಣ ಕಳುಹಿಸಿ'), [
      Text(t('Session: $sessionId', 'ಸೆಷನ್: $sessionId')),
      Text(t('Amount: ${money(amount)}', 'ಮೊತ್ತ: ${money(amount)}')),
      const SizedBox(height: 10),
      CheckboxListTile(
        value: firstPayment,
        title: Text(t('First-time recipient', 'ಮೊದಲ ಬಾರಿಗೆ ಹಣ ಸ್ವೀಕರಿಸುವವರು')),
        onChanged: (value) {
          setState(() {
            firstPayment = value ?? false;
          });
        },
      ),
      CheckboxListTile(
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
      CheckboxListTile(
        value: urgentRequest,
        title: Text(t('Urgent payment pressure', 'ತಕ್ಷಣ ಪಾವತಿಸಲು ಒತ್ತಡ')),
        onChanged: (value) {
          setState(() {
            urgentRequest = value ?? false;
          });
        },
      ),
      const SizedBox(height: 12),
      riskPanel(),
      const SizedBox(height: 15),
      FilledButton.icon(
        onPressed: paymentStatus == 'Awaiting payment' ? simulatePayment : null,
        icon: const Icon(Icons.send),
        label: Text(t('Simulate Payment', 'ಡೆಮೊ ಪಾವತಿ ಮಾಡಿ')),
      ),
      const SizedBox(height: 12),
      Text(t('Status: $translatedStatus', 'ಸ್ಥಿತಿ: $translatedStatus')),
    ]);
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
    return section(t('Receive Money', 'ಹಣ ಸ್ವೀಕರಿಸಿ'), [
      Text(t('Merchant: ABC Grocery Store', 'ವ್ಯಾಪಾರಿ: ABC ದಿನಸಿ ಅಂಗಡಿ')),
      const SizedBox(height: 15),
      TextField(
        controller: amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: t('Enter amount (₹)', 'ಮೊತ್ತ ನಮೂದಿಸಿ (₹)'),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 15),
      FilledButton.icon(
        onPressed: createRequest,
        icon: const Icon(Icons.add),
        label: Text(t('Create Payment Request', 'ಪಾವತಿ ವಿನಂತಿ ರಚಿಸಿ')),
      ),
      const SizedBox(height: 15),
      Text(t('Session: $sessionId', 'ಸೆಷನ್: $sessionId')),
      Text(t('Status: $translatedStatus', 'ಸ್ಥಿತಿ: $translatedStatus')),
      const SizedBox(height: 15),
      SwitchListTile(
        value: receiptMissing,
        title: Text(
          t(
            'Simulate missing merchant receipt',
            'ವ್ಯಾಪಾರಿಯ ಸ್ವೀಕೃತಿ ಕಾಣೆಯಾಗಿರುವಂತೆ ತೋರಿಸಿ',
          ),
        ),
        subtitle: Text(
          t(
            'Enable this to demonstrate a dispute.',
            'ವಿವಾದ ತೋರಿಸಲು ಇದನ್ನು ಆನ್ ಮಾಡಿ.',
          ),
        ),
        onChanged: (value) {
          setState(() {
            receiptMissing = value;
          });
        },
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: paymentStatus == 'Awaiting merchant verification'
            ? verifyMerchantReceipt
            : null,
        icon: const Icon(Icons.verified),
        label: Text(t('Verify Demo Receipt', 'ಡೆಮೊ ಸ್ವೀಕೃತಿ ಪರಿಶೀಲಿಸಿ')),
      ),
      const SizedBox(height: 12),
      Text(
        t(
          'Verification uses simulated records, not '
              'real bank or UPI confirmation.',
          'ಪರಿಶೀಲನೆ ಡೆಮೊ ದಾಖಲೆಗಳನ್ನು ಬಳಸುತ್ತದೆ, '
              'ನಿಜವಾದ ಬ್ಯಾಂಕ್ ಅಥವಾ UPI ದೃಢೀಕರಣವಲ್ಲ.',
        ),
      ),

      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 16),
      savedRequestsPanel(),
    ]);
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
    return section(t('Dispute Replay & Review', 'ವಿವಾದ ಮರುಪರಿಶೀಲನೆ'), [
      Text(
        t('Payment Session: $sessionId', 'ಪಾವತಿ ಸೆಷನ್: $sessionId'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Text(
        t(
          'Payment Status: $translatedStatus',
          'ಪಾವತಿ ಸ್ಥಿತಿ: $translatedStatus',
        ),
      ),
      const SizedBox(height: 20),
      Text(
        t('Transaction Timeline', 'ವಹಿವಾಟಿನ ಸಮಯರೇಖೆ'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      if (timeline.isEmpty)
        Text(t('No transaction events yet.', 'ಇನ್ನೂ ಯಾವುದೇ ವಹಿವಾಟು ಇಲ್ಲ.')),
      for (int i = 0; i < timeline.length; i++)
        ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text(timeline[i]),
        ),

      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 16),
      firebaseDisputeTimeline(),

      const SizedBox(height: 15),
      if (paymentStatus == 'Mismatch - Needs review') ...[
        Text(
          t(
            'A payment mismatch was detected.',
            'ಪಾವತಿಯಲ್ಲಿ ಹೊಂದಾಣಿಕೆ ಸಮಸ್ಯೆ ಕಂಡುಬಂದಿದೆ.',
          ),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: reviewSubmitted ? null : submitForReview,
          icon: const Icon(Icons.support_agent),
          label: Text(
            reviewSubmitted
                ? t('Submitted for Review', 'ಪರಿಶೀಲನೆಗೆ ಸಲ್ಲಿಸಲಾಗಿದೆ')
                : t('Submit for Human Review', 'ಮಾನವ ಪರಿಶೀಲನೆಗೆ ಸಲ್ಲಿಸಿ'),
          ),
        ),
        if (reviewSubmitted)
          Text(
            t('Review Status: Pending (Demo)', 'ಪರಿಶೀಲನೆ ಸ್ಥಿತಿ: ಬಾಕಿ (ಡೆಮೊ)'),
          ),
      ],
      if (paymentStatus == 'Matched')
        Text(
          t(
            'Demo payment records matched successfully.',
            'ಡೆಮೊ ಪಾವತಿ ದಾಖಲೆಗಳು ಯಶಸ್ವಿಯಾಗಿ ಹೊಂದಿವೆ.',
          ),
          style: const TextStyle(color: Colors.green),
        ),
    ]);
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
        onPressed: updateBudget,
        child: Text(t('Save Budget', 'ಬಜೆಟ್ ಉಳಿಸಿ')),
      ),
      const SizedBox(height: 20),
      Text(
        t(
          'Monthly Budget: ${money(monthlyBudget)}',
          'ಮಾಸಿಕ ಬಜೆಟ್: ${money(monthlyBudget)}',
        ),
      ),
      Text(
        t(
          'Total Expenses: ${money(totalExpenses)}',
          'ಒಟ್ಟು ಖರ್ಚು: ${money(totalExpenses)}',
        ),
      ),
      Text(
        t(
          'Budget Left: ${money(monthlyBudget - totalExpenses)}',
          'ಉಳಿದ ಬಜೆಟ್: ${money(monthlyBudget - totalExpenses)}',
        ),
      ),
      const SizedBox(height: 12),
      LinearProgressIndicator(
        value: (totalExpenses / monthlyBudget).clamp(0.0, 1.0).toDouble(),
        minHeight: 10,
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPage,
        onDestinationSelected: (index) {
          setState(() {
            currentPage = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home),
            label: t('Home', 'ಮುಖಪುಟ'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.send),
            label: t('Send', 'ಕಳುಹಿಸಿ'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.store),
            label: t('Receive', 'ಸ್ವೀಕರಿಸಿ'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: t('Disputes', 'ವಿವಾದಗಳು'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart),
            label: t('Insights', 'ವಿಶ್ಲೇಷಣೆ'),
          ),
        ],
      ),
    );
  }
}
