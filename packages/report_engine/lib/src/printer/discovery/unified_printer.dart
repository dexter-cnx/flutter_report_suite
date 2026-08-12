enum PrinterConnectionType {
  system,
  usb,
  network,
  bluetooth,
  embedded,
}

class UnifiedPrinter {
  const UnifiedPrinter({
    required this.id,
    required this.name,
    required this.type,
    this.metadata = const <String, String>{},
  });

  final String id;
  final String name;
  final PrinterConnectionType type;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedPrinter &&
          other.id == id &&
          other.name == name &&
          other.type == type;

  @override
  int get hashCode => Object.hash(id, name, type);
}
