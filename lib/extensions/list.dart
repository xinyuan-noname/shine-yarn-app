extension SafeRemoveAt<T> on List<T> {
  T? safeRemoveAt(int index) {
    if (length - 1 < index) return null;
    return removeAt(index);
  }
}
