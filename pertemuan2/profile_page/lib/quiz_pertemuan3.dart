import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ============================================================
// HELPER: tampilkan gambar dari XFile (support Web & Mobile)
// ============================================================

class _XImageHolder {
  final String? path;       // mobile
  final Uint8List? bytes;   // web

  const _XImageHolder({this.path, this.bytes});

  bool get hasImage => bytes != null || path != null;

  Widget toImage({double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (bytes != null) {
      return Image.memory(bytes!, width: width, height: height, fit: fit);
    }
    if (path != null) {
      return Image.file(File(path!), width: width, height: height, fit: fit);
    }
    return const SizedBox.shrink();
  }

  Widget toCircleAvatar({double radius = 50}) {
    if (bytes != null) {
      return CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes!));
    }
    if (path != null) {
      return CircleAvatar(radius: radius, backgroundImage: FileImage(File(path!)));
    }
    return CircleAvatar(radius: radius);
  }
}

Future<_XImageHolder?> _pickImageCrossPlatform(ImagePicker picker) async {
  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  if (picked == null) return null;
  if (kIsWeb) {
    final bytes = await picked.readAsBytes();
    return _XImageHolder(bytes: bytes);
  }
  return _XImageHolder(path: picked.path);
}

// ============================================================
// MODEL
// ============================================================

class ProfileData {
  String name;
  String bio;
  String education;
  String location;
  String contact;
  List<String> skills;
  _XImageHolder? avatar;

  ProfileData({
    required this.name,
    required this.bio,
    required this.education,
    required this.location,
    required this.contact,
    required this.skills,
    this.avatar,
  });
}

class ExperienceData {
  String title;
  String description;
  _XImageHolder? image;

  ExperienceData({
    required this.title,
    required this.description,
    this.image,
  });
}

// ============================================================
// HALAMAN UTAMA
// ============================================================

class ProfilePageV3 extends StatefulWidget {
  const ProfilePageV3({super.key});

  @override
  State<ProfilePageV3> createState() => _ProfilePageV3State();
}

class _ProfilePageV3State extends State<ProfilePageV3> {
  ProfileData _profile = ProfileData(
    name: 'Muhammad Rafly Alfarizi',
    bio: 'Saya suka belajar hal baru, terutama yang berkaitan '
        'dengan teknologi dan pengembangan aplikasi mobile.',
    education: 'Universitas Pasundan — Semester 8\nIPK: 3.75',
    location: 'Bandung, Jawa Barat',
    contact: 'rafly.223040043@mail.unpas.ac.id',
    skills: ['Flutter', 'Dart', 'Firebase', 'UI/UX', 'Git'],
  );

  final List<ExperienceData> _experiences = [];

  Future<void> _goToEditProfile() async {
    final updated = await Navigator.push<ProfileData>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: _profile)),
    );
    if (updated != null) setState(() => _profile = updated);
  }

  Future<void> _goToEditExperience() async {
    final updated = await Navigator.push<List<ExperienceData>>(
      context,
      MaterialPageRoute(
          builder: (_) => EditExperiencePage(experiences: _experiences)),
    );
    if (updated != null) {
      setState(() {
        _experiences..clear()..addAll(updated);
      });
    }
  }

  Widget _buildAvatar() {
    if (_profile.avatar != null && _profile.avatar!.hasImage) {
      return _profile.avatar!.toCircleAvatar(radius: 50);
    }
    return const CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(
        'https://avatars.githubusercontent.com/u/116247408?s=400&u=cbb61570c6ad0193d11ca75fb03a9c901c1bf596&v=4',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            const ListTile(leading: Icon(Icons.home), title: Text('Beranda')),
            const ListTile(leading: Icon(Icons.person), title: Text('Profil')),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Pengaturan'),
                    content: const Text('Fitur pengaturan belum tersedia.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup')),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload Pengalaman'),
              onTap: () {
                Navigator.pop(context);
                _goToEditExperience();
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 12),
                  Text(_profile.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Mahasiswa Teknik Informatika',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatBox(label: 'Post', value: '12')),
                Expanded(child: _StatBox(label: 'Teman', value: '128')),
                Expanded(child: _StatBox(label: 'Like', value: '1.2K')),
              ],
            ),
            const SizedBox(height: 24),
            _SectionCard(
                icon: Icons.info_outline,
                title: 'Tentang Saya',
                content: _profile.bio),
            _SectionCard(
                icon: Icons.school,
                title: 'Pendidikan',
                content: _profile.education),
            _SectionCard(
                icon: Icons.location_on,
                title: 'Lokasi',
                content: _profile.location),
            _SectionCard(
                icon: Icons.email, title: 'Kontak', content: _profile.contact),
            // Skills
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star, color: Colors.blue, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Skills',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _profile.skills
                                .map((s) => Chip(label: Text(s)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pengalaman (BONUS)
            if (_experiences.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.work, color: Colors.blue, size: 28),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text('Pengalaman',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${_experiences.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._experiences
                          .map((exp) => _ExperienceItem(exp: exp)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToEditProfile,
        label: const Text('Edit Profil'),
        icon: const Icon(Icons.edit),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Pesan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Setting'),
        ],
        onTap: (i) {},
      ),
    );
  }
}

// ============================================================
// HALAMAN EDIT PROFILE
// ============================================================

class EditProfilePage extends StatefulWidget {
  final ProfileData profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _eduCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _skillsCtrl;
  _XImageHolder? _avatar;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _bioCtrl = TextEditingController(text: p.bio);
    _eduCtrl = TextEditingController(text: p.education);
    _locCtrl = TextEditingController(text: p.location);
    _contactCtrl = TextEditingController(text: p.contact);
    _skillsCtrl = TextEditingController(text: p.skills.join(', '));
    _avatar = p.avatar;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _bioCtrl, _eduCtrl, _locCtrl, _contactCtrl, _skillsCtrl
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await _pickImageCrossPlatform(_picker);
    if (result != null) setState(() => _avatar = result);
  }

  void _save() {
    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updated = ProfileData(
      name: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      education: _eduCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      skills: skills,
      avatar: _avatar,
    );

    Navigator.pop(context, updated);
  }

  Widget _buildAvatarPreview() {
    if (_avatar != null && _avatar!.hasImage) {
      return _avatar!.toCircleAvatar(radius: 50);
    }
    return const CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(
        'https://avatars.githubusercontent.com/u/116247408?s=400&u=cbb61570c6ad0193d11ca75fb03a9c901c1bf596&v=4',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, color: Colors.blue),
            label:
            const Text('Simpan', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text('Foto Profil',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      _buildAvatarPreview(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.photo_library, size: 16),
                    label: const Text('Ganti Foto dari Galeri'),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            const Text('Informasi Profil',
                style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildField(controller: _nameCtrl, label: 'Nama Lengkap *', icon: Icons.person),
            const SizedBox(height: 12),
            _buildField(controller: _bioCtrl, label: 'Bio / Tentang', icon: Icons.info_outline, maxLines: 3),
            const SizedBox(height: 12),
            _buildField(controller: _eduCtrl, label: 'Pendidikan', icon: Icons.school, maxLines: 2),
            const SizedBox(height: 12),
            _buildField(controller: _locCtrl, label: 'Lokasi', icon: Icons.location_on),
            const SizedBox(height: 12),
            _buildField(controller: _contactCtrl, label: 'Kontak (Email)', icon: Icons.email),
            const SizedBox(height: 12),
            _buildField(controller: _skillsCtrl, label: 'Skills (pisahkan dengan koma)', icon: Icons.star),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// ============================================================
// HALAMAN EDIT PENGALAMAN (BONUS)
// ============================================================

class EditExperiencePage extends StatefulWidget {
  final List<ExperienceData> experiences;
  const EditExperiencePage({super.key, required this.experiences});

  @override
  State<EditExperiencePage> createState() => _EditExperiencePageState();
}

class _EditExperiencePageState extends State<EditExperiencePage> {
  late List<ExperienceData> _list;
  final _picker = ImagePicker();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  _XImageHolder? _newImage;

  @override
  void initState() {
    super.initState();
    _list = widget.experiences
        .map((e) => ExperienceData(
        title: e.title, description: e.description, image: e.image))
        .toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await _pickImageCrossPlatform(_picker);
    if (result != null) setState(() => _newImage = result);
  }

  void _addExperience() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
        ),
      );
      return;
    }
    setState(() {
      _list.add(ExperienceData(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        image: _newImage,
      ));
      _titleCtrl.clear();
      _descCtrl.clear();
      _newImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengalaman berhasil ditambahkan!'),
      ),
    );
  }

  void _removeAt(int index) => setState(() => _list.removeAt(index));

  void _save() => Navigator.pop(context, _list);

  Widget _buildImagePreview() {
    if (_newImage != null && _newImage!.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _newImage!.toImage(height: 200),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate,
            size: 48, color: Colors.indigo.shade300),
        const SizedBox(height: 8),
        Text('Ketuk untuk pilih gambar',
            style: TextStyle(color: Colors.indigo.shade400)),
        Text('dari galeri perangkat kamu',
            style:
            TextStyle(fontSize: 12, color: Colors.indigo.shade300)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Pengalaman'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.blue),
            label:
            const Text('Simpan', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload gambar
            InkWell(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: (_newImage != null && _newImage!.hasImage) ? 200 : 140,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Informasi Pengalaman',
                style: TextStyle(
                    color: Colors.indigo, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul *',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addExperience,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Pengalaman'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_list.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const Text('Daftar Pengalaman',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._list.asMap().entries.map(
                    (e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: (e.value.image != null &&
                        e.value.image!.hasImage)
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: e.value.image!
                          .toImage(width: 56, height: 56),
                    )
                        : const Icon(Icons.image_not_supported),
                    title: Text(e.value.title),
                    subtitle: Text(
                      e.value.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon:
                      const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeAt(e.key),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET HELPERS
// ============================================================

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  const _SectionCard(
      {required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(content, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  final ExperienceData exp;
  const _ExperienceItem({required this.exp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (exp.image != null && exp.image!.hasImage)
                ? exp.image!.toImage(width: 64, height: 64)
                : Container(
              width: 64,
              height: 64,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(exp.description,
                    style: TextStyle(
                        color: Colors.grey.shade700, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}