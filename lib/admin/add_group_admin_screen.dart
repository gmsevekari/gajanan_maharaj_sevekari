import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_management_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';

class AddGroupAdminScreen extends StatefulWidget {
  final AdminUser currentAdmin;
  final AdminManagementService? managementService;

  const AddGroupAdminScreen({
    super.key,
    required this.currentAdmin,
    this.managementService,
  });

  @override
  State<AddGroupAdminScreen> createState() => _AddGroupAdminScreenState();
}

class _AddGroupAdminScreenState extends State<AddGroupAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final Set<String> _selectedRoles = {};
  String? _selectedGroupId;
  bool _isLoading = false;
  late final AdminManagementService _managementService;

  @override
  void initState() {
    super.initState();
    _managementService = widget.managementService ?? AdminManagementService();
    if (!_isSuperAdmin) {
      _selectedGroupId = widget.currentAdmin.groupId;
    }
  }

  bool get _isSuperAdmin => widget.currentAdmin.roles.contains('super_admin');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final email = _emailController.text.trim();
        final exists = await _managementService.isAdminExists(email);
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin with this email already exists'),
              ),
            );
          }
          return;
        }

        final newAdmin = AdminUser(
          email: email,
          roles: _selectedRoles.toList(),
          groupId: _selectedGroupId,
        );

        await _managementService.saveAdmin(newAdmin);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin added successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appConfig = context.watch<AppConfigProvider>().appConfig;
    final groups = appConfig?.gajananMaharajGroups ?? [];
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';

    final currentGroup = groups.firstWhere(
      (g) => g.id == widget.currentAdmin.groupId,
      orElse: () => GajananMaharajGroup(
        id: widget.currentAdmin.groupId ?? '',
        nameEn: widget.currentAdmin.groupId ?? '',
        nameMr: widget.currentAdmin.groupId ?? '',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.addGroupAdminTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isSuperAdmin && widget.currentAdmin.groupId != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: theme.cardTheme.elevation,
                color: theme.cardTheme.color,
                shape: theme.cardTheme.shape,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.groups,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${localizations.adminGroupLabel}:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.appColors.secondaryText,
                              ),
                            ),
                            Text(
                              widget.currentAdmin.groupId ?? '',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.appColors.primarySwatch[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: theme.cardTheme.elevation,
                shape: theme.cardTheme.shape,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: localizations.adminEmailLabel,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.emailRequired;
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return localizations.invalidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, localizations.rolesLabel),
                        _buildRoleCheckbox(
                          context,
                          localizations.roleSuperAdmin,
                          _selectedRoles.contains('super_admin'),
                          _isSuperAdmin
                              ? (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedRoles.add('super_admin');
                                    } else {
                                      _selectedRoles.remove('super_admin');
                                    }
                                  });
                                }
                              : null,
                        ),
                        _buildRoleCheckbox(
                          context,
                          localizations.roleGroupAdmin,
                          _selectedRoles.contains('group_admin'),
                          (value) {
                            setState(() {
                              if (value == true) {
                                _selectedRoles.add('group_admin');
                              } else {
                                _selectedRoles.remove('group_admin');
                                _selectedGroupId = null;
                              }
                            });
                          },
                        ),
                        _buildRoleCheckbox(
                          context,
                          localizations.roleParayanCoordinator,
                          _selectedRoles.contains('parayan_coordinator'),
                          (value) {
                            setState(() {
                              if (value == true) {
                                _selectedRoles.add('parayan_coordinator');
                              } else {
                                _selectedRoles.remove('parayan_coordinator');
                              }
                            });
                          },
                        ),
                        _buildRoleCheckbox(
                          context,
                          localizations.roleNamjapCoordinator,
                          _selectedRoles.contains('namjap_coordinator'),
                          (value) {
                            setState(() {
                              if (value == true) {
                                _selectedRoles.add('namjap_coordinator');
                              } else {
                                _selectedRoles.remove('namjap_coordinator');
                              }
                            });
                          },
                        ),
                        FormField<Set<String>>(
                          validator: (value) {
                            if (_selectedRoles.isEmpty) {
                              return localizations.atLeastOneRoleRequired;
                            }
                            return null;
                          },
                          builder: (state) {
                            if (state.hasError) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        if (_selectedRoles.contains('group_admin') &&
                            _isSuperAdmin) ...[
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _selectedGroupId,
                            decoration: InputDecoration(
                              labelText: localizations.selectGroupLabel,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.group_outlined),
                            ),
                            items: groups.map((group) {
                              return DropdownMenuItem(
                                value: group.id,
                                child: Text(
                                  isMarathi ? group.nameMr : group.nameEn,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGroupId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.groupRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  localizations.addAdminButton.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRoleCheckbox(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool?>? onChanged,
  ) {
    final theme = Theme.of(context);
    return CheckboxListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: onChanged == null ? theme.disabledColor : null,
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: theme.colorScheme.primary,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
      enabled: onChanged != null,
    );
  }
}
