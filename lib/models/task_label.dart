import 'package:flutter/material.dart';

class TaskLabel {
  final String name;
  final Color color;

  const TaskLabel(this.name, this.color);
}

// TODO: let the user make their own labels (1k)
const defaultLabels = [
  TaskLabel('University', Colors.black),
  TaskLabel('Work', Color(0xFF757575)),
  TaskLabel('Health', Color(0xFFBDBDBD)),
  TaskLabel('Personal', Color(0xFFD32F2F)),
];
