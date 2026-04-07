enum ParayanType { oneDay, threeDay, guruPushya }

extension ParayanTypeExtensions on ParayanType {
  int get daysCount {
    switch (this) {
      case ParayanType.oneDay:
      case ParayanType.guruPushya:
        return 1;
      case ParayanType.threeDay:
        return 3;
    }
  }
}
