import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import 'avatar.dart';
import 'tx_widgets.dart' show kCardBg;

const _teal = Color(0xFF006767);

/// Isi satu postingan (dipakai di feed dan di layar komentar).
class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool detail;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final ValueChanged<String>? onMenu;
  const PostCard({super.key, required this.post, this.detail = false, this.onTap, this.onLike, this.onMenu});

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map<String, dynamic>;
    final body = (post['body'] as String?) ?? '';
    final image = post['image'] as String?;
    final liked = post['liked'] as bool;

    final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Avatar(name: author['name'] as String),
        const SizedBox(width: 10),
        Expanded(child: Text(author['name'] as String, style: inter(13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_horiz, size: 24),
          onSelected: onMenu,
          itemBuilder: (_) => [
            if (post['mine'] == true) const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            const PopupMenuItem(value: 'copy', child: Text('Salin teks')),
          ],
        ),
      ]),
      if (body.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(body,
            style: inter(12, weight: FontWeight.w200),
            maxLines: detail ? null : 6,
            overflow: detail ? TextOverflow.visible : TextOverflow.ellipsis),
      ],
      if (image != null) ...[
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            Api.imageUrl(image),
            width: double.infinity,
            height: detail ? 200 : 124,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: detail ? 200 : 124,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      Container(height: 1, color: Colors.black12),
      const SizedBox(height: 8),
      Row(children: [
        InkWell(
          onTap: onLike,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 24, color: _teal),
              const SizedBox(width: 6),
              Text('${post['likes']}', style: inter(10, weight: FontWeight.w200)),
            ]),
          ),
        ),
        const SizedBox(width: 22),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Row(children: [
            const Icon(Icons.chat_bubble_outline, size: 24, color: _teal),
            const SizedBox(width: 6),
            Text('${post['comments']}', style: inter(10, weight: FontWeight.w200)),
          ]),
        ),
      ]),
    ]);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12)),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
