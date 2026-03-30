import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

/// Genera un código de viaje amigable para el usuario.
/// 
/// Formato: TRP-YY-II-NNN
/// - TRP: Prefijo (TRIP)
/// - YY: Año corto (26 = 2026)
/// - II: Iniciales del conductor (2 letras mayúsculas)
/// - NNN: Secuencial de 3 dígitos (001-999)
/// 
/// Ejemplos:
/// - TRP-26-JP-001 → Primer viaje de Juan Pérez en 2026
/// - TRP-26-MG-042 → Viaje 42 de María Gómez en 2026
class GenerateTripCodeUseCase implements UseCase<String, GenerateTripCodeParams> {
  const GenerateTripCodeUseCase(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Either<Failure, String>> call(GenerateTripCodeParams params) async {
    try {
      // Obtener iniciales del conductor
      final initials = _getInitials(params.driverName);
      
      // Año corto (26 para 2026)
      final year = DateTime.now().year;
      final yearShort = year.toString().substring(2);
      
      // Obtener y incrementar contador
      final counter = await _incrementCounter(params.driverId, year);
      
      // Generar código: TRP-26-JP-001
      final tripCode = 'TRP-$yearShort-$initials-${counter.toString().padLeft(3, '0')}';
      
      return Right(tripCode);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Obtiene las iniciales del nombre del conductor (2 letras)
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    
    if (parts.isEmpty) return 'XX';
    
    if (parts.length == 1) {
      // Un solo nombre: usar primeras 2 letras
      final name = parts[0];
      if (name.length >= 2) {
        return name.substring(0, 2).toUpperCase();
      }
      return '${name[0]}X'.toUpperCase();
    }
    
    // Dos o más nombres: usar primera letra de cada uno
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Obtiene e incrementa el contador de viajes para un conductor en un año
  Future<int> _incrementCounter(String driverId, int year) async {
    final counterId = '${driverId}_$year';
    final counterRef = _firestore.collection('trip_counters').doc(counterId);
    
    return await _firestore.runTransaction<int>((transaction) async {
      final counterDoc = await transaction.get(counterRef);
      
      if (counterDoc.exists) {
        final currentCounter = counterDoc.data()?['counter'] as int? ?? 0;
        final newCounter = currentCounter + 1;
        
        // Si llegamos a 999, advertir (pero continuar)
        if (newCounter >= 999) {
          // En producción, aquí podrías lanzar una excepción o manejar el overflow
          debugPrint('⚠️ ADVERTENCIA: Contador de viajes cerca del límite para $driverId en $year');
        }
        
        transaction.update(counterRef, {'counter': newCounter});
        return newCounter;
      } else {
        // Primer viaje del conductor en este año
        transaction.set(counterRef, {
          'driverId': driverId,
          'year': year,
          'counter': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return 1;
      }
    });
  }
}

/// Parámetros para generar el código de viaje
class GenerateTripCodeParams {
  const GenerateTripCodeParams({
    required this.driverId,
    required this.driverName,
  });

  final String driverId;
  final String driverName;
}
