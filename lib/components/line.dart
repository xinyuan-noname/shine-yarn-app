import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

final bottomLine = PreferredSize(
  preferredSize: Size.fromHeight(0),
  child: Container(
    color: mainColorGrey20,
    height: 2,
    margin: EdgeInsets.only(bottom: 1),
  ),
);

final bottomLineSmall = PreferredSize(
  preferredSize: Size.fromHeight(0),
  child: Container(
    color: mainColorGrey20,
    height: 0.5,
    margin: EdgeInsets.only(bottom: 1),
  ),
);
final bottomLineLarge = PreferredSize(
  preferredSize: Size.fromHeight(0),
  child: Container(
    color: mainColorGrey20,
    height: 4,
    margin: EdgeInsets.only(bottom: 1),
  ),
);
