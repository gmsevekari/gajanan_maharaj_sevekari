String toMarathiNumerals(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], marathi[i]);
  }
  return input;
}

String formatNumberLocalized(
  dynamic number,
  String languageCode, {
  bool pad = true,
}) {
  if (number == null) return '';
  String numStr = number.toString();
  if (pad) {
    if (numStr.length == 1 && int.tryParse(numStr) != null) {
      numStr = numStr.padLeft(2, '0');
    }
  }
  if (languageCode != 'mr') return numStr;
  return toMarathiNumerals(numStr);
}
