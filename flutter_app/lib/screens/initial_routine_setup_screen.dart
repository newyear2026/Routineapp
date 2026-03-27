import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../application/services/onboarding_routine_setup_service.dart';
import '../domain/onboarding/recommended_routine_catalog.dart';

class InitialRoutineSetupScreen extends StatefulWidget {
  const InitialRoutineSetupScreen({super.key});

  @override
  State<InitialRoutineSetupScreen> createState() =>
      _InitialRoutineSetupScreenState();
}

class _InitialRoutineSetupScreenState extends State<InitialRoutineSetupScreen> {
  static const List<RecommendedRoutineDefinition> _catalog =
      RecommendedRoutineCatalog.items;
  final OnboardingRoutineSetupService _onboardingRoutines =
      OnboardingRoutineSetupService();

  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.from(RecommendedRoutineCatalog.defaultSelection);
  }

  void _toggleRoutine(int index) {
    setState(() {
      _selected[index] = !_selected[index];
    });
  }

  List<RecommendedRoutineDefinition> _selectedDefinitions() {
    final out = <RecommendedRoutineDefinition>[];
    for (var i = 0; i < _catalog.length; i++) {
      if (_selected[i]) out.add(_catalog[i]);
    }
    return out;
  }

  Future<void> _completeSetup() async {
    await _onboardingRoutines.completeWithSelectedDefinitions(
      _selectedDefinitions(),
    );
    if (!mounted) return;
    await context.read<RoutineAppController>().load();
    if (!mounted) return;
    context.go('/notification-permission');
  }

  Future<void> _skipRoutineSetup() async {
    await _onboardingRoutines.skipWithoutSavingRoutines();
    if (!mounted) return;
    context.go('/notification-permission');
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.where((s) => s).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F3),
              Color(0xFFFFF5F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text(
                      '루틴 선택',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF8B7B9E),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      '하루를 시작해볼까요?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B7B9E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '원하는 루틴을 선택해주세요\n나중에 언제든 수정할 수 있어요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB8A4C9),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8DDFA).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$selectedCount개 선택됨',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B7B9E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  itemCount: _catalog.length,
                  itemBuilder: (context, index) {
                    final def = _catalog[index];
                    return _buildRoutineCard(
                      def: def,
                      index: index,
                      isSelected: _selected[index],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
                child: TextButton(
                  onPressed: _skipRoutineSetup,
                  child: const Text(
                    '나중에 설정할게요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB8A4C9),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                child: GestureDetector(
                  onTap: _completeSetup,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4C5F0), Color(0xFFC4B5E6)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4C5F0).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '완료하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineCard({
    required RecommendedRoutineDefinition def,
    required int index,
    required bool isSelected,
  }) {
    final color = Color(def.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleRoutine(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color
                  : const Color(0xFFE8DDFA).withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : const Color(0xFFB8A4C9).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    def.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B7B9E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      def.timeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB8A4C9),
                      ),
                    ),
                  ],
                ),
              ),
              if (def.showRecommendedBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB8C6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '추천',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFB8C6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
