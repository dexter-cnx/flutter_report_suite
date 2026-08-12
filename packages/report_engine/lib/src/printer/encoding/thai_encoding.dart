/// Thai text encoding strategies supported by ESC/POS rendering.
///
/// Code-page strategies are printer-dependent. [rasterImage] is intended for
/// devices whose Thai code pages are missing or unreliable.
enum ThaiEncoding {
  tis620,
  cp874,
  rasterImage,
}
