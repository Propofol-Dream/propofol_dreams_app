import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4279069528),
      surfaceTint: Color(4279069528),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4288869082),
      onPrimaryContainer: Color(4278198297),
      secondary: Color(4280312967),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4291225599),
      onSecondaryContainer: Color(4278197805),
      tertiary: Color(4285488398),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4294632071),
      onTertiaryContainer: Color(4280425216),
      error: Color(4290386458),
      onError: Color(4294967295),
      errorContainer: Color(4294957782),
      onErrorContainer: Color(4282449922),
      surface: Color(4294310903),
      onSurface: Color(4279704859),
      onSurfaceVariant: Color(4282337605),
      outline: Color(4285495669),
      outlineVariant: Color(4290759108),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020975),
      inversePrimary: Color(4287026879),
      primaryFixed: Color(4288869082),
      onPrimaryFixed: Color(4278198297),
      primaryFixedDim: Color(4287026879),
      onPrimaryFixedVariant: Color(4278210882),
      secondaryFixed: Color(4291225599),
      onSecondaryFixed: Color(4278197805),
      secondaryFixedDim: Color(4287811317),
      onSecondaryFixedVariant: Color(4278209643),
      tertiaryFixed: Color(4294632071),
      onTertiaryFixed: Color(4280425216),
      tertiaryFixedDim: Color(4292724334),
      onTertiaryFixedVariant: Color(4283713024),
      surfaceDim: Color(4292205528),
      surfaceBright: Color(4294310903),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4293916145),
      surfaceContainer: Color(4293521387),
      surfaceContainerHigh: Color(4293126886),
      surfaceContainerHighest: Color(4292797664),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278209598),
      surfaceTint: Color(4279069528),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4281303662),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4278208613),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4282153887),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4283449856),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4287001381),
      onTertiaryContainer: Color(4294967295),
      error: Color(4287365129),
      onError: Color(4294967295),
      errorContainer: Color(4292490286),
      onErrorContainer: Color(4294967295),
      surface: Color(4294310903),
      onSurface: Color(4279704859),
      onSurfaceVariant: Color(4282074433),
      outline: Color(4283916637),
      outlineVariant: Color(4285758841),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020975),
      inversePrimary: Color(4287026879),
      primaryFixed: Color(4281303662),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4278675542),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4282153887),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4280115844),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4287001381),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4285291275),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292205528),
      surfaceBright: Color(4294310903),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4293916145),
      surfaceContainer: Color(4293521387),
      surfaceContainerHigh: Color(4293126886),
      surfaceContainerHighest: Color(4292797664),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278200351),
      surfaceTint: Color(4279069528),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4278209598),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4278199607),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4278208613),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4280951296),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4283449856),
      onTertiaryContainer: Color(4294967295),
      error: Color(4283301890),
      onError: Color(4294967295),
      errorContainer: Color(4287365129),
      onErrorContainer: Color(4294967295),
      surface: Color(4294310903),
      onSurface: Color(4278190080),
      onSurfaceVariant: Color(4280100387),
      outline: Color(4282074433),
      outlineVariant: Color(4282074433),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020975),
      inversePrimary: Color(4289461476),
      primaryFixed: Color(4278209598),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4278203433),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4278208613),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4278202438),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4283449856),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4281740288),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292205528),
      surfaceBright: Color(4294310903),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4293916145),
      surfaceContainer: Color(4293521387),
      surfaceContainerHigh: Color(4293126886),
      surfaceContainerHighest: Color(4292797664),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4287026879),
      surfaceTint: Color(4287026879),
      onPrimary: Color(4278204461),
      primaryContainer: Color(4278210882),
      onPrimaryContainer: Color(4288869082),
      secondary: Color(4287811317),
      onSecondary: Color(4278203467),
      secondaryContainer: Color(4278209643),
      onSecondaryContainer: Color(4291225599),
      tertiary: Color(4292724334),
      onTertiary: Color(4282003456),
      tertiaryContainer: Color(4283713024),
      onTertiaryContainer: Color(4294632071),
      error: Color(4294948011),
      onError: Color(4285071365),
      errorContainer: Color(4287823882),
      onErrorContainer: Color(4294957782),
      surface: Color(4279178515),
      onSurface: Color(4292797664),
      onSurfaceVariant: Color(4290759108),
      outline: Color(4287206286),
      outlineVariant: Color(4282337605),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292797664),
      inversePrimary: Color(4279069528),
      primaryFixed: Color(4288869082),
      onPrimaryFixed: Color(4278198297),
      primaryFixedDim: Color(4287026879),
      onPrimaryFixedVariant: Color(4278210882),
      secondaryFixed: Color(4291225599),
      onSecondaryFixed: Color(4278197805),
      secondaryFixedDim: Color(4287811317),
      onSecondaryFixedVariant: Color(4278209643),
      tertiaryFixed: Color(4294632071),
      onTertiaryFixed: Color(4280425216),
      tertiaryFixedDim: Color(4292724334),
      onTertiaryFixedVariant: Color(4283713024),
      surfaceDim: Color(4279178515),
      surfaceBright: Color(4281613112),
      surfaceContainerLowest: Color(4278783757),
      surfaceContainerLow: Color(4279704859),
      surfaceContainer: Color(4279968031),
      surfaceContainerHigh: Color(4280625961),
      surfaceContainerHighest: Color(4281349684),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4287290051),
      surfaceTint: Color(4287026879),
      onPrimary: Color(4278197012),
      primaryContainer: Color(4283408266),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4288074489),
      onSecondary: Color(4278196518),
      secondaryContainer: Color(4284192700),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4292987506),
      onTertiary: Color(4280030720),
      tertiaryContainer: Color(4288974910),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294949553),
      onError: Color(4281794561),
      errorContainer: Color(4294923337),
      onErrorContainer: Color(4278190080),
      surface: Color(4279178515),
      onSurface: Color(4294376696),
      onSurfaceVariant: Color(4291022280),
      outline: Color(4288390560),
      outlineVariant: Color(4286285185),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292797664),
      inversePrimary: Color(4278211139),
      primaryFixed: Color(4288869082),
      onPrimaryFixed: Color(4278195471),
      primaryFixedDim: Color(4287026879),
      onPrimaryFixedVariant: Color(4278206002),
      secondaryFixed: Color(4291225599),
      onSecondaryFixed: Color(4278194974),
      secondaryFixedDim: Color(4287811317),
      onSecondaryFixedVariant: Color(4278205011),
      tertiaryFixed: Color(4294632071),
      onTertiaryFixed: Color(4279636224),
      tertiaryFixedDim: Color(4292724334),
      onTertiaryFixedVariant: Color(4282463488),
      surfaceDim: Color(4279178515),
      surfaceBright: Color(4281613112),
      surfaceContainerLowest: Color(4278783757),
      surfaceContainerLow: Color(4279704859),
      surfaceContainer: Color(4279968031),
      surfaceContainerHigh: Color(4280625961),
      surfaceContainerHighest: Color(4281349684),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4293722103),
      surfaceTint: Color(4287026879),
      onPrimary: Color(4278190080),
      primaryContainer: Color(4287290051),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4294507519),
      onSecondary: Color(4278190080),
      secondaryContainer: Color(4288074489),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4294966005),
      onTertiary: Color(4278190080),
      tertiaryContainer: Color(4292987506),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294965753),
      onError: Color(4278190080),
      errorContainer: Color(4294949553),
      onErrorContainer: Color(4278190080),
      surface: Color(4279178515),
      onSurface: Color(4294967295),
      onSurfaceVariant: Color(4294180344),
      outline: Color(4291022280),
      outlineVariant: Color(4291022280),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292797664),
      inversePrimary: Color(4278202663),
      primaryFixed: Color(4289132511),
      onPrimaryFixed: Color(4278190080),
      primaryFixedDim: Color(4287290051),
      onPrimaryFixedVariant: Color(4278197012),
      secondaryFixed: Color(4291816191),
      onSecondaryFixed: Color(4278190080),
      secondaryFixedDim: Color(4288074489),
      onSecondaryFixedVariant: Color(4278196518),
      tertiaryFixed: Color(4294960779),
      onTertiaryFixed: Color(4278190080),
      tertiaryFixedDim: Color(4292987506),
      onTertiaryFixedVariant: Color(4280030720),
      surfaceDim: Color(4279178515),
      surfaceBright: Color(4281613112),
      surfaceContainerLowest: Color(4278783757),
      surfaceContainerLow: Color(4279704859),
      surfaceContainer: Color(4279968031),
      surfaceContainerHigh: Color(4280625961),
      surfaceContainerHighest: Color(4281349684),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
