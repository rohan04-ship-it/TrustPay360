
import 'package:flutter/material.dart';

void main() {
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
          seedColor: Colors.indigo,
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
  int sessionNumber = 1000;
  String sessionId = 'No payment request';
  String paymentStatus = 'Not started';

  bool firstPayment = true;
  bool receiptMissing = false;

bool reviewSubmitted = false;

  double amount = 500;

  final amountController =
      TextEditingController(text: '500');

final expenseController = TextEditingController();
final budgetController =
    TextEditingController(text: '5000');

double monthlyBudget = 5000;
String expenseCategory = 'Groceries';

final List<Map<String, dynamic>> expenseRecords = [];
final List<Map<String, dynamic>> collectionRecords = [];

double get totalExpenses {
  return expenseRecords.fold<double>(
    0.0,
    (sum, item) => sum + (item['amount'] as double),
  );
}

double get totalCollections {
  return collectionRecords.fold<double>(
    0.0,
    (sum, item) => sum + (item['amount'] as double),
  );
}


  final List<String> timeline = [];

  
@override
void dispose() {
  amountController.dispose();
  expenseController.dispose();
  budgetController.dispose();
  super.dispose();
}


  void createRequest() {reviewSubmitted = false;
    final value =
        double.tryParse(amountController.text.trim());

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
        ),
      );
      return;
    }

    setState(() {
      amount = value;
      sessionNumber++;
      sessionId = 'TP360-$sessionNumber';
      paymentStatus = 'Awaiting payment';
      timeline
        ..clear()
        ..add('Merchant created a payment request');
    });
  }

  
void simulatePayment() {
  if (sessionNumber == 1000 ||
      paymentStatus != 'Awaiting payment') {
    return;
  }

  setState(() {
    timeline.add('Customer initiated demo payment');
    timeline.add('Customer-side demo reports success');

    paymentStatus = 'Awaiting merchant verification';
  });
}

void verifyMerchantReceipt() {
  if (paymentStatus != 'Awaiting merchant verification') {
    return;
  }

  setState(() {
    timeline.add('Merchant checked the demo receipt');

    if (receiptMissing) {
      paymentStatus = 'Mismatch - Needs review';
      timeline.add(
        'No matching merchant receipt in demo ledger',
      );
      timeline.add('Dispute case created for review');
    
} else {
  paymentStatus = 'Matched';

  timeline.add(
    'Merchant receipt matched in demo ledger',
  );

  if (!collectionRecords.any(
    (record) => record['sessionId'] == sessionId,
  )) {
    collectionRecords.add({
      'sessionId': sessionId,
      'amount': amount,
    });
  }
}

  });
}


void submitForReview() {
  if (!paymentStatus.contains('Mismatch') ||
      reviewSubmitted) {
    return;
  }

  setState(() {
    reviewSubmitted = true;

    timeline.add(
      'Dispute submitted to demo human-review queue',
    );
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Dispute submitted for demo review',
      ),
    ),
  );
}

void addExpense() {
  final value = double.tryParse(
    expenseController.text.trim(),
  );

  if (value == null || !value.isFinite || value <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter a valid expense amount'),
      ),
    );
    return;
  }

  setState(() {
    expenseRecords.add({
      'category': expenseCategory,
      'amount': value,
    });

    expenseController.clear();
  });
}

void updateBudget() {
  final value = double.tryParse(
    budgetController.text.trim(),
  );

  if (value == null || !value.isFinite || value <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter a valid monthly budget'),
      ),
    );
    return;
  }

  setState(() {
    monthlyBudget = value;
  });
}


  Widget section(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }

  Widget buildPage() {
    switch (currentPage) {
      case 0:
        return section(
          'Welcome to TrustPay 360',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'One Payment. Two-Sided Protection.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                'Our app protects customers and '
                'shopkeepers through payment-risk checks, '
                'transaction matching, and dispute review.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() => currentPage = 2);
                },
                icon: const Icon(Icons.store),
                label: const Text('Create Payment Request'),
              ),
            ],
          ),
        );

      case 1:
        return section(
          'Send Money Safely',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Session: $sessionId'),
              Text('Amount: ₹${amount.toStringAsFixed(0)}'),
              CheckboxListTile(
                value: firstPayment,
                title: const Text('First-time recipient'),
                onChanged: (value) {
                  setState(() {
                    firstPayment = value ?? false;
                  });
                },
              ),
              Text(
                firstPayment
                    ? 'Safety tip: Verify the merchant name '
                      'before your first payment.'
                    : 'Check the recipient and amount.',
              ),
              const SizedBox(height: 15),
              SwitchListTile(
                value: receiptMissing,
                title: const Text(
                  'Simulate missing merchant receipt',
                ),
                onChanged: (value) {
                  setState(() {
                    receiptMissing = value;
                  });
                },
              ),
              FilledButton(
                onPressed: simulatePayment,
                child: const Text('Simulate Payment'),
              ),
              const SizedBox(height: 12),
              Text('Status: $paymentStatus'),

const SizedBox(height: 20),

SwitchListTile(
  title: const Text('Simulate missing receipt'),
  subtitle: const Text(
    'Turn on to demonstrate a payment dispute',
  ),
  value: receiptMissing,
  onChanged: (value) {
    setState(() {
      receiptMissing = value;
    });
  },
),

const SizedBox(height: 12),

FilledButton.icon(
  onPressed: paymentStatus ==
          'Awaiting merchant verification'
      ? verifyMerchantReceipt
      : null,
  icon: const Icon(Icons.verified),
  label: const Text('Verify Demo Receipt'),
),

            ],
          ),
        );

      case 2:
        return section(
          'Receive Money',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Merchant: ABC Grocery Store'),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              FilledButton(
                onPressed: createRequest,
                child: const Text('Create Payment Request'),
              ),
              const SizedBox(height: 15),
              Text('Session: $sessionId'),
              Text('Status: $paymentStatus'),
            ],
          ),
        );

     
case 3:
  return section(
    'Dispute Replay & Review',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Session: $sessionId',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text('Payment Status: $paymentStatus'),

        const SizedBox(height: 20),

        const Text(
          'Transaction Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        if (timeline.isEmpty)
          const Text('No transaction events yet.'),

        for (int i = 0; i < timeline.length; i++)
          ListTile(
            leading: CircleAvatar(
              child: Text('${i + 1}'),
            ),
            title: Text(timeline[i]),
          ),

        const SizedBox(height: 20),

        if (paymentStatus.contains('Mismatch')) ...[
          const Text(
            'A payment mismatch was detected.',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed:
                reviewSubmitted ? null : submitForReview,
            icon: const Icon(Icons.support_agent),
            label: Text(
              reviewSubmitted
                  ? 'Submitted for Review'
                  : 'Submit for Human Review',
            ),
          ),

          if (reviewSubmitted)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Review Status: Pending manual review',
              ),
            ),
        ],

        if (paymentStatus == 'Matched')
          const Text(
            'Demo payment records matched successfully.',
            style: TextStyle(color: Colors.green),
          ),
      ],
    ),
  );


      
default:
  return section(
    'Financial Insights',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Budget Tracker',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: budgetController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Monthly budget (₹)',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 10),

        FilledButton(
          onPressed: updateBudget,
          child: const Text('Save Budget'),
        ),

        const SizedBox(height: 20),

        Text(
          'Monthly Budget: ₹${monthlyBudget.toStringAsFixed(2)}',
        ),

        Text(
          'Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}',
        ),

        Text(
          'Budget Left: ₹${(monthlyBudget - totalExpenses).toStringAsFixed(2)}',
        ),

        const SizedBox(height: 12),

        LinearProgressIndicator(
          value: (totalExpenses / monthlyBudget)
              .clamp(0.0, 1.0)
              .toDouble(),
          minHeight: 10,
        ),

        const SizedBox(height: 25),

        const Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: expenseController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Expense Amount (₹)',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 10),

        DropdownButton<String>(
          value: expenseCategory,
          isExpanded: true,
          items: [
            'Groceries',
            'Food',
            'Transport',
            'Shopping',
            'Bills',
            'Others',
          ].map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
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
          label: const Text('Add Expense'),
        ),

        const SizedBox(height: 20),

        const Text(
          'Expense History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        if (expenseRecords.isEmpty)
          const Text('No expenses recorded yet.'),

        for (final record in expenseRecords)
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(record['category'] as String),
            trailing: Text(
              '₹${(record['amount'] as double).toStringAsFixed(2)}',
            ),
          ),

        const Divider(height: 35),

        const Text(
          'Merchant Collections',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Verified Collections: ₹${totalCollections.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        if (collectionRecords.isEmpty)
          const Text('No matched demo payments yet.'),

        for (final record in collectionRecords)
          ListTile(
            leading: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            title: Text(record['sessionId'] as String),
            trailing: Text(
              '₹${(record['amount'] as double).toStringAsFixed(2)}',
            ),
          ),

        const Divider(height: 35),

        const Text(
          'Financial Safety Tips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const ListTile(
          leading: Icon(Icons.security),
          title: Text('Never share your UPI PIN or OTP.'),
        ),

        const ListTile(
          leading: Icon(Icons.verified_user),
          title: Text(
            'Always check the recipient before paying.',
          ),
        ),

        const ListTile(
          leading: Icon(Icons.warning_amber),
          title: Text(
            'Do not trust payment screenshots alone.',
          ),
        ),
      ],
    ),
  );

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TrustPay 360',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
          setState(() => currentPage = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.send),
            label: 'Send',
          ),
          NavigationDestination(
            icon: Icon(Icons.store),
            label: 'Receive',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Disputes',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
