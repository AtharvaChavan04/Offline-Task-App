import 'dart:convert';
import 'package:frontend/core/constants/constants.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/home/repository/task_local_repository.dart';
import 'package:frontend/models/tasks_model.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class TaskRemoteRepository {
  final taskLocalRepository = TaskLocalRepository();

  static const Duration _requestTimeout = Duration(seconds: 5);

  Future<TasksModel> createTask({
    required String title,
    required String description,
    required String hexColor,
    required String token,
    required DateTime dueAt,
    required String uid,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse("${Constants.backendUri}/tasks/"),
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
            body: jsonEncode({
              'title': title,
              'description': description,
              'hexColor': hexColor,
              'dueAt': dueAt.toIso8601String(),
            }),
          )
          .timeout(_requestTimeout); // Add timeout

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['error'] ??
            'Failed to create task. Please try again.';
      }

      final taskModel = TasksModel.fromJson(res.body);
      return taskModel;
    } catch (e) {
      try {
        final taskModel = TasksModel(
          id: const Uuid().v4(),
          uid: uid,
          title: title,
          color: hexToRgb(hexColor),
          description: description,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          dueAt: dueAt,
          isSynced: 0,
        );
        await taskLocalRepository.insertTask(taskModel);
        return taskModel;
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<List<TasksModel>> getTask({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.backendUri}/tasks/"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      ).timeout(_requestTimeout); // Add timeout

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ??
            'Failed to fetch tasks. Please try again.';
      }

      final listOfTasks = jsonDecode(res.body);

      List<TasksModel> tasksList = [];
      for (var elem in listOfTasks) {
        tasksList.add(TasksModel.fromMap(elem));
      }

      await taskLocalRepository.insertTasks(tasksList);

      return tasksList;
    } catch (e) {
      try {
        final tasks = await taskLocalRepository.getTasks();

        if (tasks.isNotEmpty) {
          return tasks;
        } else {
          rethrow;
        }
      } catch (localError) {
        rethrow;
      }
    }
  }

  Future<bool> syncTasks({
    required String token,
    required List<TasksModel> tasks,
  }) async {
    try {
      final taskListInMap = [];
      for (final task in tasks) {
        taskListInMap.add(task.toMap());
      }
      final res = await http
          .post(
            Uri.parse("${Constants.backendUri}/tasks/sync"),
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
            body: jsonEncode(taskListInMap),
          )
          .timeout(_requestTimeout); // Add timeout

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['error'] ??
            'Failed to create task. Please try again.';
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
