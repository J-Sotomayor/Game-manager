import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/game_ui.dart';
import '../../providers/theme_provider.dart';

class GameCRUDPage extends StatefulWidget {
  /// null = crear, no null = editar
  final String? gameId;

  const GameCRUDPage({super.key, this.gameId});

  @override
  State<GameCRUDPage> createState() => _GameCRUDPageState();
}

class _GameCRUDPageState extends State<GameCRUDPage> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final genreController = TextEditingController();
  final platformController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  String? imageUrl;
  File? imageFile;

  bool loading = false;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();

    if (widget.gameId != null) {
      isEdit = true;
      loadGameData();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    genreController.dispose();
    platformController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadGameData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();

      final data = doc.data() ?? {};

      titleController.text = (data['title'] ?? '').toString();
      genreController.text = (data['genre'] ?? '').toString();
      descriptionController.text = (data['description'] ?? '').toString();
      platformController.text = (data['platform'] ?? '').toString();
      priceController.text =
          data['price'] != null ? data['price'].toString() : '';
      imageUrl = (data['imageUrl'] ?? '').toString();

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el juego: $e')),
      );
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      imageFile = File(picked.path);
      setState(() {});
    }
  }

  Future<String?> uploadImage() async {
    if (imageFile == null) return imageUrl;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fileName = "game_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final ref = FirebaseStorage.instance
        .ref()
        .child('games')
        .child(uid)
        .child(fileName);

    await ref.putFile(imageFile!);

    return await ref.getDownloadURL();
  }

  Future<void> saveGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // subir imagen si corresponde
      final uploadedImageUrl = await uploadImage();

      // precio opcional
      double? price;
      final priceText = priceController.text.trim().replaceAll(',', '.');
      if (priceText.isNotEmpty) {
        price = double.tryParse(priceText);
        if (price == null) {
          throw 'El precio no es un número válido.';
        }
      }

      final gameData = <String, dynamic>{
        'title': titleController.text.trim(),
        'genre': genreController.text.trim(),
        'description': descriptionController.text.trim(),
        'imageUrl': uploadedImageUrl ?? "",
        'platform': platformController.text.trim(),
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (price != null) {
        gameData['price'] = price;
      }

      final ref = FirebaseFirestore.instance.collection('games');

      if (isEdit) {
        await ref.doc(widget.gameId).update(gameData);
      } else {
        await ref.add(gameData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Juego actualizado correctamente'
                : 'Juego creado correctamente',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el juego: $e')),
      );
    }
  }

  Future<void> deleteGame() async {
    if (!isEdit) return;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar juego'),
            content: const Text(
              '¿Estás seguro de que quieres eliminar este juego?\n\n'
              'Esta acción no se puede deshacer.',
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

    setState(() => loading = true);

    try {
      // Opcional: borrar imagen en Storage si existe
      if (imageUrl != null && imageUrl!.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl!);
          await ref.delete();
        } catch (_) {
          // si falla aquí, no queremos romper todo el flujo
        }
      }

      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .delete();

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Juego eliminado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el juego: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEdit ? "Editar juego" : "Nuevo juego"),
        backgroundColor: Colors.transparent,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
              ),
              onPressed: deleteGame,
            ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: GameBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: GameGlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // badge superior
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white.withOpacity(0.06),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.18),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.build_rounded,
                                        size: 16,
                                        color: GamePalette.secondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isEdit
                                            ? "Editor de juego"
                                            : "Creador de juego",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontSize: 11.5,
                                          color: GamePalette.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.videogame_asset_rounded,
                                  size: 20,
                                  color: GamePalette.textSecondary,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Text(
                              isEdit
                                  ? "Actualiza la info de tu juego"
                                  : "Crea un nuevo juego para tu catálogo",
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Completa los datos, sube una portada y guarda los cambios.",
                              style: theme.textTheme.bodyMedium,
                            ),

                            const SizedBox(height: 18),

                            // selector de imagen
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                height: 190,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                  color: Colors.white.withOpacity(0.03),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (imageFile != null)
                                        Image.file(
                                          imageFile!,
                                          fit: BoxFit.cover,
                                        )
                                      else if (imageUrl != null &&
                                          imageUrl!.isNotEmpty)
                                        Image.network(
                                          imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const _ImagePlaceholder(),
                                        )
                                      else
                                        const _ImagePlaceholder(),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black
                                                  .withOpacity(0.6),
                                              Colors.transparent,
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.camera_alt_outlined,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "Toca para subir portada",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Título
                            TextFormField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                labelText: "Título del juego",
                                prefixIcon:
                                    Icon(Icons.text_fields_rounded),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) {
                                  return 'El título es obligatorio';
                                }
                                if (v.length < 3) {
                                  return 'Mínimo 3 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Género
                            TextFormField(
                              controller: genreController,
                              decoration: const InputDecoration(
                                labelText:
                                    "Género (acción, RPG, deportes...)",
                                prefixIcon:
                                    Icon(Icons.category_outlined),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) {
                                  return 'El género es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Plataforma y precio en fila
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: platformController,
                                    decoration: const InputDecoration(
                                      labelText: "Plataforma (PC, PS5, etc.)",
                                      prefixIcon: Icon(
                                        Icons.devices_other_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: priceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: "Precio",
                                      prefixIcon: Icon(
                                        Icons.price_change_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Descripción
                            TextFormField(
                              controller: descriptionController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: "Descripción",
                                alignLabelWithHint: true,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Botón guardar
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryGameButton(
                                text: isEdit
                                    ? "Guardar cambios"
                                    : "Crear juego",
                                loading: loading,
                                onPressed: saveGame,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GamePalette.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          color: GamePalette.secondary,
          size: 36,
        ),
      ),
    );
  }
}
