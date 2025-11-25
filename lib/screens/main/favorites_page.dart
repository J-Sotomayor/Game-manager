import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../game_detail_page.dart';
import '../widgets/game_ui.dart';
import '../../providers/theme_provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String _searchTerm = '';

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tus favoritos'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: uid == null
            ? const Center(
                child: Text(
                  'No hay usuario autenticado.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GameSectionTitle(
                      text: 'Juegos favoritos',
                      icon: Icons.favorite_rounded,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aquí se muestran los juegos que marcaste como favoritos. '
                      'Tócalos para ver su detalle o editarlo.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Buscador
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar en favoritos por título o género',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchTerm = value.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Lista de favoritos
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('favorites')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, favSnapshot) {
                          if (favSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (favSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Ocurrió un error al cargar tus favoritos.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          if (!favSnapshot.hasData ||
                              favSnapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'Aún no has agregado juegos a favoritos.\n'
                                'Marca el icono ❤️ en el catálogo para empezar.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          final favDocs = favSnapshot.data!.docs;

                          return ListView.separated(
                            itemCount: favDocs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final favDoc = favDocs[index];
                              final gameId =
                                  (favDoc.data() as Map<String, dynamic>?)
                                          ?['gameId'] ??
                                      favDoc.id;
                              final addedAt =
                                  favDoc['createdAt'] as Timestamp?;

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('games')
                                    .doc(gameId)
                                    .get(),
                                builder: (context, gameSnapshot) {
                                  if (gameSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const _FavoriteSkeletonCard();
                                  }

                                  if (!gameSnapshot.hasData ||
                                      !gameSnapshot.data!.exists) {
                                    // juego eliminado del catálogo
                                    return Dismissible(
                                      key: ValueKey(favDoc.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 24),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onDismissed: (_) async {
                                        await favDoc.reference.delete();
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Favorito eliminado (juego ya no existe).',
                                            ),
                                          ),
                                        );
                                      },
                                      child: GameGlassCard(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.orangeAccent,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Este juego fue eliminado del catálogo.',
                                                style: theme
                                                    .textTheme.bodyMedium,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white70,
                                              ),
                                              onPressed: () async {
                                                await favDoc.reference
                                                    .delete();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final data = gameSnapshot.data!.data()
                                      as Map<String, dynamic>;

                                  final title = (data['title'] ??
                                          'Juego sin título')
                                      .toString();
                                  final genre =
                                      (data['genre'] ?? 'Sin género')
                                          .toString();
                                  final platform =
                                      (data['platform'] ?? '').toString();
                                  final imageUrl =
                                      (data['imageUrl'] ?? '').toString();
                                  final priceData = data['price'];
                                  final createdAt =
                                      data['createdAt'] as Timestamp?;

                                  String priceText = 'Sin precio';
                                  if (priceData is num) {
                                    priceText =
                                        '\$${priceData.toStringAsFixed(2)}';
                                  } else if (priceData is String &&
                                      priceData.trim().isNotEmpty) {
                                    priceText = '\$$priceData';
                                  }

                                  final text = (title + genre)
                                      .toLowerCase()
                                      .trim();
                                  if (_searchTerm.isNotEmpty &&
                                      !text.contains(_searchTerm)) {
                                    return const SizedBox.shrink();
                                  }

                                  return Dismissible(
                                    key: ValueKey(favDoc.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding:
                                          const EdgeInsets.only(right: 24),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (_) async {
                                      final ok =
                                          await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Quitar de favoritos'),
                                                  content: Text(
                                                    '¿Quitar "$title" de tus favoritos?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx,
                                                              false),
                                                      child: const Text(
                                                          'Cancelar'),
                                                    ),
                                                    FilledButton(
                                                      style: FilledButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                      child: const Text(
                                                          'Quitar'),
                                                    ),
                                                  ],
                                                ),
                                              ) ??
                                              false;
                                      return ok;
                                    },
                                    onDismissed: (_) async {
                                      await favDoc.reference.delete();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '"$title" se quitó de tus favoritos.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                GameDetailPage(
                                              gameId: gameId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: GameGlassCard(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Imagen
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: SizedBox(
                                                width: 110,
                                                height: 80,
                                                child: imageUrl.isNotEmpty
                                                    ? Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_,
                                                                __, ___) =>
                                                            const _FavImagePlaceholder(),
                                                      )
                                                    : const _FavImagePlaceholder(),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          title,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: theme
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        child: const Icon(
                                                          Icons.favorite,
                                                          size: 18,
                                                          color: Colors
                                                              .redAccent,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    platform.isNotEmpty
                                                        ? '$genre · $platform'
                                                        : genre,
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: GamePalette
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      999),
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.06),
                                                          border: Border.all(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.16),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .price_change_rounded,
                                                              size: 14,
                                                              color: GamePalette
                                                                  .secondary,
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              priceText,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 11,
                                                                color: GamePalette
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (addedAt != null ||
                                                      createdAt != null)
                                                    Text(
                                                      'Añadido a favoritos: '
                                                      '${_formatDate(addedAt ?? createdAt)}',
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        fontSize: 11,
                                                        color: GamePalette
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FavImagePlaceholder extends StatelessWidget {
  const _FavImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GamePalette.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.favorite_rounded,
          color: GamePalette.secondary,
          size: 26,
        ),
      ),
    );
  }
}

class _FavoriteSkeletonCard extends StatelessWidget {
  const _FavoriteSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return GameGlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 110,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
