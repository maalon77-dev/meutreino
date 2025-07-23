import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedGifWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedGifWidget({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se a URL estiver vazia, mostrar placeholder
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: placeholder ?? Center(
          child: Icon(
            Icons.fitness_center,
            size: 32,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    // Construir a URL completa
    final fullUrl = imageUrl.startsWith('http') 
        ? imageUrl 
        : 'https://airfit.online/$imageUrl';

    Widget imageWidget = CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: borderRadius,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue[400]!,
              ),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: errorWidget ?? Center(
          child: Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.grey[400],
          ),
        ),
      ),
      // Configurações de cache otimizadas
      memCacheWidth: width.toInt(), // Cache em memória com resolução 1x
      memCacheHeight: height.toInt(),
      maxWidthDiskCache: width.toInt(), // Cache em disco com resolução 1x
      maxHeightDiskCache: height.toInt(),
      // Configurações de qualidade
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    // Aplicar borderRadius se fornecido
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
} 