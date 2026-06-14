import 'package:flutter/material.dart';
import '../models/log_model.dart';
import '../services/log_service.dart';

class LogViewModel extends ChangeNotifier {
  final LogService _logService = LogService();
  
  List<LogModel> _logs = [];
  List<LogModel> _filteredLogs = [];
  bool _isLoading = false;

  List<LogModel> get logs => _filteredLogs;
  bool get isLoading => _isLoading;

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _logs = await _logService.getLogs();
      _filteredLogs = List.from(_logs);
    } catch (e) {
      print('Error loading logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterLogs(String query) {
    if (query.isEmpty) {
      _filteredLogs = List.from(_logs);
    } else {
      _filteredLogs = _logs.where((log) {
        return log.hoten.toLowerCase().contains(query.toLowerCase()) ||
               log.hanhdong.toLowerCase().contains(query.toLowerCase()) ||
               log.chitiet.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }
}
