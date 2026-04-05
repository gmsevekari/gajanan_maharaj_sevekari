import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:provider/provider.dart';

enum LogicalIcon {
  home,
  stotras,
  play,
  calendar,
  events,
  favorites,
  notifications,
  search,
  settings,
  donations,
  about,
}

class ThemedIcon extends StatelessWidget {
  final LogicalIcon logicalIcon;
  final double? size;
  final Color? color;
  final IconData? fallbackIcon;
  final String? defaultImagePath;

  const ThemedIcon(
    this.logicalIcon, {
    super.key,
    this.size,
    this.color,
    this.fallbackIcon,
    this.defaultImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final festivalProvider = Provider.of<FestivalProvider>(context);
    final activeFestivalId = festivalProvider.activeFestival?.id;

    if (activeFestivalId == 'ganesh_chaturthi') {
      return _buildGaneshChaturthiIcon(context);
    } else if (activeFestivalId == 'diwali') {
      return _buildDiwaliIcon(context);
    }

    // Default mappings
    if (defaultImagePath != null) {
      return Image.asset(
        defaultImagePath!,
        height: size ?? 24.0,
        width: size ?? 24.0,
      );
    }
    return Icon(_getDefaultIcon(), size: size, color: color);
  }

  IconData _getDefaultIcon() {
    if (fallbackIcon != null) return fallbackIcon!;
    switch (logicalIcon) {
      case LogicalIcon.home:
        return Icons.home;
      case LogicalIcon.stotras:
        return Icons.menu_book;
      case LogicalIcon.play:
        return Icons.play_circle_fill;
      case LogicalIcon.calendar:
        return Icons.calendar_month;
      case LogicalIcon.events:
        return Icons.event;
      case LogicalIcon.favorites:
        return Icons.favorite;
      case LogicalIcon.notifications:
        return Icons.notifications;
      case LogicalIcon.search:
        return Icons.search;
      case LogicalIcon.settings:
        return Icons.settings;
      case LogicalIcon.donations:
        return Icons.volunteer_activism;
      case LogicalIcon.about:
        return Icons.info;
    }
  }

  Widget _buildGaneshChaturthiIcon(BuildContext context) {
    final effectiveSize = size ?? Theme.of(context).iconTheme.size ?? 24.0;
    
    String fullPath = 'resources/images/festive/ganesh_donations.png'; // Fallback
    switch (logicalIcon) {
      case LogicalIcon.home:
        fullPath = 'resources/images/festive_icons/ganesh_chaturthi/home.png';
        break;
      case LogicalIcon.stotras:
        fullPath = 'resources/images/festive/ganesh_stotras.png';
        break;
      case LogicalIcon.play:
        fullPath = 'resources/images/festive/ganesh_tour.png';
        break;
      case LogicalIcon.calendar:
        fullPath = 'resources/images/festive_icons/ganesh_chaturthi/calendar.png';
        break;
      case LogicalIcon.events:
        fullPath = 'resources/images/festive/ganesh_events.png';
        break;
      case LogicalIcon.favorites:
        fullPath = 'resources/images/festive/ganesh_favorites.png';
        break;
      case LogicalIcon.donations:
        fullPath = 'resources/images/festive/ganesh_drum.png';
        break;
      case LogicalIcon.about:
        fullPath = 'resources/images/festive/ganesh_about.png';
        break;
      case LogicalIcon.notifications:
        fullPath = 'resources/images/festive_icons/ganesh_chaturthi/notifications.png';
        break;
      case LogicalIcon.search:
        fullPath = 'resources/images/festive_icons/ganesh_chaturthi/search.png';
        break;
      case LogicalIcon.settings:
        fullPath = 'resources/images/festive_icons/ganesh_chaturthi/settings.png';
    }

    return Image.asset(
      fullPath,
      width: effectiveSize * 1.6,
      height: effectiveSize * 1.6,
      errorBuilder: (context, error, stackTrace) => Icon(
        _getDefaultIcon(),
        size: effectiveSize,
        color: color ?? IconTheme.of(context).color,
      ),
    );
  }

  Widget _buildDiwaliIcon(BuildContext context) {
    final effectiveSize = size ?? Theme.of(context).iconTheme.size ?? 24.0;
    
    String? fullPath;
    switch (logicalIcon) {
      case LogicalIcon.home:
        fullPath = 'resources/images/festive_icons/diwali/home.png';
        break;
      case LogicalIcon.calendar:
        fullPath = 'resources/images/festive_icons/diwali/calendar.png';
        break;
      case LogicalIcon.notifications:
        fullPath = 'resources/images/festive_icons/diwali/notifications.png';
        break;
      case LogicalIcon.search:
        fullPath = 'resources/images/festive_icons/diwali/search.png';
        break;
      case LogicalIcon.settings:
        fullPath = 'resources/images/festive_icons/diwali/settings.png';
        break;
      default:
        // For anything not customized for diwali, gracefully fallback
        break;
    }

    if (fullPath != null) {
      return Image.asset(
        fullPath,
        width: effectiveSize * 1.6,
        height: effectiveSize * 1.6,
        errorBuilder: (context, error, stackTrace) => Icon(
          _getDefaultIcon(),
          size: effectiveSize,
          color: color ?? IconTheme.of(context).color,
        ),
      );
    }

    return Icon(
      _getDefaultIcon(),
      size: effectiveSize,
      color: color ?? IconTheme.of(context).color,
    );
  }
}
