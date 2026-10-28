import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/avatar.dart';
import '../widgets/post_card.dart';
import '../widgets/tx_widgets.dart' show kCardBg;

/// Detail postingan + komentar.
class CommunityPostScreen extends StatefulWidget {
  final int postId;
  const CommunityPostScreen({super.key, required this.postId});
  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  final _input = TextEditingController();
  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  final _expanded = <int>{};
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Api.postDetail(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = r['post'] as Map<String, dynamic>;
        _comments = (r['comments'] as List).cast<Map<String, dynamic>>();
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

  Future<void> _like() async {
    final p = _post!;
    final was = p['liked'] as bool;
    setState(() {
      p['liked'] = !was;
      p['likes'] = (p['likes'] as int) + (was ? -1 : 1);
    });
    try {
      final r = await Api.toggleLike(widget.postId);
      if (mounted) {
        setState(() {
          p['liked'] = r['liked'];
          p['likes'] = r['likes'];
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        p['liked'] = was;
        p['likes'] = (p['likes'] as int) + (was ? 1 : -1);
      });
      showError(context, e.message);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await Api.addComment(widget.postId, text);
      _input.clear();
      await _load();
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _menu(String action) async {
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: (_post!['body'] as String?) ?? ''));
      if (mounted) showInfo(context, 'Teks disalin');
      return;
    }
    final ok = await _confirm('Hapus postingan?', 'Postingan dan komentarnya akan dihapus.');
    if (ok != true) return;
    try {
      await Api.deletePost(widget.postId);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  Future<void> _deleteComment(Map<String, dynamic> c) async {
    if (c['mine'] != true) return;
    final ok = await _confirm('Hapus komentar?', 'Komentar ini akan dihapus.');
    if (ok != true) return;
    try {
      await Api.deleteComment(c['id'] as int);
      _load();
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  Future<bool?> _confirm(String title, String content) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 4),
              child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF006363))),
            ),
          ),
          Expanded(child: _body()),
          _inputBar(),
        ]),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center, style: inter(16)),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Coba lagi', width: 160, height: 46, fontSize: 15, textColor: Colors.white, onTap: _load),
          ]),
        ),
      );
    }
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(isMobile ? 16 : 38, 8,
          isMobile ? 16 : 38, 16),
        children: [
          Container(
            decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              PostCard(post: _post!, detail: true, onLike: _like, onMenu: _menu),
              if (_comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Belum ada komentar. Jadi yang pertama!', style: inter(12, color: const Color(0xFF5B5B5B))),
                ),
              for (final c in _comments) _comment(c),
              const SizedBox(height: 8),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _comment(Map<String, dynamic> c) {
    final id = c['id'] as int;
    final body = c['body'] as String;
    final long = body.length > 120;
    final open = _expanded.contains(id);
    final author = c['author'] as Map<String, dynamic>;
    return InkWell(
      onLongPress: () => _deleteComment(c),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(name: author['name'] as String),
            const SizedBox(width: 10),
            Expanded(child: Text(author['name'] as String, style: inter(13))),
          ]),
          const SizedBox(height: 8),
          Text(long && !open ? '${body.substring(0, 120)}...' : body, style: inter(12, weight: FontWeight.w200)),
          if (long)
            GestureDetector(
              onTap: () => setState(() => open ? _expanded.remove(id) : _expanded.add(id)),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(open ? 'Sembunyikan' : 'Baca Selengkapnya ...', style: inter(12, weight: FontWeight.w200)),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _inputBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        color: kCardBg,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 3,
              maxLength: 500,
              style: inter(13),
              cursorColor: AppColors.primary,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                hintText: 'Tulis komentar...',
                hintStyle: inter(12, weight: FontWeight.w200),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          IconButton(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send, color: AppColors.primary),
          ),
        ]),
      );
}
