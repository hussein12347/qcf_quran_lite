import 'package:qcf_quran_lite/src/data/page_data_1985.dart';
import 'package:qcf_quran_lite/src/data/quran_data_1985.dart';

import 'page_data.dart';
import 'quran_data.dart';

enum MushafEdition {
  edition1985,

  edition2003,
}

MushafEdition _currentEdition = MushafEdition.edition2003;

MushafEdition get currentMushafEdition => _currentEdition;

List get activePageData =>
    _currentEdition == MushafEdition.edition1985 ? pageData1985 : pageData;

List get activeQuran =>
    _currentEdition == MushafEdition.edition1985 ? quran1985 : quran;
final List<void Function()> _editionListeners = [];

void addMushafEditionListener(void Function() listener) =>
    _editionListeners.add(listener);

void setMushafEditionInternal(MushafEdition edition) {
  if (_currentEdition == edition) return;
  _currentEdition = edition;
  for (final l in _editionListeners) {
    l();
  }
}