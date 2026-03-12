extension SafeIndex<T> on List<T> {
  T? safeElementAt(int index) {
    return (index >= 0 && index < length) ? this[index] : null;
  }
}
extension SafeLast<T> on List<T> {
  T? get safeLast => isNotEmpty ? last : null;
}
extension SafeFirst<T> on List<T> {
  T? get safeFirst => isNotEmpty ? first : null;
}