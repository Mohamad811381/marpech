// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:marpech/services/localization_service.dart';

double homeLs(double english) => L10n.isFa ? 0.3 : english;
FontStyle get homeItalic => L10n.isFa ? FontStyle.normal : FontStyle.italic;
String homeUpper(String s) => L10n.isFa ? s : s.toUpperCase();