import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wisbaj/config/routes.dart';
import 'package:wisbaj/features/home/presentation/widgets/alarm_list_widget.dart';
import 'package:wisbaj/features/home/presentation/widgets/image_carousel.dart';
import 'package:wisbaj/shared/providers/bluetooth_provider.dart';
import 'package:wisbaj/shared/widgets/connection_status_bar.dart';
import 'package:wisbaj/core/models/connection_status.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatusAsync = ref.watch(bluetoothConnectionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wisbaj'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.connection);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Naviguer vers les paramètres (non implémenté)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paramètres non implémentés')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de statut de connexion
          connectionStatusAsync.when(
            data: (status) => ConnectionStatusBar(status: status),
            loading: () => const LinearProgressIndicator(),
            error: (err, stack) => ConnectionStatusBar(status: ConnectionStatus.error),
          ),
          
          // Carousel d'images
          const ImageCarousel(),
          
          // Liste des alarmes
          const Expanded(
            child: AlarmListWidget(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.addAlarm);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
