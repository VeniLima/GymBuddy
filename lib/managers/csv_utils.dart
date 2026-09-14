/// Formats a free-text value as a safely-quoted CSV field.
///
/// User-entered names (workout/exercise/routine names) are exported as-is
/// into CSV files that get opened in spreadsheet apps. Excel/Sheets treat a
/// leading `=`, `+`, `-` or `@` as the start of a formula, so a crafted name
/// (e.g. an exercise called `=HYPERLINK(...)`) could execute when the
/// exported file is opened by someone else. Prefixing such values with an
/// apostrophe forces the cell to be read as plain text.
String sanitizeCsvField(String value) {
  var v = value;
  if (v.isNotEmpty && RegExp(r'^[=+\-@]').hasMatch(v)) {
    v = "'$v";
  }
  return '"${v.replaceAll('"', '""')}"';
}
