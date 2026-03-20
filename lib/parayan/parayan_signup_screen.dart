import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class ParayanSignupScreen extends StatefulWidget {
  final ParayanEvent event;

  const ParayanSignupScreen({super.key, required this.event});

  @override
  State<ParayanSignupScreen> createState() => _ParayanSignupScreenState();
}

class _ParayanSignupScreenState extends State<ParayanSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parayanService = ParayanService();

  final List<TextEditingController> _nameControllers = [TextEditingController()];
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _addNameField() {
    setState(() {
      _nameControllers.add(TextEditingController());
    });
  }

  void _removeNameField(int index) {
    if (_nameControllers.length > 1) {
      setState(() {
        _nameControllers[index].dispose();
        _nameControllers.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceInfo = DeviceInfoPlugin();
      String? deviceId;
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }

      if (deviceId == null) {
        throw Exception("Could not determine device ID");
      }

      final names = _nameControllers
          .map((c) => c.text.trim())
          .where((name) => name.isNotEmpty)
          .toList();

      if (names.isEmpty) {
        throw Exception("Please enter at least one name");
      }

      await _parayanService.enrollParticipants(
        eventId: widget.event.id,
        type: widget.event.type,
        deviceId: deviceId,
        names: names,
        email: _emailController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;

      // Navigate to confirmation
      Navigator.pop(context, true);
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.parayanJoinedSuccess)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (localizations == null) return const SizedBox.shrink();

    final isMarathi = localizations.localeName == 'mr';

    return Scaffold(
      appBar: AppBar(title: Text(localizations.joinParayanLabel)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    isMarathi ? widget.event.titleMr : widget.event.titleEn,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMarathi
                        ? widget.event.descriptionMr
                        : widget.event.descriptionEn,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Household Members Header
                  Row(
                    children: [
                      Text(
                        isMarathi ? "कुटुंबातील सदस्य" : "Household Members",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addNameField,
                        icon: const Icon(Icons.add),
                        label: Text(isMarathi ? "जोडा" : "Add"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Name fields
                  ..._nameControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: "${localizations.name} ${index + 1}",
                                icon: const Icon(Icons.person),
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? localizations.parayanNameRequired
                                  : null,
                            ),
                          ),
                          if (_nameControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeNameField(index),
                              padding: const EdgeInsets.only(top: 12),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      icon: const Icon(Icons.email),
                      hintText: isMarathi ? "उदा. seva@example.com" : "e.g. seva@example.com",
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.emailRequired;
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return localizations.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: isMarathi ? "फोन नंबर" : "Phone Number",
                      icon: const Icon(Icons.phone),
                      hintText: isMarathi ? "१०-अंकी नंबर" : "10-digit number",
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.phoneRequired;
                      }
                      final phoneRegex = RegExp(r'^[0-9]{10}$');
                      if (!phoneRegex.hasMatch(value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                        return localizations.invalidPhone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(localizations.joinParayanLabel),
                  ),
                ],
              ),
            ),
    );
  }
}
