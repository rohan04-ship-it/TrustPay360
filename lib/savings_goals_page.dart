import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalsPage extends StatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {
  static const navy = Color(0xFF0A1330);
  static const mint = Color(0xFF59F0B5);
  static const blue = Color(0xFF17468C);

  late final String uid;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> goalsStream;

  bool saving = false;

  CollectionReference<Map<String, dynamic>> get goals => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('savings');

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    goalsStream = validUser()
        ? goals.snapshots(includeMetadataChanges: true)
        : Stream.empty();
  }

  bool validUser() {
    final user = FirebaseAuth.instance.currentUser;

    return user != null && !user.isAnonymous && user.uid == uid;
  }

  String money(num value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  void notify(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> createGoal() async {
    if (saving || !validUser()) return;

    String name = '';
    String amountText = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLength: 80,
              onChanged: (value) => name = value,
              decoration: const InputDecoration(
                labelText: 'Goal name',
                hintText: 'New Laptop',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => amountText = value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || saving || !validUser()) {
      return;
    }

    final target = double.tryParse(amountText.trim());

    if (name.trim().isEmpty ||
        name.trim().length > 80 ||
        target == null ||
        !target.isFinite ||
        target <= 0 ||
        target > 1000000000) {
      notify('Enter a valid goal name and target amount');
      return;
    }

    setState(() => saving = true);

    try {
      await goals.add({
        'name': name.trim(),
        'target': target,
        'saved': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notify('Savings goal created successfully');
    } catch (error) {
      notify('Unable to create goal: $error');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> addSavings(String goalId) async {
    if (saving || !validUser()) return;

    String amountText = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record Savings'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => amountText = value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Saved amount',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || saving || !validUser()) {
      return;
    }

    final amount = double.tryParse(amountText.trim());

    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > 1000000000) {
      notify('Enter a valid savings amount');
      return;
    }

    setState(() => saving = true);

    try {
      final ref = goals.doc(goalId);

      await FirebaseFirestore.instance.runTransaction<void>((
        transaction,
      ) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();

        if (data == null) {
          throw StateError('Savings goal no longer exists');
        }

        final target = (data['target'] as num).toDouble();

        final saved = (data['saved'] as num).toDouble();

        final newAmount = saved + amount;

        if (newAmount > target) {
          throw StateError('Amount exceeds remaining goal balance');
        }

        transaction.update(ref, {
          'saved': newAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      notify('Savings recorded successfully');
    } catch (error) {
      notify('Unable to record savings: $error');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> deleteGoal(String goalId) async {
    if (saving || !validUser()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Savings Goal?'),
        content: const Text('This savings record will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || saving || !validUser()) {
      return;
    }

    setState(() => saving = true);

    try {
      await goals.doc(goalId).delete();
      notify('Savings goal deleted');
    } catch (error) {
      notify('Unable to delete goal: $error');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget goalCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final name = data['name'] as String;

    final target = (data['target'] as num).toDouble();

    final saved = (data['saved'] as num).toDouble();

    final progress = target > 0
        ? (saved / target).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final completed = saved >= target;

    final accent = completed ? Colors.green : blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFDDFBF0) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.1),
                child: Icon(
                  completed ? Icons.check_circle : Icons.flag_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: saving ? null : () => deleteGoal(doc.id),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            money(saved),
            style: TextStyle(
              color: accent,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),

          Text('Target: ${money(target)}'),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              color: accent,
              backgroundColor: const Color(0xFFE9F2FF),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '${(progress * 100).toStringAsFixed(1)}% completed',
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text('Remaining: ${money(target - saved)}'),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
              ),
              onPressed: saving || completed ? null : () => addSavings(doc.id),
              icon: Icon(completed ? Icons.verified : Icons.add),
              label: Text(completed ? 'Goal Achieved!' : 'Record Savings'),
            ),
          ),

          if (doc.metadata.hasPendingWrites)
            const Text('Waiting for server confirmation'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!validUser()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Savings Goals')),
        body: const Center(child: Text('Please sign in again')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Savings Goals'),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mint,
        foregroundColor: navy,
        onPressed: saving ? null : createGoal,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: goalsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load goals: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          double totalSaved = 0;

          for (final doc in docs) {
            totalSaved += (doc.data()['saved'] as num).toDouble();
          }

          final completed = docs.where((doc) {
            final data = doc.data();

            return (data['saved'] as num) >= (data['target'] as num);
          }).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(colors: [blue, navy]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.savings_outlined, color: mint, size: 42),

                    const SizedBox(height: 18),

                    const Text(
                      'Total Recorded Savings',
                      style: TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 8),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        money(totalSaved),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: mint,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      '$completed of ${docs.length} goals completed',
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Savings records only. No money is transferred.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              if (saving)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                ),

              if (snapshot.data!.metadata.isFromCache)
                const Text('Showing cached records'),

              const SizedBox(height: 24),

              const Text(
                'My Savings Goals',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              if (docs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Create your first savings goal to get started.',
                    ),
                  ),
                ),

              ...docs.map(goalCard),
            ],
          );
        },
      ),
    );
  }
}
