import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/post_card.dart';
import '../widgets/tx_widgets.dart' show kCardBg;
import 'community_post_screen.dart';

/// Tab 4 - Komunitas: cari, buat postingan (teks + foto), daftar postingan.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _search = TextEditingController();
  final _compose = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _posts = [];
  Uint8List? _image;
  bool _loading = true;
  bool _posting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _compose.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await Api.posts(q: _search.text.trim());
      if (!mounted) return;
      setState(() {
        _posts = items;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (mounted) setState(() => _image = bytes);
    } catch (_) {
      if (mounted) showError(context, 'Gagal memilih foto');
    }
  }

  Future<void> _post() async {
    final text = _compose.text.trim();
    if (text.isEmpty && _image == null) return showError(context, 'Tulis sesuatu atau pilih foto dulu');
    setState(() => _posting = true);
    try {
      await Api.createPost(text, imageBytes: _image);
      if (!mounted) return;
      _compose.clear();
      setState(() => _image = null);
      showInfo(context, 'Postingan terkirim');
      await _load();
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _like(Map<String, dynamic> p) async {
    final wasLiked = p['liked'] as bool;
    setState(() {
      p['liked'] = !wasLiked;
      p['likes'] = (p['likes'] as int) + (wasLiked ? -1 : 1);
    });
    try {
      final r = await Api.toggleLike(p['id'] as int);
      if (mounted) {
        setState(() {
          p['liked'] = r['liked'];
          p['likes'] = r['likes'];
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        p['liked'] = wasLiked;
        p['likes'] = (p['likes'] as int) + (wasLiked ? 1 : -1);
      });
      showError(context, e.message);
    }
  }

  Future<void> _menu(Map<String, dynamic> p, String action) async {
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: (p['body'] as String?) ?? ''));
      if (mounted) showInfo(context, 'Teks disalin');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus postingan?'),
        content: const Text('Postingan dan komentarnya akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deletePost(p['id'] as int);
      if (mounted) showInfo(context, 'Postingan dihapus');
      _load();
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  Future<void> _open(Map<String, dynamic> p) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityPostScreen(postId: p['id'] as int)));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 38, top + 24,
              isMobile ? 16 : 38, 24),
          children: [
            _searchBar(),
            const SizedBox(height: 20),
            _composeCard(),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Column(children: [
                Text(_error!, textAlign: TextAlign.center, style: inter(16)),
                const SizedBox(height: 16),
                PrimaryButton(
                    label: 'Coba lagi',
                    width: 160,
                    height: 46,
                    fontSize: 15,
                    textColor: Colors.white,
                    onTap: () {
                      setState(() => _loading = true);
                      _load();
                    }),
              ])
            else if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text(
                    _search.text.isEmpty ? 'Belum ada obrolan. Jadi yang pertama memposting!' : 'Tidak ada obrolan yang cocok.',
                    textAlign: TextAlign.center,
                    style: inter(14, color: const Color(0xFF5B5B5B))),
              )
            else
              for (final p in _posts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: PostCard(
                    post: p,
                    onTap: () => _open(p),
                    onLike: () => _like(p),
                    onMenu: (a) => _menu(p, a),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() => Container(
        height: 46,
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.search, size: 24)),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              style: inter(13),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Cari Obrolan...',
                hintStyle: inter(12, weight: FontWeight.w200),
              ),
            ),
          ),
        ]),
      );

  Widget _composeCard() => Container(
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _compose,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              style: inter(13),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Apa yang ingin kamu bagikan?',
                hintStyle: inter(12, weight: FontWeight.w200),
              ),
            ),
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_image!, height: 110, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => setState(() => _image = null),
                    child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          Container(height: 1, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            child: Row(children: [
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    const Icon(Icons.image_outlined, size: 24, color: Color(0xFF006767)),
                    const SizedBox(width: 6),
                    Text('Photo', style: inter(12, weight: FontWeight.w600, color: const Color(0xFF006767))),
                  ]),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 61,
                height: 31,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _posting ? null : _post,
                    child: Center(
                      child: _posting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Post', style: inter(12, weight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      );
}
