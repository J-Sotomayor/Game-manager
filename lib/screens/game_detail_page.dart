import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'widgets/game_ui.dart';
import '../providers/theme_provider.dart';
import 'game/game_crud_page.dart';
import 'widgets/favorite_button.dart';

class GameDetailPage extends StatefulWidget {
  final String gameId;

  const GameDetailPage({
    super.key,
    required this.gameId,
  });

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  bool _deleting = false;

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _deleteGame(
      BuildContext context, String gameId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar juego'),
            content: const Text(
              'Esta acción no se puede deshacer.\n\n'
              '¿Seguro que quieres eliminar este juego del catálogo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _deleting = true);

    try {
      final imageUrl = (data['imageUrl'] ?? '').toString();
      if (imageUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        } catch (_) {
          // Si falla borrar imagen, no rompemos todo el flujo
        }
      }

      await FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .delete();

      if (!mounted) return;
      Navigator.pop(context); // cerrar detalle
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Juego eliminado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el juego: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Detalle del juego'),
        backgroundColor: Colors.transparent,
        actions: [
          FavoriteButton(gameId: widget.gameId),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: Stack(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('games')
                  .doc(widget.gameId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      'Este juego ya no existe en el catálogo.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                final title =
                    (data['title'] ?? 'Juego sin título').toString();
                final genre =
                    (data['genre'] ?? 'Sin género').toString();
                final platform =
                    (data['platform'] ?? '').toString();
                final imageUrl =
                    (data['imageUrl'] ?? '').toString();
                final description =
                    (data['description'] ?? '').toString();
                final priceData = data['price'];
                final createdAt =
                    data['createdAt'] as Timestamp?;

                String priceText = 'Sin precio';
                if (priceData is num) {
                  priceText = '\$${priceData.toStringAsFixed(2)}';
                } else if (priceData is String &&
                    priceData.trim().isNotEmpty) {
                  priceText = '\$$priceData';
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 620),
                      child: GameGlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Imagen grande
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const _DetailImagePlaceholder(),
                                      )
                                    : const _DetailImagePlaceholder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Título + precio
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Precio',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            GamePalette.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      priceText,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: GamePalette.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Chips de género / plataforma / fecha
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  icon: Icons.category_outlined,
                                  label: genre,
                                ),
                                if (platform.isNotEmpty)
                                  _InfoChip(
                                    icon:
                                        Icons.devices_other_rounded,
                                    label: platform,
                                  ),
                                if (createdAt != null)
                                  _InfoChip(
                                    icon:
                                        Icons.calendar_month_rounded,
                                    label:
                                        'Añadido: ${_formatDate(createdAt)}',
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Text(
                              'Descripción',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description.isEmpty
                                  ? 'Este juego aún no tiene descripción.'
                                  : description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: GamePalette.textSecondary,
                                  ),
                            ),

                            const SizedBox(height: 22),

                            // Botones de acción
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryGameButton(
                                    text: 'Editar juego',
                                    loading: false,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GameCRUDPage(
                                              gameId: widget.gameId),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                      padding:
                                          const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    onPressed: _deleting
                                        ? null
                                        : () => _deleteGame(
                                              context,
                                              widget.gameId,
                                              data,
                                            ),
                                    child: _deleting
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                          Color>(
                                                      Colors.redAccent),
                                            ),
                                          )
                                        : const Text('Eliminar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            if (_deleting)
              Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: GamePalette.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: GamePalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GamePalette.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          color: GamePalette.secondary,
          size: 40,
        ),
      ),
    );
  }
}
