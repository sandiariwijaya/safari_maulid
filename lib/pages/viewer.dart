import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../util.dart';

/// Buka penampil foto layar penuh (bisa geser & zoom).
void bukaViewer(BuildContext context, List<String> urls, int awal, {String judul = '', List<String>? keterangan}) {
  if (urls.isEmpty) return;
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PenampilFoto(urls: urls, awal: awal < 0 ? 0 : awal, judul: judul, keterangan: keterangan),
  ));
}

class PenampilFoto extends StatefulWidget {
  final List<String> urls;
  final int awal;
  final String judul;
  final List<String>? keterangan;
  const PenampilFoto({super.key, required this.urls, required this.awal, this.judul = '', this.keterangan});

  @override
  State<PenampilFoto> createState() => _PenampilFotoState();
}

class _PenampilFotoState extends State<PenampilFoto> {
  late int _i = widget.awal;
  late final PageController _pc = PageController(initialPage: widget.awal);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ket = widget.keterangan != null && _i < widget.keterangan!.length ? widget.keterangan![_i] : '';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${widget.judul.isEmpty ? '' : '${widget.judul} • '}${_i + 1}/${widget.urls.length}',
            style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Buka / unduh di browser',
            icon: const Icon(Icons.download),
            onPressed: () => buka(widget.urls[_i]),
          ),
        ],
      ),
      body: Stack(children: [
        PhotoViewGallery.builder(
          pageController: _pc,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _i = i),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (_, __) => const Center(child: CircularProgressIndicator(color: kGold)),
          builder: (_, i) => PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(widget.urls[i]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
          ),
        ),
        if (ket.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(12),
              child: SafeArea(top: false, child: Text(ket, style: const TextStyle(color: Colors.white))),
            ),
          ),
      ]),
    );
  }
}
