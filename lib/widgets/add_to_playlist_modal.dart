import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:provider/provider.dart';

class AddToPlaylistModal extends StatelessWidget {
  final String aartiId;

  const AddToPlaylistModal({super.key, required this.aartiId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        final playlists = playlistProvider.playlists;
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.addToPlaylist,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final isAdded = playlist.aartiIds.contains(aartiId);
                    
                    return CheckboxListTile(
                      title: Text(playlist.isDefault ? localizations.myFavorites : playlist.name),
                      value: isAdded,
                      onChanged: (bool? value) {
                        if (value == true) {
                          playlistProvider.addAarti(playlist.id, aartiId);
                        } else {
                          playlistProvider.removeAarti(playlist.id, aartiId);
                        }
                      },
                      secondary: Icon(
                        playlist.isDefault ? Icons.favorite : Icons.queue_music,
                        color: playlist.isDefault ? Colors.red : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(localizations.createNewPlaylist),
                      onPressed: () => _showCreatePlaylistDialog(context, playlistProvider, localizations),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, PlaylistProvider provider, AppLocalizations localizations) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.createNewPlaylist),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: localizations.playlistName),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await provider.createPlaylist(name);
                    // Get newly created playlist (it's the last one)
                    final newPlaylist = provider.playlists.last;
                    await provider.addAarti(newPlaylist.id, aartiId);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext); // close dialog
                    }
                  } catch (e) {
                     if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                     }
                  }
                }
              },
              child: Text(localizations.createPlaylist),
            ),
          ],
        );
      },
    );
  }
}

void showAddToPlaylistModal(BuildContext context, String aartiId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddToPlaylistModal(aartiId: aartiId),
      );
    },
  );
}
