import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/shared/story_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

enum StoryListMode { deity, category, group, file }

class StoryListScreen extends StatefulWidget {
  final String storyType;
  final StoryListMode mode;
  final DeityConfig? deity;
  final StoryCategory? category;
  final StoryGroup? group;

  const StoryListScreen({
    super.key,
    required this.storyType,
    this.mode = StoryListMode.deity,
    this.deity,
    this.category,
    this.group,
  });

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  Future<List<Map<String, String>>>? _fileListFuture;
  Future<List<_GroupData>>? _allGroupsMetadataFuture;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final deity = widget.deity;
    final config = deity?.nityopasana.kidsStories?[widget.storyType];

    if (widget.mode == StoryListMode.file && config != null) {
      setState(() {
        _fileListFuture = _loadFilesMetadata(parentConfig: config);
      });
    } else if (widget.mode == StoryListMode.group && config != null) {
      setState(() {
        _allGroupsMetadataFuture = _loadGroupsMetadata(config);
      });
    }
  }

  Future<List<Map<String, String>>> _loadFilesMetadata({
    StoryGroup? specificGroup,
    StoriesConfig? parentConfig,
  }) async {
    final List<Map<String, String>> results = [];
    final category = widget.category;
    final group = specificGroup ?? widget.group;
    final files = group?.files ?? category?.files ?? parentConfig?.files ?? [];

    final textDir = group?.textResourceDirectory ??
        category?.textResourceDirectory ??
        parentConfig?.textResourceDirectory ??
        '';
    final imageDir = group?.imageResourceDirectory ??
        category?.imageResourceDirectory ??
        parentConfig?.imageResourceDirectory ??
        '';

    for (var fileItem in files) {
      final path = '$textDir/${fileItem.file}';
      try {
        final jsonString = await rootBundle.loadString(path);
        final data = json.decode(jsonString);

        results.add({
          'title_en': data['title_en'] ?? '',
          'title_mr': data['title_mr'] ?? '',
          'assetPath': path,
          'imagePath': fileItem.image?.isNotEmpty == true
              ? '$imageDir/${fileItem.image}'
              : 'resources/images/gajanan_maharaj/aartis/event/placeholder.png', // Fallback
        });
      } catch (e) {
        debugPrint('Error loading story file metadata: $path, $e');
      }
    }
    return results;
  }

  Future<List<_GroupData>> _loadGroupsMetadata(StoriesConfig config) async {
    final groups = config.groups ?? widget.category?.groups ?? [];

    final List<Future<_GroupData>> futures = groups.map((group) async {
      final filesMetadata = await _loadFilesMetadata(
        specificGroup: group,
        parentConfig: config,
      );
      return _GroupData(group: group, files: filesMetadata);
    }).toList();

    return Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = Localizations.localeOf(context).useMarathiContent;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(localizations, isMarathi)),
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
      body: _buildBody(context, theme, isMarathi),
    );
  }

  String _getTitle(AppLocalizations localizations, bool isMarathi) {
    if (widget.group != null) {
      return isMarathi ? widget.group!.titleMr : widget.group!.titleEn;
    }
    if (widget.category != null) {
      return isMarathi ? widget.category!.titleMr : widget.category!.titleEn;
    }

    // Default to the story type title if no specific group or category is provided
    switch (widget.storyType) {
      case 'videos':
        return localizations.videosTitle;
      case 'audios':
        return localizations.audiosTitle;
      case 'stories':
        return localizations.storiesTitle;
      default:
        return localizations.homeStoriesTitle;
    }
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isMarathi) {
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    if (widget.mode == StoryListMode.deity) {
      final deitiesWithContent =
          appConfigProvider.appConfig?.deities.where((d) {
            final config = d.nityopasana.kidsStories?[widget.storyType];
            return config?.hasContent ?? false;
          }).toList() ??
          [];
      return _buildDeityList(deitiesWithContent, theme, isMarathi);
    }

    switch (widget.mode) {
      case StoryListMode.category:
        final config = widget.deity!.nityopasana.kidsStories![widget.storyType]!;
        final categories = config.categories ?? [];
        return _buildCategoryList(categories, theme, isMarathi);

      case StoryListMode.group:
        return _buildGroupedFileList(theme, isMarathi);

      case StoryListMode.file:
        return _buildFileList(theme, isMarathi);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDeityList(
    List<DeityConfig> deities,
    ThemeData theme,
    bool isMarathi,
  ) {
    if (deities.isEmpty) {
      return const Center(child: Text('No deities found for this story type'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deities.length,
      itemBuilder: (context, index) {
        final deity = deities[index];
        final stories = deity.nityopasana.kidsStories![widget.storyType]!;
        final imagePath =
            deity.imagePath.startsWith('resources/')
                ? deity.imagePath
                : 'resources/images/deity/${deity.imagePath}';
        final count =
            stories.isCategorized
                ? stories.categories?.length ?? 0
                : (stories.isGrouped
                    ? stories.groups?.length ?? 0
                    : (stories.files?.isNotEmpty == true
                        ? stories.files!.length
                        : stories.items?.length ?? 0));

        return _buildStandardCard(
          theme: theme,
          title: isMarathi ? deity.nameMr : deity.nameEn,
          subtitle:
              '${isMarathi ? toMarathiNumerals(count.toString()) : count} ${stories.isCategorized ? "Categories" : (stories.isGrouped ? "Adhyays" : "Items")}',
          imagePath: deity.imagePath,
          showImage: true,
          onTap: () {
            if (stories.isCategorized) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryListScreen(
                    storyType: widget.storyType,
                    mode: StoryListMode.category,
                    deity: deity,
                  ),
                ),
              );
            } else if (stories.isGrouped) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryListScreen(
                    storyType: widget.storyType,
                    mode: StoryListMode.group,
                    deity: deity,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryListScreen(
                    storyType: widget.storyType,
                    mode: StoryListMode.file,
                    deity: deity,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildCategoryList(
    List<StoryCategory> categories,
    ThemeData theme,
    bool isMarathi,
  ) {
    if (categories.isEmpty)
      return const Center(child: Text('No categories found.'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = category.files.length.toString();
        return _buildStandardCard(
          theme: theme,
          title: isMarathi ? category.titleMr : category.titleEn,
          subtitle: '${isMarathi ? toMarathiNumerals(count) : count} Chapters',
          imagePath: null,
          showImage: false,
          onTap: () {
            if (category.groups != null && category.groups!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryListScreen(
                    storyType: widget.storyType,
                    mode: StoryListMode.group,
                    deity: widget.deity,
                    category: category,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryListScreen(
                    storyType: widget.storyType,
                    mode: StoryListMode.file,
                    deity: widget.deity,
                    category: category,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildGroupedFileList(ThemeData theme, bool isMarathi) {
    return FutureBuilder<List<_GroupData>>(
      future: _allGroupsMetadataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading chapters.'));
        }

        final groupDataList = snapshot.data!;
        if (groupDataList.isEmpty) {
          return const Center(child: Text('No groups found.'));
        }

        // Flatten all files into a single list for continuous navigation
        final List<Map<String, String>> allFilesMetadata =
            groupDataList.expand((g) => g.files).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 100),
          itemCount: groupDataList.length,
          itemBuilder: (context, gIndex) {
            final groupData = groupDataList[gIndex];

            // Calculate the absolute starting index for this group in the flattened list
            int absoluteStartIndex = 0;
            for (int i = 0; i < gIndex; i++) {
              absoluteStartIndex += groupDataList[i].files.length;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  theme,
                  isMarathi ? groupData.group.titleMr : groupData.group.titleEn,
                ),
                ...List.generate(groupData.files.length, (fIndex) {
                  final fileData = groupData.files[fIndex];
                  final absoluteIndex = absoluteStartIndex + fIndex;

                  return _buildStandardCard(
                    theme: theme,
                    title: isMarathi
                        ? (fileData['title_mr'] ?? '')
                        : (fileData['title_en'] ?? ''),
                    imagePath: null,
                    showImage: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryDetailScreen(
                            deity: widget.deity!,
                            contentList: allFilesMetadata,
                            currentIndex: absoluteIndex,
                            assetPath: fileData['assetPath']!,
                            imagePath: fileData['imagePath']!,
                            storyType: widget.storyType,
                          ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(ThemeData theme, bool isMarathi) {
    return FutureBuilder<List<Map<String, String>>>(
      future: _fileListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading chapters.'));
        }

        final files = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 100),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final fileData = files[index];
            return _buildStandardCard(
              theme: theme,
              title:
                  isMarathi
                      ? (fileData['title_mr'] ?? '')
                      : (fileData['title_en'] ?? ''),
              imagePath: fileData['imagePath'],
              showImage: true,
              index: index + 1, // Add index for text stories
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryDetailScreen(
                      deity: widget.deity!,
                      contentList: files,
                      currentIndex: index,
                      assetPath: fileData['assetPath']!,
                      imagePath: fileData['imagePath']!,
                      storyType: widget.storyType,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStandardCard({
    required ThemeData theme,
    required String title,
    String? subtitle,
    String? imagePath,
    bool showImage = false,
    int? index,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading:
            index != null
                ? CircleAvatar(
                  backgroundColor: theme.appColors.primarySwatch.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : (showImage && imagePath != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        imagePath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: 50,
                              height: 50,
                              color: theme.appColors.primarySwatch.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.appColors.primarySwatch,
                              ),
                            ),
                      ),
                    )
                    : null),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: theme.appColors.primarySwatch.withValues(alpha: 0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
class _GroupData {
  final StoryGroup group;
  final List<Map<String, String>> files;

  _GroupData({required this.group, required this.files});
}
