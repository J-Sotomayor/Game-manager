import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/theme_provider.dart';
import '../../providers/auth_service.dart';
import '../auth/login_page.dart';
import '../widgets/game_ui.dart';

// Páginas principales
import 'home_page.dart';          // Ajusta si tu archivo se llama distinto
import 'search_page.dart';
import 'game_list_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';    // Ajusta si tu perfil está en otra ruta
import '../game/game_crud_page.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  // 👇 IMPORTANTE: inicializado y NO nulo
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),        // 0
    const SearchPage(),      // 1
    const GameListPage(),    // 2
    const FavoritesPage(),   // 3
    const ProfilePage(),     // 4
  ];

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: GameDrawer(
        currentIndex: _currentIndex,
        onNavigate: _onTabSelected,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // 👇 FAB tipo “botón de menú” arriba a la izquierda
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 4,
        ),
        child: FloatingActionButton.small(
          backgroundColor: Colors.black.withOpacity(0.35),
          elevation: 0,
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: const Icon(
            Icons.menu_rounded,
            color: Colors.white,
          ),
        ),
      ),

      // BOTTOM NAV GAMER
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GamePalette.surfaceAlt.withOpacity(0.96),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: GamePalette.secondary,
          unselectedItemColor: GamePalette.textSecondary,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Buscar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Lista',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DRAWER GAMER ====================

class GameDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const GameDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Jugador';
    final email = user?.email ?? '';

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Drawer(
      backgroundColor: GamePalette.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    GamePalette.secondary.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              selected: currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                onNavigate(0);
              },
            ),
            _DrawerItem(
              icon: Icons.favorite_rounded,
              label: 'Favoritos',
              selected: currentIndex == 3,
              onTap: () {
                Navigator.pop(context);
                onNavigate(3);
              },
            ),
            _DrawerItem(
              icon: Icons.search_rounded,
              label: 'Buscar',
              selected: currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                onNavigate(1);
              },
            ),
            _DrawerItem(
              icon: Icons.list_alt_rounded,
              label: 'Lista de videojuegos',
              selected: currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                onNavigate(2);
              },
            ),
            _DrawerItem(
              icon: Icons.add_circle_outline,
              label: 'Añadir juego',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameCRUDPage(),
                  ),
                );
              },
            ),

            const Divider(
              height: 24,
              indent: 16,
              endIndent: 16,
              color: Colors.white24,
            ),

            // SWITCH TEMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.dark_mode_outlined,
                    color: GamePalette.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Modo oscuro',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (value) =>
                        themeProvider.toggleTheme(value),
                    activeThumbColor: Colors.white,
                    activeTrackColor: GamePalette.secondary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor:
                        Colors.white.withOpacity(0.18),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            const Spacer(),

            // CERRAR SESIÓN
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                color: Colors.redAccent,
                onTap: () async {
                  final auth =
                      Provider.of<AuthService>(context, listen: false);

                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cerrar sesión'),
                          content: const Text(
                            '¿Seguro que quieres cerrar sesión?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Cerrar sesión'),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (!confirm) return;

                  await auth.logout();
                  if (!context.mounted) return;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool selected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = color ?? GamePalette.textPrimary;

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? GamePalette.secondary : textColor,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: selected ? GamePalette.secondary : textColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
