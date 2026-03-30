import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';

class ParayanAdminAddParticipantsScreen extends StatefulWidget {
  final ParayanEvent event;

  const ParayanAdminAddParticipantsScreen({super.key, required this.event});

  @override
  State<ParayanAdminAddParticipantsScreen> createState() =>
      _ParayanAdminAddParticipantsScreenState();
}

class _GroupData {
  final TextEditingController phoneController = TextEditingController();
  final List<TextEditingController> nameControllers = [TextEditingController()];
  String selectedCountryCode = '+1';
}

class _ParayanAdminAddParticipantsScreenState
    extends State<ParayanAdminAddParticipantsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_GroupData> _groups = [_GroupData()];
  final ParayanService _parayanService = ParayanService();
  bool _isSubmitting = false;

  void _addGroup() {
    setState(() {
      _groups.add(_GroupData());
    });
  }

  void _removeGroup(int index) {
    setState(() {
      _groups.removeAt(index);
    });
  }

  void _addName(int groupIndex) {
    if (_groups[groupIndex].nameControllers.length < 5) {
      setState(() {
        _groups[groupIndex].nameControllers.add(TextEditingController());
      });
    }
  }

  void _removeName(int groupIndex, int nameIndex) {
    if (_groups[groupIndex].nameControllers.length > 1) {
      setState(() {
        _groups[groupIndex].nameControllers.removeAt(nameIndex);
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> groupsToUpload = _groups.map((g) {
        return {
          'phone': '${g.selectedCountryCode} ${g.phoneController.text.trim()}',
          'names': g.nameControllers
              .map((c) => c.text.trim())
              .where((n) => n.isNotEmpty)
              .toList(),
        };
      }).toList();

      await _parayanService.adminAddParticipants(
        eventId: widget.event.id,
        groups: groupsToUpload,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.participantsAddedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding participants: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    for (var group in _groups) {
      group.phoneController.dispose();
      for (var controller in group.nameControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addParticipantLabel)),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _groups.length + 1,
                itemBuilder: (context, index) {
                  if (index == _groups.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _addGroup,
                            icon: const Icon(Icons.add_home),
                            label: Text(l10n.addHousehold),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(l10n.submitAll),
                          ),
                        ],
                      ),
                    );
                  }

                  final group = _groups[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${l10n.householdLabel} ${index + 1}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              if (_groups.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeGroup(index),
                                ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: group.phoneController,
                            decoration: InputDecoration(
                              labelText: l10n.phoneNumberLabel,
                              prefixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 8),
                                  const Icon(Icons.phone),
                                  const SizedBox(width: 4),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: group.selectedCountryCode,
                                      items: ['+91', '+1', '+44', '+61', '+971']
                                          .map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          })
                                          .toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            group.selectedCountryCode =
                                                newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.phoneRequired;
                              }
                              if (!RegExp(
                                r'^[0-9]{10}$',
                              ).hasMatch(value.trim())) {
                                return l10n.invalidPhone;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ...group.nameControllers.asMap().entries.map((entry) {
                            final nameIndex = entry.key;
                            final controller = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        labelText:
                                            '${l10n.name} ${nameIndex + 1}',
                                        prefixIcon: const Icon(Icons.person),
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return l10n.parayanNameRequired;
                                        }
                                        final nameRegex = RegExp(
                                          r'^[\p{L}\p{M}\p{Nd}\s]+$',
                                          unicode: true,
                                        );
                                        if (!nameRegex.hasMatch(value.trim())) {
                                          return l10n.nameAlphabetRegexError;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (group.nameControllers.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _removeName(index, nameIndex),
                                      padding: const EdgeInsets.only(top: 12),
                                    ),
                                ],
                              ),
                            );
                          }),
                          if (group.nameControllers.length < 5)
                            TextButton.icon(
                              onPressed: () => _addName(index),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addParticipant),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
