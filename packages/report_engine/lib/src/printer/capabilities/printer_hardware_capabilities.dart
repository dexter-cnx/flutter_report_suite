/// Optional physical-printer capabilities.
///
/// Adapters implement only the capabilities the target device/transport can
/// actually provide. Callers should check interface presence rather than
/// assuming every printer can cut paper or drive a cash drawer.
abstract interface class CutterCapability {
  Future<void> cutPaper();
}

abstract interface class CashDrawerCapability {
  Future<void> openCashDrawer();

  Future<bool> isCashDrawerOpen();
}
