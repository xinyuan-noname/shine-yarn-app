import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shine/services/api.dart';
import 'package:shine/theme.dart';

class NetworkAvatar extends StatelessWidget {
  final String id;
  final double radius;
  final int? ts;
  String get _imageUrl => "${ApiService.url}/profiles/avatar/$id";
  Map<String, String> get _httpHeaders {
    final raw = ApiService.headers;
    return raw.cast<String, String>();
  }

  const NetworkAvatar({super.key, this.radius = 30, this.ts, required this.id});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: ts is int
          ? "$_imageUrl?ts=$ts"
          : _imageUrl,
      httpHeaders: _httpHeaders,
      placeholder: (context, url) {
        return _buildDefualtAvatar();
      },

      imageBuilder: (context, imageProvider) {
        return CircleAvatar(radius: radius, backgroundImage: imageProvider);
      },

      errorWidget: (context, url, error) {
        return _buildDefualtAvatar();
      },
    );
  }

  Widget _buildDefualtAvatar() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: deepColorBlue, width: 0.5),
        color: mainColorGreenBule40,
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 3), 
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: mainColorGreenBule40,
        radius: radius,
        child: Text(
          "闪",
          style: TextStyle(
            fontSize: radius * 1.4,
            fontWeight: FontWeight.bold,
            fontFamily: "SmileySans",
            color: Colors.white30,
            shadows: const [
              Shadow(offset: Offset(1, 1), color: mainColorPurple),
              Shadow(offset: Offset(-1, -1), color: mainColorPurple),
            ],
          ),
        ),
      ),
    );
  }
}

final defaultAvatar25 = Container(
  alignment: Alignment.center,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: deepColorBlue, width: 0.5),
    color: mainColorGreenBule40,
    boxShadow: [
      const BoxShadow(
        color: Color.fromRGBO(255, 255, 255, 0.2),
        spreadRadius: 1,
        blurRadius: 2,
        offset: Offset(0, 3), // changes position of shadow
      ),
    ],
  ),
  child: const CircleAvatar(
    backgroundColor: mainColorGreenBule40,
    radius: 25,
    child: Text(
      "闪",
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        fontFamily: "SmileySans",
        color: Colors.white30,
        shadows: [
          Shadow(offset: Offset(1, 1), color: mainColorPurple),
          Shadow(offset: Offset(-1, -1), color: mainColorPurple),
        ],
      ),
    ),
  ),
);
final defaultAvatar50 = Container(
  alignment: Alignment.center,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: deepColorBlue, width: 0.5),
    color: mainColorGreenBule40,
    boxShadow: [
      const BoxShadow(
        color: Color.fromRGBO(255, 255, 255, 0.2),
        spreadRadius: 1,
        blurRadius: 2,
        offset: Offset(0, 3), // changes position of shadow
      ),
    ],
  ),
  child: const CircleAvatar(
    backgroundColor: mainColorGreenBule40,
    radius: 50,
    child: Text(
      "闪",
      style: TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        fontFamily: "SmileySans",
        color: Colors.white30,
        shadows: [
          Shadow(offset: Offset(1, 1), color: mainColorPurple),
          Shadow(offset: Offset(-1, -1), color: mainColorPurple),
        ],
      ),
    ),
  ),
);
