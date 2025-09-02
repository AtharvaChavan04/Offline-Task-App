import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';
import 'package:frontend/features/home/cubit/tasks_cubit.dart';
import 'package:frontend/features/home/pages/add_new_task_page.dart';
import 'package:frontend/features/home/widgets/date_selector.dart';
import 'package:frontend/features/home/widgets/task_card.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute route() {
    return MaterialPageRoute(builder: (context) => const HomePage());
  }

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state as AuthLoggedIn;
    context.read<TasksCubit>().getAllTasks(token: user.user.token);
    Connectivity().onConnectivityChanged.listen((data) async {
      if (data.contains(ConnectivityResult.wifi) ||
          data.contains(ConnectivityResult.mobile)) {
        await context.read<TasksCubit>().syncTasks(user.user.token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () {
              Navigator.push(context, AddNewTaskPage.route());
            },
          ),
        ],
      ),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TasksError) {
            return Center(child: Text(state.error));
          }
          if (state is GetTasksSuccess) {
            final tasks = state.tasks
                .where(
                  (elem) =>
                      DateFormat('d').format(elem.dueAt) ==
                          DateFormat('d').format(selectedDate) &&
                      selectedDate.month == elem.dueAt.month &&
                      selectedDate.year == elem.dueAt.year,
                )
                .toList();
            return Column(
              children: [
                DateSelector(
                  onTap: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                  selectedDate: selectedDate,
                ),
                Expanded(
                  child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Row(
                          children: [
                            Expanded(
                              child: TaskCard(
                                color: task.color,
                                headerText: task.title,
                                descriptionText: task.description.isEmpty
                                    ? 'No Description'
                                    : task.description,
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: strengthenColor(
                                  task.color,
                                  0.69,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                DateFormat.jm().format(task.dueAt),
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
