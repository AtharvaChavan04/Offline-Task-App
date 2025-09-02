import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/home/repository/task_local_repository.dart';
import 'package:frontend/features/home/repository/task_remote_repository.dart';
import 'package:frontend/models/tasks_model.dart';
part 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit() : super(TasksInitial());

  final taskRemoteRepository = TaskRemoteRepository();
  final taskLocalRepository = TaskLocalRepository();

  Future<void> createNewTask({
    required String title,
    required String description,
    required Color color,
    required String token,
    required DateTime dueAt,
    required String uid,
  }) async {
    emit(TasksLoading());
    try {
      emit(TasksLoading());

      final taskModel = await taskRemoteRepository.createTask(
        uid: uid,
        title: title,
        description: description,
        hexColor: rgbToHex(color),
        token: token,
        dueAt: dueAt,
      );

      await taskLocalRepository.insertTask(taskModel);
      emit(AddNewTaskSuccess(taskModel: taskModel));
    } catch (e) {
      emit(TasksError(error: e.toString()));
    }
  }

  Future<void> getAllTasks({
    required String token,
  }) async {
    emit(TasksLoading());
    try {
      emit(TasksLoading());

      final tasks = await taskRemoteRepository.getTask(
        token: token,
      );
      emit(GetTasksSuccess(tasks: tasks));
    } catch (e) {
      try {
        final localTasks = await taskLocalRepository.getTasks();

        if (localTasks.isNotEmpty) {
          emit(GetTasksSuccess(tasks: localTasks));
        } else {
          emit(TasksError(error: 'No tasks available offline'));
        }
      } catch (localError) {
        emit(TasksError(error: e.toString()));
      }
    }
  }

  Future<void> syncTasks(String token) async {
    final unsyncedTasks = await taskLocalRepository.getUnsyncedTasks();
    if (unsyncedTasks.isEmpty) return;
    final isSynced = await taskRemoteRepository.syncTasks(
      token: token,
      tasks: unsyncedTasks,
    );
    if (isSynced) {
      for (final task in unsyncedTasks) {
        await taskLocalRepository.updateRowValue(task.id, 1);
      }
    }
  }

  void updateSelectedDate(DateTime date) {
    final current =
        state is TasksUIState ? (state as TasksUIState) : const TasksUIState();
    emit(current.copyWith(selectedDate: date));
  }

  void updateSelectedColor(Color color) {
    final current =
        state is TasksUIState ? (state as TasksUIState) : const TasksUIState();
    emit(current.copyWith(selectedColor: color));
  }
}
