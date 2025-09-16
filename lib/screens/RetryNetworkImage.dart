import 'dart:async';

import 'package:flutter/material.dart';

class RetryNetworkImage extends StatefulWidget {
  final String imageUrl;
  final int maxRetries;
  final Duration retryDelay;
  final ImageProvider fallbackImageProvider;

  RetryNetworkImage({
    required this.imageUrl,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    required this.fallbackImageProvider,
  });

  @override
  _RetryNetworkImageState createState() => _RetryNetworkImageState();
}

class _RetryNetworkImageState extends State<RetryNetworkImage> {
  late Future<ImageProvider> _imageFuture;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImageWithRetry(widget.imageUrl);
  }

  Future<ImageProvider> _loadImageWithRetry(String url) async {
    while (_retryCount < widget.maxRetries) {
      try {
        final image = NetworkImage(url);
        // Prefetch the image to check if it can be loaded
        await precacheImage(image, context);
        return image;
      } catch (e) {
        _retryCount++;
        print("Failed to load image. Retrying ($_retryCount/${widget.maxRetries})... Exception: $e");
        await Future.delayed(widget.retryDelay);
      }
    }
    // Return fallback image if all retries fail
    return widget.fallbackImageProvider;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image(image: snapshot.data!);
        } else if (snapshot.hasError) {
          print("Error loading image: ${snapshot.error}");
          return Image(image: widget.fallbackImageProvider);
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
