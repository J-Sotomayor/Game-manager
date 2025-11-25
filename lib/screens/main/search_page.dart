import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../game_detail_page.dart';
import '../widgets/favorite_button.dart';
import '../widgets/game_ui.dart';
import '../../providers/theme_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
        title: const Text('Buscar juegos'),
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
                      text: 'Buscador',
                      icon: Icons.search_rounded,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Encuentra juegos por título, género o plataforma. '
                      'Toca un resultado para ver su detalle o marcarlo como favorito.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Escribe el nombre del juego...',
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
                                'Ocurrió un error al buscar juegos.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'Aún no hay juegos en tu catálogo.\n'
                                'Crea uno nuevo desde el botón "+" en la lista.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs.toList();

                            docs.sort((a, b) {
                              final da = (a.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
                              final db = (b.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
                            
                              if (da == null && db == null) return 0;
                              if (da == null) return 1;
                              if (db == null) return -1;
                              return db.compareTo(da);
                            });

                           


                          if (_searchTerm.isEmpty) {
                            return Center(
                              child: Text(
                                'Empieza a escribir para buscar en tu catálogo 👾',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          final results = docs.where((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};

                            final title = (data['title'] ?? '')
                                .toString()
                                .toLowerCase();
                            final genre = (data['genre'] ?? '')
                                .toString()
                                .toLowerCase();
                            final platform = (data['platform'] ?? '')
                                .toString()
                                .toLowerCase();

                            return title.contains(_searchTerm) ||
                                genre.contains(_searchTerm) ||
                                platform.contains(_searchTerm);
                          }).toList();

                          if (results.isEmpty) {
                            return Center(
                              child: Text(
                                'No se encontraron juegos que coincidan\ncon "$_searchTerm".',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final gameDoc = results[index];
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

                              return InkWell(
                                borderRadius: BorderRadius.circular(20),
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
                                                      const _SearchImagePlaceholder(),
                                                )
                                              : const _SearchImagePlaceholder(),
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
                                                FavoriteButton(
                                                  gameId: gameDoc.id,
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
                                                        width: 4,
                                                      ),
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
                                                const SizedBox(width: 8),
                                                if (createdAt != null)
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

class _SearchImagePlaceholder extends StatelessWidget {
  const _SearchImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GamePalette.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.search_rounded,
          color: GamePalette.secondary,
          size: 26,
        ),
      ),
    );
  }
}
