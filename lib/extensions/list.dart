extension SafeIndex<T> on List<T> {
  T safeElementAt(int index, T fallback) {
    return (index >= 0 && index < length) ? this[index] : fallback;
  }
}