import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/avatar_data.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';

class AvatarPickerModal extends StatelessWidget {
  const AvatarPickerModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AvatarPickerModal(),
    );
  }

  Future<void> _pickCustomPhoto(BuildContext context, AppState appState) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final safeExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext) ? ext : 'png';

      final success = await appState.uploadAndSetCustomAvatar(bytes, safeExt);
      if (context.mounted) {
        Navigator.of(context).pop();
        if (success) {
          AudioService.playReward();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xff059669),
              content: Text(
                appState.language == 'en'
                    ? "Profile photo updated successfully!"
                    : "Foto profil berhasil diperbarui!",
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context);
    final isEn = appState.language == 'en';
    final String currentAvatar = appState.userAvatar;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0f172a) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: const Color(0xff10b981),
            width: 2.0,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xffcbd5e1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isEn ? "CHOOSE TRADER AVATAR 🎭" : "PILIH AVATAR TRADER 🎭",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xff0f172a),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEn
                ? "Select your 3D character avatar for your profile identity!"
                : "Pilih karakter avatar 3D favorit untuk identitas profil Anda!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
            ),
          ),
          const SizedBox(height: 16),

          // Avatar Grid 3-column scrollable
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.82,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: AvatarData.avatars.length,
              itemBuilder: (context, idx) {
                final av = AvatarData.avatars[idx];
                final bool isSelected = currentAvatar == av.id;

                return GestureDetector(
                  onTap: () {
                    AudioService.playReward();
                    appState.updateAvatar(av.id);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xff059669),
                        content: Text(
                          isEn
                              ? "Avatar changed to ${av.getTitle('en')}! 🎭"
                              : "Avatar berhasil diubah menjadi ${av.getTitle('id')}! 🎭",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                          : (isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? av.color
                            : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0)),
                        width: isSelected ? 2.2 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: av.color.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: av.color.withOpacity(0.18),
                            border: Border.all(color: av.color.withOpacity(0.4), width: 1.5),
                          ),
                          child: Icon(av.icon, color: av.color, size: 28),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          av.getTitle(isEn ? 'en' : 'id'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xff065f46))
                                : (isDark ? const Color(0xffcbd5e1) : const Color(0xff334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Upload custom photo button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: BorderSide(
                color: isDark ? const Color(0xff3b82f6) : const Color(0xff2563eb),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _pickCustomPhoto(context, appState),
            icon: Icon(
              Icons.add_photo_alternate_rounded,
              size: 18,
              color: isDark ? const Color(0xff60a5fa) : const Color(0xff2563eb),
            ),
            label: Text(
              isEn ? "UPLOAD CUSTOM PHOTO" : "UNGGAH FOTO DARI GALERI",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xff60a5fa) : const Color(0xff2563eb),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
