import 'package:flutter/material.dart';

final bottomLine = PreferredSize(
  preferredSize: Size.fromHeight(0),
  child: Container(color: Color.fromARGB(45, 158, 158, 158), height: 2),
);

final bottomLineSmall = PreferredSize(
  preferredSize: Size.fromHeight(0),
  child: Container(color: Color.fromARGB(45, 158, 158, 158), height: 0.5),
);
final bottomLineLarge = PreferredSize(
  preferredSize: Size.fromHeight(0),
  child: Container(color: Color.fromARGB(45, 158, 158, 158), height: 6),
);
