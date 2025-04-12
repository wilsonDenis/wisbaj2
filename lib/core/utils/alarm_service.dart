import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:wisbaj/config/constants.dart';
import 'package:wisbaj/core/models/alarm_model.dart';

class AlarmService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Box _alarmBox = Hive.box(AppConstants.alarmBoxName);
  Timer? _timer;

  // Initialiser le service
  Future<void> initialize() async {
    print('[AlarmService] Initialisation des notifications...');

    // Initialiser les notifications pour Android
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialiser les notifications pour iOS
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuration globale des notifications
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    // Initialisation de la plateforme de notifications
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
    print('[AlarmService] Notifications initialisées');

    // Démarrer le timer pour vérifier les alarmes
    _startTimer();
    print('[AlarmService] Timer démarré');
  }

  // Gérer la notification lorsque l'utilisateur clique dessus
  void _onSelectNotification(NotificationResponse response) {
    print('[AlarmService] Notification sélectionnée: ${response.payload}');
    // Vous pouvez ajouter ici la logique de navigation ou d'action associée à la notification
  }

  // Démarrer le timer pour vérifier les alarmes toutes les minutes
  void _startTimer() {
    // Annuler un timer existant
    _timer?.cancel();

    // Calculer le temps jusqu'à la prochaine minute exacte
    final now = DateTime.now();
    final nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final timeUntilNextMinute = nextMinute.difference(now);

    print(
        '[AlarmService] Temps jusqu\'à la prochaine minute: ${timeUntilNextMinute.inSeconds} secondes');

    // Déclencher le timer pour commencer à la prochaine minute exacte
    Timer(timeUntilNextMinute, () {
      print('[AlarmService] Première vérification des alarmes');
      _checkAlarms();

      // Puis démarrer un timer périodique toutes les minutes
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        print('[AlarmService] Vérification périodique des alarmes');
        _checkAlarms();
      });
    });
  }

  // Vérifier les alarmes actives
  void _checkAlarms() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentWeekday = now.weekday; // 1 = Lundi, 7 = Dimanche

    // Convertir au format utilisé (0 = Lundi, 6 = Dimanche)
    final adjustedWeekday = currentWeekday - 1;

    print(
        '[AlarmService] Vérification des alarmes à ${DateFormat.Hm().format(now)} (Jour ${currentWeekday})');

    // Récupérer toutes les alarmes stockées
    List<AlarmModel> alarms = getAllAlarms();
    print('[AlarmService] Nombre d\'alarmes chargées: ${alarms.length}');

    for (var alarm in alarms) {
      print(
          '[AlarmService] Vérification de l\'alarme ${alarm.id} - Heure: ${alarm.time.hour}:${alarm.time.minute} | ActiveDays: ${alarm.activeDays}');
      if (alarm.isActive &&
          alarm.time.hour == currentHour &&
          alarm.time.minute == currentMinute &&
          alarm.activeDays[adjustedWeekday]) {
        print(
            '[AlarmService] Condition remplie pour l\'alarme ${alarm.id}. Déclenchement...');
        _triggerAlarm(alarm);
      }
    }
  }

  // Déclencher une alarme via une notification
  Future<void> _triggerAlarm(AlarmModel alarm) async {
    print('[AlarmService] Envoi de la notification pour l\'alarme ${alarm.id}');

    // Définition des paramètres pour Android
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarmes',
      channelDescription: 'Notifications pour les alarmes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    // Définition des paramètres pour iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        alarm.id.hashCode,
        'Wisbaj Alarm',
        alarm.label.isEmpty ? 'Il est temps!' : alarm.label,
        notificationDetails,
        payload: alarm.id,
      );
      print('[AlarmService] Notification envoyée pour l\'alarme ${alarm.id}');
    } catch (e) {
      print(
          '[AlarmService] Erreur lors du déclenchement de la notification: $e');
      // Tentative de fallback en cas d'erreur
      const AndroidNotificationDetails fallbackDetails =
          AndroidNotificationDetails(
        'alarm_channel_fallback',
        'Alarmes (fallback)',
        channelDescription: 'Notifications pour les alarmes (mode dégradé)',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails fallbackNotificationDetails =
          NotificationDetails(
        android: fallbackDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        alarm.id.hashCode,
        'Wisbaj Alarm',
        alarm.label.isEmpty ? 'Il est temps!' : alarm.label,
        fallbackNotificationDetails,
        payload: alarm.id,
      );
      print(
          '[AlarmService] Notification fallback envoyée pour l\'alarme ${alarm.id}');
    }
  }

  // CRUD Operations

  // Récupérer toutes les alarmes
  List<AlarmModel> getAllAlarms() {
    final List<dynamic> alarmData = _alarmBox.values.toList();
    return alarmData.map((data) => data as AlarmModel).toList();
  }

  // Récupérer une alarme par son ID
  AlarmModel? getAlarmById(String id) {
    return _alarmBox.get(id) as AlarmModel?;
  }

  // Ajouter ou mettre à jour une alarme
  Future<void> saveAlarm(AlarmModel alarm) async {
    await _alarmBox.put(alarm.id, alarm);
    print('[AlarmService] Alarme ${alarm.id} enregistrée/mise à jour');
  }

  // Supprimer une alarme
  Future<void> deleteAlarm(String id) async {
    await _alarmBox.delete(id);
    print('[AlarmService] Alarme $id supprimée');
  }

  // Formater une heure pour l'affichage
  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.Hm().format(dateTime);
  }

  // Générer une chaîne représentant les jours actifs
  String formatDays(List<bool> activeDays) {
    const List<String> dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    List<String> selectedDays = [];

    for (int i = 0; i < activeDays.length; i++) {
      if (activeDays[i]) {
        selectedDays.add(dayLabels[i]);
      }
    }

    if (selectedDays.isEmpty) {
      return 'Aucun jour';
    } else if (selectedDays.length == 7) {
      return 'Tous les jours';
    } else if (selectedDays.length == 5 &&
        activeDays[0] &&
        activeDays[1] &&
        activeDays[2] &&
        activeDays[3] &&
        activeDays[4]) {
      return 'Jours de semaine';
    } else if (selectedDays.length == 2 && activeDays[5] && activeDays[6]) {
      return 'Weekends';
    } else {
      return selectedDays.join(', ');
    }
  }

  // Nettoyer les ressources
  void dispose() {
    _timer?.cancel();
    print('[AlarmService] Timer annulé et ressources nettoyées');
  }
}
