import 'package:flutter/material.dart';

import '../../domain/habits/habit.dart';

/// A reusable card widget to display a habit with toggle and delete actions.
///
/// Public API kept stable for reuse across pages:
/// - [habit]: the habit to display
/// - [background]: background fill color of the card
/// - [completed]: whether the habit is completed for the current day
/// - [onToggle]: called when the checkbox is tapped to toggle completion
/// - [onDelete]: called when the delete icon is pressed
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.background,
    required this.completed,
    required this.onToggle,
    required this.onDelete,
  });

  final Habit habit;
  final Color background;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
        );
    final subtitleStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6));

    // Material provides ink splash for the inner checkbox InkWell only.
    return Material(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Center all children vertically
          children: [
            Tooltip(
              message: completed ? 'Mark as not done' : 'Mark as done',
              child: InkWell(
                onTap: onToggle,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: completed ? cs.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primary, width: completed ? 0 : 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    size: completed ? 18 : 0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(habit.name, style: titleStyle),
                  const SizedBox(height: 4),
                  Text(
                    completed ? 'Completed today' : 'Tap the checkbox to complete',
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
