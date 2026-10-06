import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_entry_edit_dialog.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';
import 'package:gajanan_maharaj_sevekari/widgets/phone_number_field.dart';

/// What an admin can do to a sign-up's entries - add a devotee to a slot,
/// edit an entry, remove one (after confirming) - shared by
/// [AdminSignupSlotsScreen] and [AdminSignupEntriesScreen]. Each action
/// reports its outcome in a snackbar on the screen whose [BuildContext] it
/// is given, and does nothing once that screen has gone.
class AdminEntryActions {
  final SignupService service;

  const AdminEntryActions(this.service);

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showAddDialog(BuildContext context, Signup signup, SignupSlot slot) {
    final l10n = AppLocalizations.of(context)!;
    showEnglishDialog(
      context: context,
      builder: (_) => SignupEntryEditDialog(
        defaultCountryCode: defaultCountryCodeFor(context, signup.groupId),
        onSave: (details) async {
          try {
            final res = await service.adminAddEntry(
              signupId: signup.id!,
              slotId: slot.id!,
              name: details.name,
              phone: details.phone,
              email: details.email,
              pledgeAmount: details.pledgeAmount,
              note: details.note,
            );
            if (!context.mounted) return null;
            if (res['success'] == true) {
              _snack(context, l10n.signupEntryAddSuccess);
            } else if (res['error'] == 'slot_full') {
              _snack(context, l10n.signupSlotFullError);
            } else {
              _snack(context, l10n.signupEntryAddError);
            }
          } catch (_) {
            if (!context.mounted) return null;
            _snack(context, l10n.signupEntryAddError);
          }
          return null;
        },
      ),
    );
  }

  void showEditDialog(BuildContext context, Signup signup, SignupEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showEnglishDialog(
      context: context,
      builder: (_) => SignupEntryEditDialog(
        defaultCountryCode: defaultCountryCodeFor(context, signup.groupId),
        entry: entry,
        onSave: (details) async {
          try {
            await service.updateEntry(
              signup.id!,
              entry.copyWith(
                name: details.name,
                phone: details.phone,
                email: details.email,
                pledgeAmount: details.pledgeAmount,
                note: details.note,
              ),
            );
            if (!context.mounted) return null;
            _snack(context, l10n.signupEntryEditSuccess);
          } catch (_) {
            if (!context.mounted) return null;
            _snack(context, l10n.signupEntryEditError);
          }
          return null;
        },
        onDelete: () => _remove(context, signup, entry, l10n),
        onReleaseDevice: (entry.deviceId ?? '').isEmpty
            ? null
            : () => _releaseDevice(context, signup, entry, l10n),
      ),
    );
  }

  Future<void> _releaseDevice(
    BuildContext context,
    Signup signup,
    SignupEntry entry,
    AppLocalizations l10n,
  ) async {
    try {
      await service.releaseEntryDevice(signup.id!, entry.id!);
      if (!context.mounted) return;
      _snack(context, l10n.signupReleaseDeviceSuccess);
    } catch (_) {
      if (!context.mounted) return;
      _snack(context, l10n.signupReleaseDeviceError);
    }
  }

  Future<void> _remove(
    BuildContext context,
    Signup signup,
    SignupEntry entry,
    AppLocalizations l10n,
  ) async {
    try {
      await service.adminRemoveEntry(signup.id!, entry.id!);
      if (!context.mounted) return;
      _snack(context, l10n.signupEntryRemoveSuccess);
    } catch (_) {
      if (!context.mounted) return;
      _snack(context, l10n.signupEntryRemoveError);
    }
  }

  void confirmRemove(BuildContext context, Signup signup, SignupEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showEnglishDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupRemoveEntryTitle),
        content: Text(l10n.signupRemoveEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _remove(context, signup, entry, l10n);
            },
            child: Text(
              l10n.yes,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
