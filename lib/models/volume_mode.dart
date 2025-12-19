enum VolumeMode {
  Volume,
  VolumePlus,
}

extension VolumeModeExtension on VolumeMode {
  String get displayName {
    switch (this) {
      case VolumeMode.Volume:
        return 'Volume';
      case VolumeMode.VolumePlus:
        return 'Volume Plus';
    }
  }
}
