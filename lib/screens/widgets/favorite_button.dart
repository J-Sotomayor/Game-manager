import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final String gameId;

  const FavoriteButton({
    super.key,
    required this.gameId,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoritesService _favoritesService = FavoritesService();

  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final isFav = await _favoritesService.isFavorite(widget.gameId);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    } catch (_) {
      // Si falla, simplemente dejamos el icono vacío
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(widget.gameId);
      } else {
        await _favoritesService.addFavorite(widget.gameId);
      }

      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar favoritos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            )
          : Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: Colors.yellow,
            ),
      onPressed: _toggleFavorite,
    );
  }
}
