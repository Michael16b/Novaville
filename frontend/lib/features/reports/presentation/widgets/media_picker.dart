import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';

class MediaPicker extends StatefulWidget {
  const MediaPicker({
    super.key,
    required this.onMediaChanged,
    this.initialMedia = const [],
  });

  final ValueChanged<List<XFile>> onMediaChanged;
  final List<XFile> initialMedia;

  @override
  State<MediaPicker> createState() => _MediaPickerState();
}

class _MediaPickerState extends State<MediaPicker> {
  final List<XFile> _mediaFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _mediaFiles.addAll(widget.initialMedia);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _mediaFiles.add(image);
      });
      widget.onMediaChanged(_mediaFiles);
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
    widget.onMediaChanged(_mediaFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropTarget(
          onDragDone: (detail) {
            setState(() {
              _mediaFiles.addAll(detail.files);
            });
            widget.onMediaChanged(_mediaFiles);
          },
          onDragEntered: (detail) {
            setState(() {
              _isDragging = true;
            });
          },
          onDragExited: (detail) {
            setState(() {
              _isDragging = false;
            });
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isDragging ? Colors.blue : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _isDragging ? Colors.blue.withOpacity(0.1) : null,
            ),
            child: Center(
              child: Text(
                _isDragging ? 'Drop here' : 'Drag and drop images here',
                style: TextStyle(
                  color: _isDragging ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_mediaFiles.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mediaFiles.length,
              itemBuilder: (context, index) {
                final file = _mediaFiles[index];
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: kIsWeb
                          ? Image.network(file.path, height: 100, width: 100, fit: BoxFit.cover)
                          : Image.file(File(file.path), height: 100, width: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeMedia(index),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
