import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/service_operations/data/models/service_order_task_model.dart';

void main() {
  group('ServiceOrderTaskModel & Checklists Tests', () {
    test('TaskStatus Enum string serialization and label tests', () {
      expect(TaskStatus.fromString('pending'), TaskStatus.pending);
      expect(TaskStatus.fromString('assigned'), TaskStatus.assigned);
      expect(TaskStatus.fromString('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('paused'), TaskStatus.paused);
      expect(TaskStatus.fromString('completed'), TaskStatus.completed);
      expect(TaskStatus.fromString('blocked'), TaskStatus.blocked);

      expect(TaskStatus.inProgress.toDbString(), 'in_progress');
      expect(TaskStatus.completed.toDbString(), 'completed');
      expect(TaskStatus.inProgress.label, 'In Progress');
    });

    test('TaskChecklistModel fromJson and toJson round-trip', () {
      final checklist = TaskChecklistModel(
        id: 'check-1',
        taskId: 'task-1',
        itemDescription: 'Torque lug nuts to 108 Nm',
        isCompleted: true,
        completedAt: DateTime.parse('2026-11-23T10:00:00Z'),
        completedBy: 'mechanic-1',
      );

      final json = checklist.toJson();
      expect(json['id'], 'check-1');
      expect(json['task_id'], 'task-1');
      expect(json['item_description'], 'Torque lug nuts to 108 Nm');
      expect(json['is_completed'], true);

      final from = TaskChecklistModel.fromJson(json);
      expect(from.id, checklist.id);
      expect(from.isCompleted, true);
    });

    test('ServiceOrderTaskModel serialization preserves dependencies and checklists', () {
      final now = DateTime.now();
      final task = ServiceOrderTaskModel(
        id: 'task-uuid-1',
        serviceOrderId: 'order-uuid-1',
        title: 'Brake Pad Replacement',
        description: 'Ceramic composite brake pads',
        estimatedDurationMinutes: 45,
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        dependsOnTaskId: 'task-uuid-0',
        createdAt: now,
        updatedAt: now,
        checklists: [
          const TaskChecklistModel(
            id: 'check-1',
            taskId: 'task-uuid-1',
            itemDescription: 'Clean sliding pins',
            isCompleted: true,
          ),
        ],
      );

      final json = task.toJson();
      expect(json['title'], 'Brake Pad Replacement');
      expect(json['priority'], 'high');
      expect(json['status'], 'in_progress');
      expect(json['depends_on_task_id'], 'task-uuid-0');
      expect(task.hasDependency, true);
      expect(task.isInProgress, true);
      expect(task.isCompleted, false);
    });
  });
}
