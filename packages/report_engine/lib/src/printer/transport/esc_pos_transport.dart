/// Transport boundary for sending already-rendered ESC/POS bytes.
///
/// Encoding/rendering code must not depend on Bluetooth, USB, network, or
/// embedded-printer plugin objects. Platform adapters implement this contract.
abstract interface class EscPosTransport {
  Future<void> send(List<int> bytes);
}
