import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/artist_provider.dart';
import '../../providers/auth_provider.dart';

class RegisterCreatorScreen extends StatefulWidget {
  const RegisterCreatorScreen({super.key});

  @override
  State<RegisterCreatorScreen> createState() => _RegisterCreatorScreenState();
}

class _RegisterCreatorScreenState extends State<RegisterCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _genreController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  String? _imagePath;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _artistNameController.dispose();
    _bioController.dispose();
    _genreController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final artistProvider = context.read<ArtistProvider>();
    final success = await artistProvider.registerAsCreator(
      artistName: _artistNameController.text.trim(),
      bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      genre: _genreController.text.trim().isNotEmpty ? _genreController.text.trim() : null,
      website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
      instagram: _instagramController.text.trim().isNotEmpty ? _instagramController.text.trim() : null,
      imagePath: _imagePath,
    );

    if (!mounted) return;

    if (success) {
      // Refrescar el usuario en AuthProvider para que isCreator sea true
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Te has registrado como creador exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(artistProvider.error ?? 'Error al registrarse'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final artistProvider = context.watch<ArtistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse como Creador'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen del artista
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                    child: _imagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 30, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text('Foto', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _artistNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Artista *',
                  hintText: 'Ej: DJ Master',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'El nombre de artista es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _genreController,
                decoration: InputDecoration(
                  labelText: 'Género Musical',
                  hintText: 'Ej: Rock, Pop, Electrónica...',
                  prefixIcon: const Icon(Icons.music_note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Biografía',
                  hintText: 'Cuéntanos sobre ti y tu música...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.article),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Sitio Web',
                  hintText: 'https://tusitio.com',
                  prefixIcon: const Icon(Icons.language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _instagramController,
                decoration: InputDecoration(
                  labelText: 'Instagram',
                  hintText: '@tuusuario',
                  prefixIcon: const Icon(Icons.camera_alt),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: artistProvider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: artistProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrarme como Creador',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}