import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/presentation/screens/share/qr_share_scanner_screen.dart';
import 'package:classtrack/presentation/widgets/welcome_setup_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QR Share Scanner & WelcomeSetupCard Tests', () {
    testWidgets('WelcomeSetupCard prompts Semester Setup Required when activeSem is unset', (tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WelcomeSetupCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Option 2 title and Step 1 banner are present
      expect(find.text('Step 1: Create a Semester'), findsOneWidget);
      expect(find.text('Scan Classmate QR Code'), findsOneWidget);

      // Tap on Option 2 while semester is unset
      await tester.tap(find.text('Scan Classmate QR Code'));
      await tester.pumpAndSettle();

      // Verify Semester Setup Required dialog is displayed
      expect(find.text('Semester Setup Required'), findsOneWidget);
      expect(find.text('Create Semester'), findsOneWidget);

      await db.close();
    });

    testWidgets('WelcomeSetupCard navigates to QrShareScannerScreen tab 1 when active semester exists', (tester) async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();
      await db.saveSemester(
        SemesterData(
          id: 'sem_test_1',
          name: 'Spring 2026',
          startDate: '2026-01-01',
          endDate: '2026-06-01',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.setSetting('active_semester_id', 'sem_test_1');

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      await container.read(activeSemesterProvider.notifier).loadFromDb();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: WelcomeSetupCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Option 2
      await tester.tap(find.text('Scan Classmate QR Code'));
      await tester.pumpAndSettle();

      // Verify QrShareScannerScreen is pushed and tab 1 ("Scan Classmate") is selected
      expect(find.byType(QrShareScannerScreen), findsOneWidget);
      final qrScreen = tester.widget<QrShareScannerScreen>(find.byType(QrShareScannerScreen));
      expect(qrScreen.initialTabIndex, equals(1));
      expect(find.text('Scan Classmate'), findsOneWidget);

      container.dispose();
      await db.close();
    });

    testWidgets('QrShareScannerScreen auto-creates semester when activeSem is unset on import', (tester) async {
      final db = AppDatabase.inMemory();

      // Prepare sample payload data
      final samplePayload = {
        'v': 2,
        'sem': 'Semester 4 Computer Science',
        'subs': [
          {
            'id': 'sub_algo',
            'name': 'Algorithms & Data Structures',
            'code': 'CS401',
            'cat': 'CORE',
            'col': '#4F46E5',
          },
          {
            'id': 'sub_db',
            'name': 'Database Systems',
            'code': 'CS402',
            'cat': 'CORE',
            'col': '#10B981',
          },
        ],
        'slots': [
          {
            'subId': 'sub_algo',
            'day': 1,
            'start': '09:00',
            'end': '10:00',
            'room': 'Lab 1',
            'teacher': 'Dr. Alan',
            'type': 'LECTURE',
          },
          {
            'subId': 'sub_db',
            'day': 2,
            'start': '11:00',
            'end': '12:00',
            'room': 'Hall A',
            'teacher': 'Prof. Grace',
            'type': 'LAB',
          },
        ],
      };

      // Encode payload to CT2 format
      final jsonStr = jsonEncode(samplePayload);
      final compressed = gzip.encode(utf8.encode(jsonStr));
      // Standard Base64 with padding
      final standardB64Payload = 'CT2:${base64.encode(compressed)}';

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': standardB64Payload};
          }
          return null;
        },
      );

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                capturedRef = ref;
                return const Scaffold(
                  body: QrShareScannerScreen(initialTabIndex: 1),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially active semester should be unset
      final initialSem = capturedRef.read(activeSemesterProvider);
      expect(initialSem.isUnset, isTrue);

      // Tap the paste FAB button
      expect(find.byIcon(Icons.paste_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.paste_rounded));
      await tester.pumpAndSettle();

      // Verify preview sheet appears with both subjects
      expect(find.text('Import Timetable'), findsOneWidget);
      expect(find.text('Algorithms & Data Structures'), findsOneWidget);
      expect(find.text('Database Systems'), findsOneWidget);
      expect(find.text('Import (2 Subjects)'), findsOneWidget);

      // Tap Import (2 Subjects)
      await tester.tap(find.text('Import (2 Subjects)'));
      await tester.pumpAndSettle();

      // Verify active semester is automatically created and set
      final activeSem = capturedRef.read(activeSemesterProvider);
      expect(activeSem.isUnset, isFalse);
      expect(activeSem.name, equals('Semester 4 Computer Science'));

      // Verify subjects were imported into state and DB
      final subjects = capturedRef.read(subjectsProvider);
      expect(subjects.length, equals(2));
      expect(subjects.any((s) => s.name == 'Algorithms & Data Structures'), isTrue);
      expect(subjects.any((s) => s.name == 'Database Systems'), isTrue);

      // Verify timetable slots were imported into state and DB
      final slots = capturedRef.read(timetableSlotsProvider);
      expect(slots.length, equals(2));
      expect(slots.any((s) => s.room == 'Lab 1'), isTrue);
      expect(slots.any((s) => s.room == 'Hall A'), isTrue);

      // Also verify SQLite database directly
      final dbSemesters = await db.getAllSemesters();
      expect(dbSemesters.length, equals(1));
      expect(dbSemesters.first.name, equals('Semester 4 Computer Science'));

      final dbSubjects = await db.getAllSubjects(activeSem.id);
      expect(dbSubjects.length, equals(2));

      final dbSlots = await db.getTimetableSlots(activeSem.id);
      expect(dbSlots.length, equals(2));

      await db.close();
    });
  });
}
