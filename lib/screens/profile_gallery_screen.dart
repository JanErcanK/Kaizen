import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_header_logo.dart';
import 'root_shell.dart';

class ProfileGalleryScreen extends StatelessWidget {
  const ProfileGalleryScreen({super.key});

  Future<void> _captureAndSave(BuildContext context) async {
    final l10n = context.l10n;
    if (!Platform.isAndroid && !Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gallery_mobileOnly)),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );
    if (picked == null) return;

    final saved = await _persistGalleryFile(picked);
    if (saved == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gallery_saveFailed)),
      );
      return;
    }

    await ProgressStore.addProfileGalleryItem(
      path: saved,
      createdAt: DateTime.now(),
    );
  }

  Future<String?> _persistGalleryFile(XFile picked) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final galleryDir = Directory('${dir.path}/Kaizen/gallery');
      if (!galleryDir.existsSync()) {
        galleryDir.createSync(recursive: true);
      }
      final ext = picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final target = File('${galleryDir.path}/me_$stamp.$ext');
      await File(picked.path).copy(target.path);
      return target.path;
    } catch (_) {
      return null;
    }
  }

  Widget _buildNavBar(BuildContext context) {
    return AppBottomNavBar(
      selectedIndex: 1,
      onDestinationSelected: (index) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        RootShell.selectedTab.value = index;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildNavBar(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.actionBackground,
        foregroundColor: AppColors.onAction,
        onPressed: () => _captureAndSave(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: ProgressStore.listenable(),
          builder: (context, tick, child) {
            final items = ProgressStore.profileGalleryItems;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeaderLogo(),
                  const SizedBox(height: 10),
                  Text(
                    l10n.gallery_title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.gallery_empty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontFamily: 'Roboto',
                            height: 1.35,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.86,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final path = item['path'].toString();
                          final createdAt =
                              DateTime.tryParse(item['createdAt'].toString());
                          final label = createdAt == null
                              ? '--'
                              : '${createdAt.day.toString().padLeft(2, '0')}.'
                                  '${createdAt.month.toString().padLeft(2, '0')}.'
                                  '${createdAt.year}';

                          final file = File(path);
                          return Container(
                            decoration: AppColors.surfaceDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: file.existsSync()
                                      ? Image.file(file, fit: BoxFit.cover)
                                      : Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: AppColors.stroke),
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
