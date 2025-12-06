import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itcc/src/data/api_routes/folder_api/folder_api.dart';
import 'package:itcc/src/data/constants/color_constants.dart';
import 'package:itcc/src/data/models/folder_model.dart';
import 'package:itcc/src/data/services/snackbar_service.dart';
import 'package:itcc/src/interface/components/common/custom_video.dart';
import 'package:itcc/src/interface/components/loading_indicator/loading_indicator.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:itcc/src/data/globals.dart' as globals;
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:typed_data';

class FolderViewPage extends ConsumerStatefulWidget {
  final String folderId;
  final String folderName;
  final String eventId;

  const FolderViewPage({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.eventId,
  });

  @override
  ConsumerState<FolderViewPage> createState() => _FolderViewPageState();
}

class _FolderViewPageState extends ConsumerState<FolderViewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteFile(EventFile file) async {
    try {
      await FolderApiService.deleteFilesFromPublicFolder(
        eventId: widget.eventId,
        fileIds: [file.id!],
      );
      // Refresh the folder data
      ref.invalidate(getFilesProvider(folderId: widget.folderId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete file: $e')),
        );
      }
    }
  }

  Widget _buildVideoPlayer(String videoUrl) {
  final ytController = YoutubePlayerController(
    initialVideoId: extractYoutubeId(videoUrl)??'',
    flags: const YoutubePlayerFlags(
      disableDragSeek: true,
      autoPlay: false,
      loop: true,
      mute: false,
      controlsVisibleAtStart: true,
      enableCaption: true,
      isLive: false,
    ),
  );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: ClipRRect(
          child: YoutubePlayer(
            controller: ytController,
            aspectRatio: 16 / 9,
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(EventFile file) {
    return GestureDetector(
      onTap: () => _showImageViewer(file),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                file.url,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (file.user == globals.id)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _showDeleteConfirmation(file),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoItem(EventFile file) {
    return Stack(
      children: [
        _buildVideoPlayer(file.url),
        if (file.user == globals.id)
          Positioned(
            top: 14,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _showDeleteConfirmation(file),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(EventFile file) async {
    final fileType = file.type == 'image' ? 'Image' : 'Video';
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete $fileType',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this $fileType?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFile(file);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.data),
        quality: 100,
        name: 'image_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        SnackbarService snackbarService = SnackbarService();
        snackbarService.showSnackBar('Image saved to gallery');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageViewer(EventFile file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  file.url,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: () => _downloadImage(file.url),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncFolder = ref.watch(getFilesProvider(folderId: widget.folderId));

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        elevation: 0,
        bottom: TabBar(
          enableFeedback: true,
          isScrollable: false,
          indicatorColor: kPrimaryColor,
          indicatorWeight: 3.0,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          controller: _tabController,
          tabs: const [
            Tab(text: 'Images'),
            Tab(text: 'Videos'),
          ],
        ),
        title: Text(
          widget.folderName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: asyncFolder.when(
        loading: () => const Center(child: LoadingAnimation()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (folder) {
          final images = folder.files.where((f) => f.type == 'image').toList();
          final videos = folder.files.where((f) => f.type == 'video').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Images Tab
              GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) => _buildImageItem(images[index]),
              ),

              // Videos Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: videos.length,
                itemBuilder: (context, index) => _buildVideoItem(videos[index]),
              ),
            ],
          );
        },
      ),
    );
  }
}
