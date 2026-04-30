import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.favorites),
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const ThemedIcon(LogicalIcon.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
          final playlists = playlistProvider.playlists;

          if (playlists.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                elevation: theme.cardTheme.elevation,
                color: theme.cardTheme.color,
                shape: theme.cardTheme.shape,
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      playlist.isDefault ? Icons.favorite : Icons.queue_music,
                      color: playlist.isDefault
                          ? theme.appColors.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    playlist.isDefault
                        ? localizations.myFavorites
                        : Localizations.localeOf(context).localizedContent(playlist.name_en, playlist.name_mr),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatNumberLocalized(playlist.aartiIds.length, Localizations.localeOf(context).languageCode, pad: false),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  trailing: playlist.isDefault
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showRenamePlaylistDialog(
                                context,
                                playlist.id,
                                Localizations.localeOf(context).localizedContent(playlist.name_en, playlist.name_mr),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 20,
                                color: theme.appColors.secondaryText,
                              ),
                              onPressed: () => _deletePlaylist(
                                context,
                                playlist.id,
                                playlistProvider,
                                localizations,
                              ),
                            ),
                          ],
                        ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.favoriteItemList,
                      arguments: playlist.id,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlaylistDialog(context),
        icon: const Icon(Icons.add),
        label: Text(localizations.createPlaylist),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(localizations.createNewPlaylist),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: localizations.playlistName,
                  hintText: localizations.playlistName,
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                  errorMaxLines: 3,
                ),
                maxLength: 50,
                autofocus: true,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) {
                            setDialogState(
                              () => errorText =
                                  localizations.playlistNameRequired,
                            );
                            return;
                          }

                          final nameRegex = RegExp(
                            r'^[\p{L}\p{M}\p{Nd}\s]+$',
                            unicode: true,
                          );
                          if (!nameRegex.hasMatch(name)) {
                            setDialogState(
                              () => errorText =
                                  localizations.playlistNameAlphanumeric,
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);
                          try {
                            await Provider.of<PlaylistProvider>(
                              context,
                              listen: false,
                            ).createPlaylist(name);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(localizations.playlistCreated),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(
                              () => errorText = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              ),
                            );
                          } finally {
                            setDialogState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localizations.createPlaylist),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenamePlaylistDialog(
    BuildContext context,
    String playlistId,
    String currentName,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(localizations.renamePlaylist),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: localizations.playlistName,
                  hintText: localizations.playlistName,
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                  errorMaxLines: 3,
                ),
                maxLength: 50,
                autofocus: true,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) {
                            setDialogState(
                              () => errorText =
                                  localizations.playlistNameRequired,
                            );
                            return;
                          }

                          final nameRegex = RegExp(
                            r'^[\p{L}0-9\u0966-\u096F ]+$',
                            unicode: true,
                          );
                          if (!nameRegex.hasMatch(name)) {
                            setDialogState(
                              () => errorText =
                                  localizations.playlistNameAlphanumeric,
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);
                          try {
                            await Provider.of<PlaylistProvider>(
                              context,
                              listen: false,
                            ).renamePlaylist(playlistId, name);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(localizations.playlistRenamed),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(
                              () => errorText = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              ),
                            );
                          } finally {
                            setDialogState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localizations.renamePlaylist),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deletePlaylist(
    BuildContext context,
    String id,
    PlaylistProvider provider,
    AppLocalizations localizations,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deletePlaylist),
        content: Text(localizations.deletePlaylistConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.ok),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.deletePlaylist(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.playlistDeleted)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
  }

}
