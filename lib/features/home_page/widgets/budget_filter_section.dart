import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../notifiers/product_notifier.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);
const _kBg      = Color(0xFFF4F6F4);

class BudgetFilterSection extends ConsumerWidget {
  const BudgetFilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0A0F0C), letterSpacing: -0.2),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _BudgetBtn(label: 'Low',    range: 'Under 10k', value: 'low',    budget: budget, ref: ref)),
              const SizedBox(width: 8),
              Expanded(child: _BudgetBtn(label: 'Middle', range: '10k – 50k', value: 'middle', budget: budget, ref: ref)),
              const SizedBox(width: 8),
              Expanded(child: _BudgetBtn(label: 'High',   range: '50k+',      value: 'high',   budget: budget, ref: ref)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetBtn extends StatelessWidget {
  final String label;
  final String range;
  final String value;
  final String budget;
  final WidgetRef ref;

  const _BudgetBtn({
    required this.label,
    required this.range,
    required this.value,
    required this.budget,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final active = budget == value;
    return GestureDetector(
      onTap: () {
        ref.read(budgetFilterProvider.notifier).state = active ? '' : value;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: active ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? _kPrimary : Colors.black.withOpacity(0.07),
            width: 1.5,
          ),
          boxShadow: active
              ? [BoxShadow(color: _kPrimary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF0A0F0C),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              range,
              style: TextStyle(
                fontSize: 10,
                color: active ? Colors.white.withOpacity(0.45) : const Color(0xFF8EA899),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
