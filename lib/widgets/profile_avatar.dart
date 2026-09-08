import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_feedback.dart';
import '../services/app_state.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key, required this.state});
  final AppState state;
  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? bytes;
  bool busy = false;
  String get cacheKey => 'profile.avatar.${widget.state.session?.uid}';
  bool get connected => widget.state.session?.anonymous == false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!connected) return;
    try {
      final cached = await widget.state.store.loadJson(cacheKey);
      if (cached is String && cached.isNotEmpty && mounted) {
        setState(() => bytes = base64Decode(cached));
      }
      final data = await widget.state.api.authenticated('/api/mobile/avatar');
      final image = '${data['image'] ?? ''}';
      if (mounted) {
        setState(() => bytes = image.isEmpty ? null : base64Decode(image));
      }
      await widget.state.store.saveJson(cacheKey, image);
    } catch (_) {
      /* The saved avatar remains available offline. */
    }
  }

  Future<void> change() async {
    if (!connected || busy) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir une photo'),
                onTap: () => Navigator.pop(context, 'choose'),
              ),
              if (bytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Revenir à l’avatar de lecteur'),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() => busy = true);
    try {
      String image = '';
      if (choice == 'choose') {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 320,
          maxHeight: 320,
          imageQuality: 70,
        );
        if (picked == null) return;
        final data = await picked.readAsBytes();
        if (data.length > 60000) {
          throw const UserMessage(
            'Cette photo est trop lourde. Choisissez une image plus petite.',
          );
        }
        image = base64Encode(data);
      }
      await widget.state.api.authenticated(
        '/api/mobile/avatar',
        method: 'PUT',
        body: {'image': image},
      );
      await widget.state.store.saveJson(cacheKey, image);
      if (mounted) {
        setState(() => bytes = image.isEmpty ? null : base64Decode(image));
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          friendlyFailure(e, action: 'enregistrer votre photo de profil'),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: connected ? 'Modifier ma photo de profil' : 'Avatar de lecteur',
    button: connected,
    child: InkWell(
      onTap: connected ? change : null,
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: 64,
              height: 64,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(),
                    )
                  : bytes == null
                  ? SvgPicture.asset('assets/illustrations/reader-avatar.svg')
                  : Image.memory(bytes!, fit: BoxFit.cover),
            ),
          ),
          if (connected)
            const Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 10,
                child: Icon(Icons.edit, size: 12),
              ),
            ),
        ],
      ),
    ),
  );
}
