import 'package:flutter/material.dart';

import 'db_helper.dart';

void main() {
  // Wajib: sqflite butuh binding Flutter sudah diinisialisasi sebelum
  // ada operasi platform channel (saat DB pertama kali dibuka).
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// =====================================================================
// MODEL — Catatan
// =====================================================================
//
// Bedanya dengan Pertemuan 3: sekarang `id` jadi field utama (nullable
// untuk catatan baru yang belum disimpan), dan kita tambah toMap/fromMap
// sebagai jembatan antara objek Dart ↔ row SQLite.
class Catatan {
  final int? id;
  final String judul;
  final String isi;
  final String kategori;
  final DateTime dibuatPada;

  Catatan({
    this.id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.dibuatPada,
  });

  // Objek Dart → Map untuk db.insert / db.update.
  // Kalau id null, jangan dikirim — biar AUTOINCREMENT yang isi.
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'judul': judul,
    'isi': isi,
    'kategori': kategori,
    'dibuat_pada': dibuatPada.millisecondsSinceEpoch,
  };

  // Row dari db.query → objek Dart.
  static Catatan fromMap(Map<String, Object?> m) => Catatan(
    id: m['id'] as int?,
    judul: m['judul'] as String,
    isi: m['isi'] as String,
    kategori: m['kategori'] as String,
    dibuatPada:
    DateTime.fromMillisecondsSinceEpoch(m['dibuat_pada'] as int),
  );

  // Helper untuk form Edit — copy dengan beberapa field diganti.
  Catatan copyWith({String? judul, String? isi, String? kategori}) => Catatan(
    id: id,
    judul: judul ?? this.judul,
    isi: isi ?? this.isi,
    kategori: kategori ?? this.kategori,
    dibuatPada: dibuatPada,
  );
}

// =====================================================================
// ROOT APP — Named Routes
// =====================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Mahasiswa (SQLite)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/form':
          // arguments boleh null (mode tambah) atau Catatan (mode edit).
            final arg = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => CatatanFormPage(initial: arg as Catatan?),
            );
          case '/detail':
            final catatan = settings.arguments as Catatan;
            return MaterialPageRoute(
              builder: (_) => DetailCatatanPage(catatan: catatan),
            );
        }
        return null;
      },
    );
  }
}

// =====================================================================
// HOME PAGE — StatefulWidget + FutureBuilder
// =====================================================================
//
// Bedanya dengan P3: state internal `List<Catatan>` HILANG. Sebagai
// gantinya kita pegang `Future<List<Catatan>>` yang nilainya datang dari
// database. UI dirender oleh `FutureBuilder`.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Catatan>> _futureCatatan;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  // Bukan async — tugasnya hanya mengganti Future yang dipegang state.
  // FutureBuilder akan otomatis menampilkan loading lalu data baru.
  void _muatUlang() {
    setState(() {
      _futureCatatan = DbHelper.instance.getAll();
    });
  }

  Future<void> _bukaForm({Catatan? initial}) async {
    // pushNamed mengembalikan Future yang resolve saat form pop.
    await Navigator.pushNamed(context, '/form', arguments: initial);
    // Apapun hasilnya (insert, update, batal), muat ulang dari DB.
    _muatUlang();
  }

  Future<void> _bukaDetail(Catatan c) async {
    await Navigator.pushNamed(context, '/detail', arguments: c);
    // Detail bisa memicu edit → refresh untuk jaga-jaga.
    _muatUlang();
  }

  Future<void> _konfirmasiHapus(Catatan c) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${c.judul}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      await DbHelper.instance.delete(c.id!);
      if (!mounted) return;
      _muatUlang();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${c.judul}" dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Mahasiswa'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _muatUlang,
          ),
        ],
      ),
      body: FutureBuilder<List<Catatan>>(
        future: _futureCatatan,
        builder: (context, snapshot) {
          // === STATE 1: loading ===
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // === STATE 2: error ===
          if (snapshot.hasError) {
            return _ErrorState(
              pesan: snapshot.error.toString(),
              onRetry: _muatUlang,
            );
          }

          final data = snapshot.data ?? const [];

          // === STATE 3: kosong ===
          if (data.isEmpty) return const _EmptyState();

          // === STATE 4: ada data ===
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = data[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(c.judul.isEmpty ? '?' : c.judul[0]),
                  ),
                  title: Text(c.judul),
                  subtitle: Text(
                    '${c.kategori} • ${_formatTanggal(c.dibuatPada)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _bukaForm(initial: c),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _konfirmasiHapus(c),
                      ),
                    ],
                  ),
                  onTap: () => _bukaDetail(c),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_alt_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Belum ada catatan',
              style:
              TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Tekan tombol + untuk menambahkan',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String pesan;
  final VoidCallback onRetry;
  const _ErrorState({required this.pesan, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Gagal memuat catatan',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(pesan,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// CATATAN FORM PAGE — Stateful + Form
// =====================================================================
//
// SATU halaman untuk dua mode:
//   - initial == null  → mode CREATE (insert)
//   - initial != null  → mode EDIT   (update)
class CatatanFormPage extends StatefulWidget {
  final Catatan? initial;
  const CatatanFormPage({super.key, this.initial});

  @override
  State<CatatanFormPage> createState() => _CatatanFormPageState();
}

class _CatatanFormPageState extends State<CatatanFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulCtrl;
  late final TextEditingController _isiCtrl;

  late String _kategori;
  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  bool get _isEdit => widget.initial != null;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill controller kalau mode edit.
    _judulCtrl = TextEditingController(text: widget.initial?.judul ?? '');
    _isiCtrl = TextEditingController(text: widget.initial?.isi ?? '');
    _kategori = widget.initial?.kategori ?? 'Kuliah';
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _menyimpan = true);

    try {
      if (_isEdit) {
        final updated = widget.initial!.copyWith(
          judul: _judulCtrl.text.trim(),
          isi: _isiCtrl.text.trim(),
          kategori: _kategori,
        );
        await DbHelper.instance.update(updated);
      } else {
        final baru = Catatan(
          judul: _judulCtrl.text.trim(),
          isi: _isiCtrl.text.trim(),
          kategori: _kategori,
          dibuatPada: DateTime.now(),
        );
        await DbHelper.instance.insert(baru);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Catatan diperbarui' : 'Catatan ditambahkan'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Catatan' : 'Tambah Catatan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judulCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'cth. Tugas Pemrograman Mobile',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                if (v.trim().length < 3) return 'Judul minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _kategoriOpsi
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() => _kategori = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isiCtrl,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                hintText: 'Tulis catatan Anda di sini...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Isi catatan tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _menyimpan ? null : _simpan,
              icon: _menyimpan
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.save),
              label: Text(_isEdit ? 'Update Catatan' : 'Simpan Catatan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _menyimpan ? null : () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// DETAIL CATATAN PAGE
// =====================================================================
class DetailCatatanPage extends StatelessWidget {
  final Catatan catatan;
  const DetailCatatanPage({super.key, required this.catatan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushNamed(context, '/form', arguments: catatan);
              // Setelah edit, tutup detail juga supaya tampilan refresh
              // dari Home (data lama di sini sudah usang).
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              catatan.judul,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.category, size: 18),
                  label: Text(catatan.kategori),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTanggal(catatan.dibuatPada),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              catatan.isi,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Daftar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// HELPER
// =====================================================================
String _formatTanggal(DateTime dt) {
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${dua(dt.day)}/${dua(dt.month)}/${dt.year} '
      '${dua(dt.hour)}:${dua(dt.minute)}';
}