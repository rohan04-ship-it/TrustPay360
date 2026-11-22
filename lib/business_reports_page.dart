import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessReportsPage extends StatefulWidget {
  const BusinessReportsPage({super.key});

  @override
  State<BusinessReportsPage> createState() => _BusinessReportsPageState();
}

class _BusinessReportsPageState extends State<BusinessReportsPage> {
  static const navy = Color(0xFF0A1330);
  static const mint = Color(0xFF59F0B5);

  DateTime selectedMonth = DateTime.now();

  late final String uid;
  late Future<Map<String, dynamic>> reportFuture;

  String money(num value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  String monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  bool validUser() {
    final user = FirebaseAuth.instance.currentUser;

    return user != null && !user.isAnonymous && user.uid == uid;
  }

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    reportFuture = loadReport();
  }

  Future<Map<String, dynamic>> loadReport() async {
    if (!validUser()) {
      throw StateError('Please sign in again');
    }

    final month = monthKey(selectedMonth);
    final db = FirebaseFirestore.instance;

    final payments = await db
        .collection('shared_payment_requests')
        .where('merchantId', isEqualTo: uid)
        .get(const GetOptions(source: Source.server));

    final expenses = await db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('month', isEqualTo: month)
        .get(const GetOptions(source: Source.server));

    double collections = 0;
    double requested = 0;
    double totalExpenses = 0;

    int totalRequests = 0;
    int matched = 0;
    int pending = 0;
    int disputed = 0;

    final categories = <String, double>{};

    for (final doc in payments.docs) {
      final data = doc.data();

      final created = data['createdAt'] as Timestamp?;
      final updated = data['updatedAt'] as Timestamp?;

      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

      final status = data['status']?.toString() ?? '';

      // Count requests created in the selected month.
      if (created != null && monthKey(created.toDate()) == month) {
        totalRequests++;
        requested += amount;

        if (status == 'Matched') {
          matched++;
        } else if (status == 'Mismatch - Needs review') {
          disputed++;
        } else {
          pending++;
        }
      }

      // Count collections in the month they were matched.
      if (status == 'Matched' &&
          updated != null &&
          monthKey(updated.toDate()) == month) {
        collections += amount;
      }
    }

    for (final doc in expenses.docs) {
      final data = doc.data();

      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

      final category = data['category']?.toString() ?? 'Others';

      totalExpenses += amount;

      categories[category] = (categories[category] ?? 0) + amount;
    }

    return {
      'month': month,
      'collections': collections,
      'requested': requested,
      'expenses': totalExpenses,
      'net': collections - totalExpenses,
      'requests': totalRequests,
      'matched': matched,
      'pending': pending,
      'disputed': disputed,
      'categories': categories,
    };
  }

  void changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + offset,
      );

      reportFuture = loadReport();
    });
  }

  void refreshReport() {
    setState(() {
      reportFuture = loadReport();
    });
  }

  Widget metric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: navy, size: 28),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: navy, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget reportBar(
    String label,
    double value,
    double maximum,
    Color color,
    String displayValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                displayValue,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: maximum > 0
                  ? (value / maximum).clamp(0.0, 1.0).toDouble()
                  : 0.0,
              minHeight: 12,
              backgroundColor: const Color(0xFFE5E7EB),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget panel(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<void> copyReport(Map<String, dynamic> data) async {
    if (!validUser()) return;

    final report =
        '''
TRUSTPAY 360 - MONTHLY REPORT

Month: ${data['month']}

Total Requests: ${data['requests']}
Total Requested: ${money(data['requested'] as num)}
Matched Requests: ${data['matched']}
Pending Requests: ${data['pending']}
Disputed Requests: ${data['disputed']}

Demo Collections: ${money(data['collections'] as num)}
Recorded Expenses: ${money(data['expenses'] as num)}
Demo Net Balance: ${money(data['net'] as num)}

Payment statistics refer to requests created in the month.
Collections refer to requests matched during the month.
Simulated payments only.
Not an official bank or accounting statement.
''';

    await Clipboard.setData(ClipboardData(text: report));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Monthly report copied')));
  }

  Future<void> generatePdf(Map<String, dynamic> data) async {
    if (!validUser()) return;

    try {
      final pdf = pw.Document();

      String currency(num amount) {
        return 'INR ${amount.toStringAsFixed(2)}';
      }

      final categories = data['categories'] as Map<String, double>;

      pw.Widget reportRow(String label, String value) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(label)),
              pw.SizedBox(width: 12),
              pw.Text(
                value,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        );
      }

      pw.Widget heading(String text) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20, bottom: 12),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),

          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.Text(
                'TrustPay 360 | Simulated payment records',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),

          build: (context) => [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue900,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TRUSTPAY 360',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'One Payment. Two-Sided Protection.',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            heading('Monthly Financial Report'),

            pw.Text('Reporting month: ${data['month']}'),

            heading('Financial Summary'),

            reportRow(
              'Verified Demo Collections',
              currency(data['collections'] as num),
            ),

            reportRow(
              'Total Requested Amount',
              currency(data['requested'] as num),
            ),

            reportRow('Recorded Expenses', currency(data['expenses'] as num)),

            reportRow('Demo Net Balance', currency(data['net'] as num)),

            heading('Payment Statistics'),

            reportRow('Total Requests', '${data['requests']}'),

            reportRow('Matched Requests', '${data['matched']}'),

            reportRow('Pending Requests', '${data['pending']}'),

            reportRow('Disputed Requests', '${data['disputed']}'),

            heading('Expense Breakdown'),

            if (categories.isEmpty) pw.Text('No expenses recorded this month.'),

            for (final entry in categories.entries)
              reportRow(entry.key, currency(entry.value)),

            pw.SizedBox(height: 24),

            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              color: PdfColors.grey200,
              child: pw.Text(
                'DISCLAIMER: This report contains simulated '
                'payment records and user-recorded expenses. '
                'Request statistics are grouped by creation '
                'month. Collections are grouped by receipt '
                'matching month. This is not an official '
                'bank statement or accounting report.',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();

      if (!mounted || !validUser()) return;

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'TrustPay360_Report_${data['month']}.pdf',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to generate PDF: $error')));
    }
  }

  Widget reportBody(Map<String, dynamic> data) {
    final collections = data['collections'] as double;
    final expenses = data['expenses'] as double;
    final net = data['net'] as double;

    final requests = data['requests'] as int;
    final matched = data['matched'] as int;
    final pending = data['pending'] as int;
    final disputed = data['disputed'] as int;

    final categories = data['categories'] as Map<String, double>;

    final maximum = collections > expenses ? collections : expenses;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Row(
            children: [
              IconButton(
                onPressed: () => changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  monthKey(selectedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: monthKey(selectedMonth) == monthKey(DateTime.now())
                    ? null
                    : () => changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF795317), navy]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.business_center_outlined, color: mint, size: 38),
              const SizedBox(height: 18),
              const Text(
                'Monthly Demo Collections',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  money(collections),
                  style: const TextStyle(
                    fontSize: 36,
                    color: mint,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              Text(
                'Recorded expenses: ${money(expenses)}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Demo net balance: ${money(net)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: net >= 0 ? mint : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Simulation data. Not actual business revenue.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            metric(
              'Total Requests',
              '$requests',
              Icons.receipt_long,
              const Color(0xFFE9F2FF),
            ),
            const SizedBox(width: 12),
            metric(
              'Matched Requests',
              '$matched',
              Icons.verified,
              const Color(0xFFDDFBF0),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            metric(
              'Pending Requests',
              '$pending',
              Icons.schedule,
              const Color(0xFFFFF3D9),
            ),
            const SizedBox(width: 12),
            metric(
              'Disputed Requests',
              '$disputed',
              Icons.warning_amber,
              const Color(0xFFFEE2E2),
            ),
          ],
        ),

        const SizedBox(height: 12),

        const Text(
          'Request counts are grouped by creation month '
          'and show their current status.',
        ),

        const SizedBox(height: 24),

        panel('Collections vs Expenses', [
          reportBar(
            'Demo Collections',
            collections,
            maximum,
            Colors.green,
            money(collections),
          ),
          reportBar(
            'Recorded Expenses',
            expenses,
            maximum,
            Colors.orange,
            money(expenses),
          ),
        ]),

        const SizedBox(height: 20),

        panel('Payment Status', [
          reportBar(
            'Matched',
            matched.toDouble(),
            requests.toDouble(),
            Colors.green,
            '$matched',
          ),
          reportBar(
            'Pending',
            pending.toDouble(),
            requests.toDouble(),
            Colors.orange,
            '$pending',
          ),
          reportBar(
            'Disputed',
            disputed.toDouble(),
            requests.toDouble(),
            Colors.red,
            '$disputed',
          ),
        ]),

        const SizedBox(height: 20),

        panel('Expense Breakdown', [
          if (categories.isEmpty) const Text('No expenses recorded this month'),

          for (final entry in categories.entries)
            reportBar(
              entry.key,
              entry.value,
              expenses,
              Colors.indigo,
              money(entry.value),
            ),
        ]),

        const SizedBox(height: 24),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: mint,
            foregroundColor: navy,
            minimumSize: const Size(0, 56),
          ),
          onPressed: () => copyReport(data),
          icon: const Icon(Icons.copy),
          label: const Text('Copy Monthly Report'),
        ),

        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 56),
          ),
          onPressed: () => generatePdf(data),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Download PDF Report'),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Business Analytics'),
        actions: [
          IconButton(
            onPressed: refreshReport,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh report',
          ),
        ],
      ),
      body: !validUser()
          ? const Center(child: Text('Please sign in again'))
          : FutureBuilder<Map<String, dynamic>>(
              future: reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load financial report'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: refreshReport,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No report available'));
                }

                return reportBody(snapshot.data!);
              },
            ),
    );
  }
}
