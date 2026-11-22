import 'qr_scanner_page.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedPaymentPage extends StatefulWidget {
  final String role;

  const SharedPaymentPage({super.key, required this.role});

  @override
  State<SharedPaymentPage> createState() => _SharedPaymentPageState();
}

class _SharedPaymentPageState extends State<SharedPaymentPage> {
  final customerController = TextEditingController();
  final amountController = TextEditingController();

  static const navy = Color(0xFF0A1330);
  static const mint = Color(0xFF59F0B5);

  bool loading = false;

  late final String uid;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> requestsStream;

  bool get isMerchant =>
      widget.role == 'Merchant' || widget.role == 'Business Owner';

  CollectionReference<Map<String, dynamic>> get requests =>
      FirebaseFirestore.instance.collection('shared_payment_requests');

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    requestsStream = requests
        .where(isMerchant ? 'merchantId' : 'customerId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true);
  }

  void notify(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool validUser() {
    final user = FirebaseAuth.instance.currentUser;

    return user != null && !user.isAnonymous && user.uid == uid;
  }

  Future<void> checkServer() async {
    try {
      final result = await requests
          .where(isMerchant ? 'merchantId' : 'customerId', isEqualTo: uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));

      debugPrint(
        'SYNC PROJECT: ${FirebaseFirestore.instance.app.options.projectId}',
      );

      debugPrint('SYNC ROLE: ${widget.role}');
      debugPrint('SYNC ACCOUNT MATCH: ${validUser()}');
      debugPrint('SERVER REQUEST COUNT: ${result.docs.length}');

      notify('Server found ${result.docs.length} payment requests');
    } catch (error) {
      debugPrint('SYNC ERROR: $error');
      notify('Server check failed: $error');
    }
  }

  Future<void> scanCustomerQr() async {
    if (!validUser() || !isMerchant) return;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );
    if (!mounted || result == null || !validUser()) return;
    if (result == uid) {
      notify('Use another customer account');
      return;
    }
    customerController.text = result;
    notify('Customer ID scanned successfully');
  }

  Future<void> copyId() async {
    await Clipboard.setData(ClipboardData(text: uid));

    notify('Customer ID copied');
  }

  Future<void> createSharedRequest() async {
    if (loading || !isMerchant || !validUser()) return;

    final customerId = customerController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (customerId.isEmpty || customerId.length > 128) {
      notify('Enter a valid customer ID');
      return;
    }

    if (customerId == uid) {
      notify('Use another customer account');
      return;
    }

    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > 1000000000) {
      notify('Enter a valid amount');
      return;
    }

    setState(() => loading = true);

    try {
      await requests.add({
        'merchantId': uid,
        'customerId': customerId,
        'amount': amount,
        'status': 'Awaiting payment',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      customerController.clear();
      amountController.clear();

      notify('Payment request created successfully');
    } catch (error) {
      notify('Request failed: $error');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> changeStatus(String requestId, String status) async {
    if (loading || !validUser()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm demo action'),
        content: Text(
          'Update request status to "$status"? '
          'No actual money will be transferred.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || loading || !validUser()) {
      return;
    }

    setState(() => loading = true);

    try {
      await requests.doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notify('Payment status updated');
    } catch (error) {
      notify('Update failed: $error');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Matched':
        return Colors.green;
      case 'Mismatch - Needs review':
        return Colors.red;
      case 'Awaiting merchant verification':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Widget requestCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final amount = (data['amount'] as num?)?.toDouble() ?? 0;

    final status = data['status']?.toString() ?? 'Unknown';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulated Payment Request',
              style: TextStyle(fontWeight: FontWeight.bold, color: navy),
            ),

            const SizedBox(height: 12),

            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),

            const SizedBox(height: 8),

            Text('Request ID: ${doc.id}', style: const TextStyle(fontSize: 12)),

            const SizedBox(height: 10),

            Text(
              isMerchant
                  ? 'Customer: ${data['customerId']}'
                  : 'Merchant: ${data['merchantId']}',
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: statusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (doc.metadata.hasPendingWrites)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Waiting for server confirmation'),
              ),

            if (!isMerchant && status == 'Awaiting payment') ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: mint,
                    foregroundColor: navy,
                  ),
                  onPressed: loading
                      ? null
                      : () => changeStatus(
                          doc.id,
                          'Awaiting merchant verification',
                        ),
                  child: const Text('Simulate Payment'),
                ),
              ),
            ],

            if (isMerchant && status == 'Awaiting merchant verification') ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: loading
                      ? null
                      : () => changeStatus(doc.id, 'Matched'),
                  icon: const Icon(Icons.verified),
                  label: const Text('Match Demo Receipt'),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () => changeStatus(doc.id, 'Mismatch - Needs review'),
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('Report Missing Receipt'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    customerController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!validUser()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Payments')),
        body: const Center(child: Text('Please sign in again')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Live Payments'),
        actions: [
          IconButton(
            onPressed: checkServer,
            icon: const Icon(Icons.refresh),
            tooltip: 'Check server',
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sync, color: mint, size: 36),

                    const SizedBox(height: 14),

                    Text(
                      isMerchant
                          ? 'Merchant Live Payments'
                          : 'Customer Live Payments',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Real-time synchronization. '
                      'Simulated payments only.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (!isMerchant)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Customer ID',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        SelectableText(uid),
                        Center(
                          child: QrImageView(
                            data: 'TRUSTPAY360:$uid',
                            version: QrVersions.auto,
                            size: 210,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        const SizedBox(height: 12),

                        FilledButton.icon(
                          onPressed: copyId,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Customer ID'),
                        ),

                        const SizedBox(height: 8),

                        const Text('Share this ID with your trusted merchant.'),
                      ],
                    ),
                  ),
                ),

              if (isMerchant)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Payment Request',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: loading ? null : scanCustomerQr,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan Customer QR'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: customerController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Customer ID',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: amountController,
                          enabled: !loading,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: navy,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: loading ? null : createSharedRequest,
                            icon: const Icon(Icons.send),
                            label: const Text('Send Request'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                ),

              const SizedBox(height: 24),

              Text(
                isMerchant
                    ? 'Sent Payment Requests'
                    : 'Incoming Payment Requests',
                style: const TextStyle(
                  color: navy,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: requestsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Unable to load requests: '
                      '${snapshot.error}',
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.toList();

                  docs.sort((a, b) {
                    final first = a.data()['createdAt'] as Timestamp?;
                    final second = b.data()['createdAt'] as Timestamp?;

                    return (second?.millisecondsSinceEpoch ?? 0).compareTo(
                      first?.millisecondsSinceEpoch ?? 0,
                    );
                  });

                  if (docs.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No payment requests yet'),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      if (snapshot.data!.metadata.isFromCache)
                        const Text('Showing cached data'),
                      ...docs.map(requestCard),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
