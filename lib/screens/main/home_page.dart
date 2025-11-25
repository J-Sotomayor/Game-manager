import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../widgets/game_ui.dart';
import '../../providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();

  Map<String, dynamic>? _userData;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final doc = await _userService.getUser();
      setState(() {
        _userData = doc.data() as Map<String, dynamic>?;
        _loadingUser = false;
      });
    } catch (_) {
      setState(() {
        _loadingUser = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Buenos días";
    if (hour < 19) return "Buenas tardes";
    return "Buenas noches";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: _loadingUser
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== HEADER USUARIO =====
                    // ===== HEADER USUARIO =====
Row(
  children: [
    // Avatar sin asset local, con fallback a icono
    if ((_userData?['photoUrl'] ?? '').toString().isNotEmpty)
      CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(_userData!['photoUrl']),
      )
    else
      CircleAvatar(
        radius: 32,
        backgroundColor: GamePalette.surfaceAlt,
        child: const Icon(
          Icons.person_rounded,
          color: GamePalette.secondary,
          size: 30,
        ),
      ),

    const SizedBox(width: 14),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_getGreeting()},",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GamePalette.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (_userData?['displayName'] ?? 'Gamer anónimo').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            "Administra tu colección de juegos, precios y favoritos.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: GamePalette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  ],
),


                    const SizedBox(height: 24),

                    const GameSectionTitle(
                      text: "Últimos juegos añadidos",
                      icon: Icons.flash_on_rounded,
                    ),
                    const SizedBox(height: 12),

                    // ===== LISTA DE JUEGOS RECIENTES =====
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('games')
                            .orderBy('createdAt', descending: true)
                            .limit(10)
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
                                "Ocurrió un error al cargar los juegos.",
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                "Aún no has registrado ningún juego.\nEmpieza añadiendo el primero 👾",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data =
                                  doc.data() as Map<String, dynamic>? ?? {};

                              final title =
                                  (data['title'] ?? 'Sin título').toString();
                              final genre =
                                  (data['genre'] ?? 'Sin categoría')
                                      .toString();
                              final imageUrl =
                                  (data['imageUrl'] ?? '').toString();

                              return SizedBox(
                                width: 260,
                                child: GameGlassCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Imagen del juego
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const _GamePlaceholder(),
                                                )
                                              : const _GamePlaceholder(),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        genre,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: GamePalette.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: Colors.white
                                                  .withOpacity(0.05),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.12),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.leaderboard,
                                                  size: 14,
                                                  color:
                                                      GamePalette.secondary,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  "Vista rápida",
                                                  style: TextStyle(
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

class _GamePlaceholder extends StatelessWidget {
  const _GamePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GamePalette.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          color: GamePalette.secondary,
        ),
      ),
    );
  }
}
