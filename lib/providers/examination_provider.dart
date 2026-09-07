import 'package:flutter/foundation.dart';

import '../models/examination_model.dart';
import '../repositories/examination_repository.dart';

class ExaminationProvider extends ChangeNotifier {
  final ExaminationRepository _repository;
  List<ExaminationModel> _examinations = const [];
  bool _loading = false;

  ExaminationProvider({ExaminationRepository? repository})
    : _repository = repository ?? ExaminationRepository();

  List<ExaminationModel> get examinations => List.unmodifiable(_examinations);
  bool get loading => _loading;

  Future<void> loadExaminations() async {
    _loading = true;
    notifyListeners();
    try {
      _examinations = await _repository.fetchExaminations();
    } catch (error, stackTrace) {
      debugPrint('Failed to load examinations: $error');
      debugPrint('$stackTrace');
      _examinations = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
