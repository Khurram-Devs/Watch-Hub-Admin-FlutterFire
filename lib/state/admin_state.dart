import 'package:flutter/material.dart';
import '../models/admin_model.dart';

class AdminState {
  static final ValueNotifier<AdminModel?> currentAdmin = ValueNotifier(null);
}
