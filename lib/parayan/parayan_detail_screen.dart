import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/parayan/my_allocation_tab.dart';
import 'package:gajanan_maharaj_sevekari/parayan/adhyays_allocation_tab.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_signup_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class ParayanDetailScreen extends StatefulWidget {
  final ParayanEvent event;

  const ParayanDetailScreen({super.key, required this.event});

  @override
  State<ParayanDetailScreen> createState() => _ParayanDetailScreenState();
}

class _ParayanDetailScreenState extends State<ParayanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ParayanService _parayanService = ParayanService();
  String? _deviceId;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String? id;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      id = iosInfo.identifierForVendor;
    }
    setState(() {
      _deviceId = id;
    });
    if (id != null) {
      _checkRegistration(id);
    }
  }

  void _checkRegistration(String deviceId) {
    _parayanService.getParticipant(widget.event.id, deviceId).first.then((p) {
      if (mounted) {
        setState(() {
          _isRegistered = p != null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Localizations.localeOf(context).languageCode == 'mr'
              ? widget.event.titleMr
              : widget.event.titleEn,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.adhyay), // Allocation
            Tab(text: localizations.namjap), // My Allocation
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdhyaysAllocationTab(event: widget.event),
          _deviceId == null
              ? const Center(child: CircularProgressIndicator())
              : MyAllocationTab(event: widget.event, deviceId: _deviceId!),
        ],
      ),
      floatingActionButton: !_isRegistered && widget.event.status == 'upcoming'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ParayanSignupScreen(event: widget.event),
                  ),
                );
                if (result == true && _deviceId != null) {
                  _checkRegistration(_deviceId!);
                }
              },
              label: Text(localizations.joinParayanLabel),
              icon: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}
