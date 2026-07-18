/// Provides authentication state for the student portal.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indicates if the student entered the app as a guest.
final StateProvider<bool> isGuestProvider = StateProvider<bool>((StateProviderRef<bool> ref) => false);
