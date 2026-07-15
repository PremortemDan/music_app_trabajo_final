import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/song_provider.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  String? _songPath;
  String? _coverPath;
  bool _isPublic = true;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _pickSong() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _songPath = result.files.single.path;
      });
    }
  }

  Future<void> _pickCover() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _coverPath = image.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_songPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un archivo de audio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final songProvider = context.read<SongProvider>();
    String? errorMsg;
    final success = await songProvider.uploadSong(
      title: _titleController.text.trim(),
      genre: _genreController.text.trim().isNotEmpty ? _genreController.text.trim() : null,
      isPublic: _isPublic,
      songPath: _songPath!,
      coverPath: _coverPath,
    ).catchError((e) {
      errorMsg = e.toString();
      return false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Canción subida exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'Error al subir la canción. Verifica tu conexión.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Canción'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image
              Center(
                child: GestureDetector(
                  onTap: _pickCover,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      image: _coverPath != null
                          ? DecorationImage(
                              image: FileImage(File(_coverPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _coverPath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Portada', style: TextStyle(color: Colors.grey[400])),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botón de seleccionar canción
              OutlinedButton.icon(
                onPressed: _pickSong,
                icon: const Icon(Icons.audio_file),
                label: Text(_songPath != null ? 'Audio seleccionado' : 'Seleccionar Audio *'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_songPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _songPath!.split('/').last,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título de la Canción *',
                  hintText: 'Ej: Mi Gran Éxito',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'El título es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _genreController,
                decoration: InputDecoration(
                  labelText: 'Género',
                  hintText: 'Ej: Pop, Rock, Hip-Hop...',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle público/privado
              SwitchListTile(
                title: const Text('Canción pública'),
                subtitle: const Text('Disponible para todos los usuarios'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: songProvider.isLoading ? null : _submit,
                  icon: songProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    songProvider.isLoading ? 'Subiendo...' : 'Subir Canción',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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