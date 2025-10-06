import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/habits/habit_providers.dart';
import '../../core/date_key.dart';
import '../../domain/habits/habit.dart';
import '../widgets/habit_card.dart';

class HabitListPage extends ConsumerWidget {
  const HabitListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitStreamProvider);
    return _HabitsScreen(habitsAsync: habitsAsync);
  }
}

class _HabitsScreen extends ConsumerWidget {
  const _HabitsScreen({required this.habitsAsync});
  final AsyncValue<List<Habit>> habitsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awesome Habits'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
                if (!context.mounted) return;
                context.go('/auth');
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sign-out failed: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Something went wrong. Please try again.\n$e'),
            ),
          ),
          data: (habits) {
            final todayKey = DateKey.today();
            final pending =
                habits.where((h) => !h.isCompletedOn(todayKey)).toList();
            final completed =
                habits.where((h) => h.isCompletedOn(todayKey)).toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  sliver: const SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Pending habits',
                    ),
                  ),
                ),
                if (pending.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        'No pending habits for today. Great job!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: pending.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final habit = pending[index];
                        final bg = _pendingColorFor(index);
                        return HabitCard(
                          habit: habit,
                          background: bg,
                          completed: false,
                          onToggle: () => ref
                              .read(habitListControllerProvider.notifier)
                              .toggleToday(habit.id),
                          onDelete: () => ref
                              .read(habitListControllerProvider.notifier)
                              .deleteHabit(habit.id),
                        );
                      },
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  sliver: const SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Completed habits'),
                  ),
                ),
                if (completed.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        'Nothing completed yet. Keep going!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: completed.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final habit = completed[index];
                        return HabitCard(
                          habit: habit,
                          background: Colors.pink.shade100,
                          completed: true,
                          onToggle: () => ref
                              .read(habitListControllerProvider.notifier)
                              .toggleToday(habit.id),
                          onDelete: () => ref
                              .read(habitListControllerProvider.notifier)
                              .deleteHabit(habit.id),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
        onPressed: () => _showAddHabitDialog(context, ref),
      ),
    );
  }

  static Color _pendingColorFor(int index) {
    switch (index % 3) {
      case 0:
        return Colors.orange.shade100;
      case 1:
        return Colors.teal.shade100;
      default:
        return Colors.lightBlue.shade100;
    }
  }

  Future<void> _showAddHabitDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final added = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Habit'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g., Drink water',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await ref
                      .read(habitListControllerProvider.notifier)
                      .addHabit(controller.text);
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    if (added == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit added')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}


