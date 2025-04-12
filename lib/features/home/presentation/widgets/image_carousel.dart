import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImageInfo {
  final String imagePath;
  final String title;
  final String subtitle;

  const ImageInfo({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel>
    with SingleTickerProviderStateMixin {
  // Contrôleur pour gérer le carousel programmatiquement
  late CarouselController _carouselController;

  // Index actuel pour suivre la position
  int _currentIndex = 0;

  // Timer pour le défilement automatique
  Timer? _autoScrollTimer;

  // Liste des informations d'images
  final List<ImageInfo> carouselItems = [
    const ImageInfo(
      imagePath: 'assets/images/carousel1.png',
      title: 'Alarmes intelligentes',
      subtitle: 'Programmez vos alarmes simplement',
    ),
    const ImageInfo(
      imagePath: 'assets/images/carousel2.jpg',
      title: 'Connexion Bluetooth',
      subtitle: 'Connectez-vous facilement à votre Arduino',
    ),
    const ImageInfo(
      imagePath: 'assets/images/carousel3.png',
      title: 'Design moderne',
      subtitle: 'Interface utilisateur élégante et intuitive',
    ),
    const ImageInfo(
      imagePath: 'assets/images/carousel4.png',
      title: 'Importation Excel',
      subtitle: 'Gérez vos alarmes en lot',
    ),
    const ImageInfo(
      imagePath: 'assets/images/carousel5.png',
      title: 'Mode sombre',
      subtitle: 'Protégez vos yeux la nuit',
    ),
    const ImageInfo(
      imagePath: 'assets/images/carousel6.jpg',
      title: 'une grosse boîte',
      subtitle: 'alarme clock',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur avec l'élément initial
    _carouselController = CarouselController(initialItem: _currentIndex);
    // Démarrer le défilement automatique après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    // Annuler le timer pour éviter les fuites de mémoire
    _autoScrollTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  // Démarrer le défilement automatique
  void _startAutoScroll() {
    // Défiler toutes les 3 secondes
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Éviter les mises à jour si le widget n'est plus monté
      if (!mounted) return;

      // Calculer le prochain index
      final nextIndex = (_currentIndex + 1) % carouselItems.length;

      // Mettre à jour le contrôleur et l'index
      setState(() {
        _currentIndex = nextIndex;
        // Recréer le contrôleur pour forcer la mise à jour de la vue
        final oldController = _carouselController;
        // Créer un nouveau contrôleur avec le prochain index
        _carouselController = CarouselController(initialItem: nextIndex);
        // Disposer de l'ancien contrôleur après un court délai
        // pour éviter des problèmes de timing
        Future.delayed(const Duration(milliseconds: 100), () {
          oldController.dispose();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15.h),
      height: 200.h,
      child: CarouselView.weighted(
        controller: _carouselController,
        flexWeights: const [3, 2, 1], // Mode Hero
        scrollDirection: Axis.horizontal,
        itemSnapping: true, // S'arrête sur chaque élément
        enableSplash: false, // Désactive l'effet d'éclaboussure
        reverse: false, // De gauche à droite (l'animation va vers la gauche)
        onTap: (index) {
          // Gestion des interactions manuelles
          if (!mounted) return;
          setState(() {
            _currentIndex = index;
            // Annuler le timer existant
            _autoScrollTimer?.cancel();
            // Redémarrer le défilement automatique
            _startAutoScroll();
          });
        },
        // Créer une liste d'éléments plus longue pour donner l'illusion d'un défilement infini
        // Nous répétons les éléments pour simuler un loop infini
        children: [
          // Répéter les éléments 3 fois pour donner l'illusion d'un défilement infini
          ...carouselItems
              .map((item) => HeroLayoutCard(imageInfo: item))
              .toList(),
          ...carouselItems
              .map((item) => HeroLayoutCard(imageInfo: item))
              .toList(),
          ...carouselItems
              .map((item) => HeroLayoutCard(imageInfo: item))
              .toList(),
        ],
      ),
    );
  }
}

class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({super.key, required this.imageInfo});

  final ImageInfo imageInfo;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        // Image avec effet d'ombrage
        ClipRRect(
          borderRadius: BorderRadius.circular(15.r),
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: Image.asset(
              imageInfo.imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Superposition de texte
        Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                imageInfo.title,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                imageInfo.subtitle,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 2.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
