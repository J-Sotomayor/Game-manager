import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../game_detail_page.dart';
import '../widgets/favorite_button.dart';
import '../widgets/game_ui.dart';
import '../../providers/theme_provider.dart';

class GameListPage extends StatefulWidget {
  const GameListPage({super.key});

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  String _searchTerm = '';
  String? _selectedGenre;

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
        title: const Text('Catálogo de juegos'),
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
                      text: 'Tus juegos',
                      icon: Icons.videogame_asset_rounded,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explora y administra los juegos de tu catálogo. '
                      'Toca un juego para ver su detalle, marcar favoritos o editarlo.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por título o género',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchTerm = value.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('games')
                            .where('createdBy', isEqualTo: uid)
                            
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Ocurrió un error al cargar los juegos.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'Aún no has registrado juegos.\n'
                                'Crea tu primer juego desde el botón "+"',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs.toList();// 👈 copiamos la lista
                            docs.sort((a, b) {
                              final da = (a.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
                              final db = (b.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;

                              if (da == null && db == null) return 0;
                              if (da == null) return 1;
                              if (db == null) return -1;
                              return db.compareTo(da); // más nuevos primero
                            });


                          // recolectar géneros para los chips
                          final genresSet = <String>{};
                          for (final doc in docs) {
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};
                            final g =
                                (data['genre'] ?? '').toString().trim();
                            if (g.isNotEmpty) {
                              genresSet.add(g);
                            }
                          }
                          final genres = genresSet.toList()..sort();

                          // aplicar filtros
                          final filteredDocs = docs.where((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};
                            final title = (data['title'] ?? '')
                                .toString()
                                .toLowerCase();
                            final genre = (data['genre'] ?? '')
                                .toString()
                                .toLowerCase();

                            final matchesSearch = _searchTerm.isEmpty ||
                                title.contains(_searchTerm) ||
                                genre.contains(_searchTerm);

                            final matchesGenre = _selectedGenre == null ||
                                genre ==
                                    _selectedGenre!
                                        .toLowerCase()
                                        .trim();

                            return matchesSearch && matchesGenre;
                          }).toList();

                          return Column(
                            children: [
                              if (genres.isNotEmpty)
                                SizedBox(
                                  height: 36,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: genres.length + 1,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        final allSelected =
                                            _selectedGenre == null;
                                        return ChoiceChip(
                                          label: const Text('Todos'),
                                          selected: allSelected,
                                          onSelected: (_) {
                                            setState(
                                              () => _selectedGenre = null,
                                            );
                                          },
                                        );
                                      }

                                      final genreLabel =
                                          genres[index - 1];
                                      final selected =
                                          _selectedGenre == genreLabel;

                                      return ChoiceChip(
                                        label: Text(genreLabel),
                                        selected: selected,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedGenre = selected
                                                ? null
                                                : genreLabel;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              if (genres.isNotEmpty)
                                const SizedBox(height: 12),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: filteredDocs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final gameDoc = filteredDocs[index];
                                    final data = gameDoc.data()
                                            as Map<String, dynamic>? ??
                                        {};

                                    final title =
                                        (data['title'] ?? 'Sin título')
                                            .toString();
                                    final genre =
                                        (data['genre'] ?? 'Sin género')
                                            .toString();
                                    final platform =
                                        (data['platform'] ?? '')
                                            .toString();
                                    final imageUrl =
                                        (data['imageUrl'] ?? '')
                                            .toString();
                                    final createdAt =
                                        data['createdAt']
                                            as Timestamp?;
                                    final priceData = data['price'];

                                    String priceText = 'Sin precio';
                                    if (priceData is num) {
                                      priceText =
                                          '\$${priceData.toStringAsFixed(2)}';
                                    } else if (priceData is String &&
                                        priceData.trim().isNotEmpty) {
                                      priceText = '\$$priceData';
                                    }

                                    return InkWell(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GameDetailPage(
                                              gameId: gameDoc.id,
                                            ),
                                          ),
                                        );
                                      },
                                      child: GameGlassCard(
                                        padding:
                                            const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                16,
                                              ),
                                              child: SizedBox(
                                                width: 110,
                                                height: 80,
                                                child: imageUrl.isNotEmpty
                                                    ? Image.network(
                                                        imageUrl,
                                                        fit:
                                                            BoxFit.cover,
                                                        errorBuilder: (_,
                                                                __, ___) =>
                                                            const _GameImagePlaceholder(),
                                                      )
                                                    : const _GameImagePlaceholder(),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
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
                                                      FavoriteButton(
                                                        gameId:
                                                            gameDoc.id,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                      height: 4),
                                                  Text(
                                                    platform.isNotEmpty
                                                        ? '$genre · $platform'
                                                        : genre,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow
                                                            .ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                      color: GamePalette
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      height: 6),
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
                                                                999,
                                                              ),
                                                          color: Colors.white
                                                              .withOpacity(
                                                                0.06,
                                                              ),
                                                          border:
                                                              Border.all(
                                                            color: Colors
                                                                .white
                                                                .withOpacity(
                                                              0.16,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize
                                                                  .min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .price_change_rounded,
                                                              size: 14,
                                                              color: GamePalette
                                                                  .secondary,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              priceText,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize:
                                                                    11,
                                                                color: GamePalette
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 8),
                                                      if (createdAt !=
                                                          null)
                                                        Text(
                                                          'Añadido: ${_formatDate(createdAt)}',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            fontSize: 11,
                                                            color: GamePalette
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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

class _GameImagePlaceholder extends StatelessWidget {
  const _GameImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GamePalette.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          color: GamePalette.secondary,
          size: 26,
        ),
      ),
    );
  }
}
