# Engineering Rules

1. UI layer must not directly access Isar or Dio.
2. All network calls go through repository layer.
3. No business logic inside widgets.
4. All models must be immutable.
5. Dark theme only.
6. Adult filter must default to true.
7. Reader is not part of MVP.
8. Use Riverpod for all state management.
9. Keep widgets small and composable.
10. Follow SOLID principles.