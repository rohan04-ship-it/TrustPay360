import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionPage extends StatefulWidget {
  final void Function(String role) onSelected;

  const RoleSelectionPage({super.key, required this.onSelected});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? selectedRole;

  static const navy = Color(0xFF0A1330);
  static const mint = Color(0xFF59F0B5);

  Widget roleCard(
    String name,
    String description,
    IconData icon,
    Color background,
  ) {
    final selected = selectedRole == name;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          setState(() {
            selectedRole = name;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? const Color(0xFF00A896) : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: navy),

              const SizedBox(height: 14),

              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  color: navy,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF475467), fontSize: 12),
              ),

              const SizedBox(height: 16),

              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? const Color(0xFF00A896) : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: mint,
                    size: 58,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Choose your workspace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Personalize your TrustPay 360 experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      roleCard(
                        'Customer',
                        'Safe digital payments',
                        Icons.person_outline,
                        const Color(0xFFDDFBF0),
                      ),

                      const SizedBox(width: 12),

                      roleCard(
                        'Merchant',
                        'Payments and collections',
                        Icons.storefront_outlined,
                        const Color(0xFFE7DBFF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      roleCard(
                        'Student',
                        'Budget and expense tracking',
                        Icons.school_outlined,
                        const Color(0xFFE9F2FF),
                      ),

                      const SizedBox(width: 12),

                      roleCard(
                        'Business Owner',
                        'Business financial insights',
                        Icons.business_center_outlined,
                        const Color(0xFFFFF3D9),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: mint,
                        foregroundColor: navy,
                        minimumSize: const Size(0, 58),
                      ),
                      onPressed: selectedRole == null
                          ? null
                          : () {
                              final user = FirebaseAuth.instance.currentUser;

                              if (user != null && !user.isAnonymous) {
                                widget.onSelected(selectedRole!);
                              }
                            },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        selectedRole == null
                            ? 'Select account type'
                            : 'Continue as $selectedRole',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Account type selection is mandatory.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
