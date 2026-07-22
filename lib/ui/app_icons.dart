import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// The v2 icon vocabulary: one semantic name per concept, all drawn from
/// the thin-stroke Lucide set (nothing from the Material font). Screens
/// reference concepts, not glyphs, so the whole identity can be retuned
/// here. Tab-bar destinations additionally get custom-painted glyphs in
/// the ConsoleTabBar; these serve everywhere else.
class AppIcons {
  AppIcons._();

  // Navigation destinations
  static const IconData today = LucideIcons.sun;
  static const IconData focus = LucideIcons.target;
  static const IconData money = LucideIcons.wallet;
  static const IconData time = LucideIcons.timer;
  static const IconData you = LucideIcons.user;

  // Library / features
  static const IconData habits = LucideIcons.checkCircle2;
  static const IconData ideas = LucideIcons.lightbulb;
  static const IconData reminders = LucideIcons.bell;
  static const IconData journal = LucideIcons.penTool;
  static const IconData notes = LucideIcons.fileText;
  static const IconData graph = LucideIcons.network;
  static const IconData review = LucideIcons.calendarCheck;
  static const IconData countdown = LucideIcons.hourglass;
  static const IconData settings = LucideIcons.settings2;
  static const IconData health = LucideIcons.heartPulse;
  static const IconData accounts = LucideIcons.landmark;
  static const IconData recurring = LucideIcons.repeat;

  // Actions
  static const IconData add = LucideIcons.plus;
  static const IconData capture = LucideIcons.plus;
  static const IconData search = LucideIcons.search;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData archive = LucideIcons.archive;
  static const IconData share = LucideIcons.share2;
  static const IconData importIn = LucideIcons.download;
  static const IconData exportOut = LucideIcons.upload;
  static const IconData done = LucideIcons.check;
  static const IconData close = LucideIcons.x;
  static const IconData more = LucideIcons.moreHorizontal;
  static const IconData undo = LucideIcons.undo2;
  static const IconData pin = LucideIcons.pin;

  // Chrome
  static const IconData back = LucideIcons.chevronLeft;
  static const IconData forward = LucideIcons.chevronRight;
  static const IconData expand = LucideIcons.chevronDown;
  static const IconData collapse = LucideIcons.chevronUp;
  static const IconData visibility = LucideIcons.eye;
  static const IconData visibilityOff = LucideIcons.eyeOff;
  static const IconData lock = LucideIcons.lock;
  static const IconData info = LucideIcons.info;
  static const IconData warning = LucideIcons.alertTriangle;

  // Capture inbox
  static const IconData mic = LucideIcons.mic;
  static const IconData image = LucideIcons.imagePlus;
  static const IconData send = LucideIcons.arrowUp;
  static const IconData sparkle = LucideIcons.sparkles;
  static const IconData paste = LucideIcons.clipboard;
}
