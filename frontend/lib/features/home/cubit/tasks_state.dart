part of 'tasks_cubit.dart';

sealed class TasksState {
  const TasksState();
}

final class TasksInitial extends TasksState {}

final class TasksLoading extends TasksState {}

final class TasksError extends TasksState {
  final String error;
  const TasksError({required this.error});
}

final class AddNewTaskSuccess extends TasksState {
  final TasksModel taskModel;
  const AddNewTaskSuccess({required this.taskModel});
}

final class GetTasksSuccess extends TasksState {
  final List<TasksModel> tasks;
  const GetTasksSuccess({required this.tasks});
}

final class TasksUIState extends TasksState {
  final DateTime? selectedDate;
  final Color? selectedColor;

  const TasksUIState({
    this.selectedDate,
    this.selectedColor,
  });

  TasksUIState copyWith({
    DateTime? selectedDate,
    Color? selectedColor,
  }) {
    return TasksUIState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }
}
