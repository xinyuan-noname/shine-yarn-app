String getLocalTimeString(DateTime time) {
  try {
    return time.toLocal().toString();
  } catch (e) {
    return time.toString(); 
  }
}