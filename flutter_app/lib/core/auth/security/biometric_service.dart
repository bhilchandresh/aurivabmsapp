class BiometricService {
  Future<bool> isAvailable() async {
    return false;
  }

  Future<bool> authenticate() async {
    return true;
  }

  Future<void> enable() async {}

  Future<void> disable() async {}
}
