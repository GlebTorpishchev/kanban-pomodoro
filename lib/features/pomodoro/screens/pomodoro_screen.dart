import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro_kanban/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:pomodoro_kanban/features/pomodoro/widgets/timer_widget.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<PomodoroProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimerWidget(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: provider.isRunning
                          ? provider.pauseTimer
                          : provider.startTimer,
                      child: Text(provider.isRunning ? 'Пауза' : 'Старт'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: provider.resetTimer,
                      child: const Text('Сброс'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('Работа (мин)'),
                        DropdownButton<int>(
                          value: provider.workDuration,
                          items: [15, 25, 30, 45]
                              .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.toString()),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              provider.setWorkDuration(value);
                            }
                          },
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Перерыв (мин)'),
                        DropdownButton<int>(
                          value: provider.breakDuration,
                          items: [5, 10, 15]
                              .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.toString()),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              provider.setBreakDuration(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}