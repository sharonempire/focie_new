import 'package:flutter/material.dart';

globalSnackbar({required BuildContext context, required String content}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Center(child: Text(content))));
}
