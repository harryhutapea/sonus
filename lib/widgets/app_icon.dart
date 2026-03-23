import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

class AppIcon extends StatelessWidget {
  final String assetName;
  final Color? color;
  final double size;

  const AppIcon(this.assetName, {super.key, this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/$assetName.svg',
      height: size,
      width: size,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn) 
          : null,
    );
  }
}