String? requiredText(String value, String message) {
  if (value.trim().isEmpty) {
    return message;
  }
  return null;
}
