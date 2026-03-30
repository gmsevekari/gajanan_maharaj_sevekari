import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';

class MyPlaylistsScreen extends StatelessWidget {
  const MyPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.favorites),
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
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    playlist.isDefault
                        ? localizations.myFavorites
                        : playlist.name,
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
                        _formatNumber(context, playlist.aartiIds.length),
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
                                playlist.name,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.grey,
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
                      Routes.playlistDetail,
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

  String _formatNumber(BuildContext context, int number) {
    String numStr = number.toString();
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    if (!isMarathi) return numStr;

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], marathi[i]);
    }
    return numStr;
  }
}
